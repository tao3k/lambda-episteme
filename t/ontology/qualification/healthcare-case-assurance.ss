;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Cross-runtime qualification for the exact AI-assisted prescription Case.
;;; Gerbil Parser, TLC and Lean qualify independent boundaries before Cedar.
;;; MRR remains a downstream Rust library consumer of the parser-owned FFI.
(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/modules/authorization/providers/cedar/interface
                 poo-flow-cedar-authorization-request->runtime
                 poo-flow-cedar-authority-context
                 poo-flow-cedar-authority-snapshot->runtime
                 poo-flow-governance-assessments-digest
                 poo-flow-cedar-proof-binding
                 poo-flow-cedar-runtime-handoff)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-compose-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance
                 HealthcareCaseQualificationMetadata
                 healthcare-case-assurance
                 healthcare-case-assurance-digest
                 healthcare-case-assurance?
                 healthcare-case-qualification-path
                 healthcare-lean-refinement-receipt-read-file
                 healthcare-tlc-model-receipt-read-file)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization
                 healthcare-authorization-capability-digest
                 healthcare-authorization-subject-digest
                 healthcare-case-cedar-request
                 healthcare-case-cedar-snapshot)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/ai-assisted-antibiotic-prescription/case
                 AIAssistedAntibioticPrescriptionCase))

(export healthcare-case-assurance-qualification)

(def qualification-digest
  (string-append "sha256:" (make-string 64 #\0)))

(def (case-proof receipt assurance)
  (let* ((profiles (.ref receipt 'profiles))
         (authorization (car (.ref (.ref receipt 'case) 'authorizations))))
    (poo-flow-cedar-proof-binding
     (symbol->string (.ref receipt 'case-id))
     (map (lambda (profile) (.ref profile 'identity)) profiles)
     qualification-digest
     qualification-digest
     (healthcare-case-assurance-digest assurance)
     (healthcare-authorization-capability-digest receipt)
     (poo-flow-governance-assessments-digest
      (.ref receipt 'governance-assessments))
     (healthcare-authorization-subject-digest receipt authorization)
     '("PooFlowProof.Vertical.Healthcare.PrescriptionCausalityRefinement.wrongAutoApprovalCannotBeAdmitted"
       "PooFlowProof.Vertical.Healthcare.PrescriptionCausalityRefinement.wrongAdministrationCannotBeAdmitted"
       "PooFlowProof.PooC3.CedarDualEngineArbitration"))))

(def (qualification-receipt-and-assurance)
  (let* ((receipt
          (ontology-compose-case AIAssistedAntibioticPrescriptionCase))
         (tlc-receipt
          (healthcare-tlc-model-receipt-read-file
           (healthcare-case-qualification-path 'tlc-receipt)))
         (assurance
          (healthcare-case-assurance
           receipt
           (healthcare-case-qualification-path 'contributor-root)
           tlc-receipt
           (healthcare-lean-refinement-receipt-read-file
            (healthcare-case-qualification-path 'lean-receipt)))))
    (values receipt assurance)))

(def (qualification-snapshot receipt assurance)
  (healthcare-case-cedar-snapshot
   receipt assurance (healthcare-case-qualification-path 'contributor-root)
   (poo-flow-cedar-authority-context
    "healthcare-authority" "prescription-runtime" 1
    (healthcare-case-assurance-digest assurance) 1 1 0)
   (case-proof receipt assurance)))

(def healthcare-case-assurance-qualification
  (test-suite
   "Healthcare exact Case assurance qualification"

   (test-case "Scheme Metadata closes the exact POO TLC and Lean assurance"
     (let-values (((receipt assurance)
                   (qualification-receipt-and-assurance)))
       (check (.ref HealthcareCaseQualificationMetadata 'kind)
              => 'lambda-episteme.healthcare-case-qualification-metadata)
       (check (.ref receipt 'accepted?) => #t)
       (check (healthcare-case-assurance? assurance) => #t)
       (check (.ref assurance 'assurance-closed?) => #t)
       (check (.ref assurance 'release-authorized?) => #f)
       (check (length (.ref assurance 'query-contracts)) => 3)
       (check (.ref assurance 'analysis-runtime-executed?) => #f)))

   (test-case "assurance digest binds the Cedar authority snapshot"
     (let-values (((receipt assurance)
                   (qualification-receipt-and-assurance)))
       (let* ((snapshot (qualification-snapshot receipt assurance))
              (runtime
               (poo-flow-cedar-authority-snapshot->runtime snapshot)))
         (check (hash-ref runtime "object_kind")
                => "cedar-authority-snapshot"))))

   (test-case "only the clinician-selected order reaches Cedar"
     (let-values (((receipt assurance)
                   (qualification-receipt-and-assurance)))
       (let* ((snapshot (qualification-snapshot receipt assurance))
              (_runtime
               (poo-flow-cedar-authority-snapshot->runtime snapshot))
            (handoff
             (poo-flow-cedar-runtime-handoff
              1 #u8(1 2 3) qualification-digest qualification-digest
              qualification-digest qualification-digest))
            (request
             (healthcare-case-cedar-request
              receipt assurance (healthcare-case-assurance-digest assurance)
              handoff))
            (runtime-request
             (poo-flow-cedar-authorization-request->runtime request)))
         (check (hash-ref runtime-request "principal")
                => "Healthcare::Provider::\"clinician-1\"")
         (check (hash-ref runtime-request "action")
                => "Healthcare::Action::\"administerMedication\"")
         (check (hash-ref runtime-request "resource")
                => "Healthcare::MedicationOrder::\"alternative-order-1\"")
         (check (hash-ref (hash-ref runtime-request "context")
                          "assurance_closed")
                => #t))))))

(run-tests! healthcare-case-assurance-qualification)
