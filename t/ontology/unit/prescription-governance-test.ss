;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop element?)
        (only-in :clan/poo/io json-string<- <-json-string)
        (only-in :std/srfi/1 find)
        :poo-flow/src/modules/governance/interface
        :poo-flow/src/modules/temporal-causality/interface
        :poo-flow/src/modules/authorization/providers/cedar/interface
        :poo-flow/lambda-episteme/modules/ontology/interface
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization-projection
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/pharmacology-evidence
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/ai-assisted-antibiotic-prescription/case)

(export prescription-governance-test)

(def qualification-digest
  (string-append "sha256:" (make-string 64 #\0)))

(def (assessment-by-profile receipt identity)
  (find (lambda (assessment)
          (equal? (.ref assessment 'profile-identity) identity))
        (.ref receipt 'governance-assessments)))

(def (case-proof receipt independent-digest)
  (let* ((profiles (.ref receipt 'profiles))
         (authorization (car (.ref (.ref receipt 'case) 'authorizations))))
    (poo-flow-cedar-proof-binding
     (symbol->string (.ref receipt 'case-id))
     (map (lambda (profile) (.ref profile 'identity)) profiles)
     qualification-digest qualification-digest independent-digest
     (healthcare-authorization-capability-digest receipt)
     (poo-flow-governance-assessments-digest
      (.ref receipt 'governance-assessments))
     (healthcare-authorization-subject-digest receipt authorization)
     '("PooFlowProof.Enterprise.GovernanceThreatAssuranceClosure"
       "PooFlowProof.PooC3.CedarDualEngineArbitration"))))

(def prescription-governance-test
  (test-suite
   "AI-assisted prescription Governance Case"

   (test-case "Scenario Profiles admit the independently reviewed prescription"
     (let* ((receipt
             (ontology-compose-case AIAssistedAntibioticPrescriptionCase))
            (evaluation (ontology-evaluate-case receipt))
            (profile-names
             (map (lambda (profile) (.ref profile 'name))
                  (.ref receipt 'profiles))))
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref receipt 'governance-handoff-ready?) => #t)
       (check profile-names
              => '(evidence privacy healthcare-base medication-safety
                            pharmacology-safety
                            ai-clinical-decision-support))
       (check (map (lambda (assessment)
                     (.ref assessment 'unresolved-threats))
                   (.ref receipt 'governance-assessments))
              => '(() () () () () ()))
       (check (.ref evaluation 'accepted?) => #t)
       (check (.ref evaluation 'runtime-executed?) => #t)))

   (test-case "causal cut separates observed future counterfactual and hypothesis"
     (let* ((receipt
             (ontology-compose-case AIAssistedAntibioticPrescriptionCase))
            (event-graph
             (poo-flow-causal-event-graph
              "patient-1" (.ref receipt 'events)))
            (cut (poo-flow-causal-cut event-graph 6))
            (classification
             (poo-flow-temporal-causal-classify
              event-graph cut "ai-tmp-smx-recommendation-1" 9)))
       (check (map (lambda (event) (.ref event 'identity))
                   (.ref cut 'events))
              => '("care-request-1"
                   "active-warfarin-context-1"
                   "ai-tmp-smx-recommendation-1"
                   "warfarin-tmp-smx-interaction-evidence-1"
                   "prescription-governance-hold-1"
                   "independent-clinician-review-1"))
       (check (.ref classification 'past-event-ids)
              => '("ai-tmp-smx-recommendation-1"
                   "warfarin-tmp-smx-interaction-evidence-1"
                   "prescription-governance-hold-1"))
       (check (.ref classification 'current-event-ids)
              => '("independent-clinician-review-1"))
       (check (.ref classification 'future-event-ids)
              => '("alternative-prescription-1/rev1"
                   "pharmacy-verification-1"
                   "alternative-administration-ready-1"))
       (check (.ref classification 'counterfactual-event-ids)
              => '("wrong-ai-auto-approval-1"
                   "wrong-tmp-smx-administration-1"))
       (check (.ref classification 'hypothesized-event-ids)
              => '("elevated-anticoagulation-risk-1"))
       (check (.ref classification 'unknown-frontier) => '())
       (check (.ref classification 'assurance-closed?) => #f)
       (check (.ref classification 'release-authorized?) => #f)))

   (test-case "label evidence has a traceable impact on this Case"
     (let* ((receipt
             (ontology-compose-case AIAssistedAntibioticPrescriptionCase))
            (reasoning (ontology-case-reasoning-graph receipt))
            (impact
             (ontology-reasoning-impact
              reasoning
              "source:healthcare/pharmacology/warfarin-tmp-smx-label-evidence")))
       (check (.ref impact 'status) => 'snapshot-scoped-impact)
       (check (.ref impact 'target-entity-kind) => 'source)
       (check (.ref impact 'impacted-case-ids)
              => '(ai-assisted-antibiotic-prescription))
       (check (.ref impact 'temporal-impact-assessed?) => #f)
       (check (.ref impact 'release-authorized?) => #f)))

   (test-case "pharmacology JSON is a typed round-trip boundary"
     (let* ((root (if (file-exists? "modules/ontology/interface.ss")
                    "." "lambda-episteme"))
            (evidence
             (healthcare-pharmacology-evidence-read-file
              (path-expand
               "user-interface/scenarios/healthcare/sources/warfarin-tmp-smx-label-evidence.json"
               root)))
            (json-value
             (json-string<- HealthcarePharmacologyEvidence evidence))
            (roundtrip
             (<-json-string HealthcarePharmacologyEvidence json-value)))
       (check (element? HealthcarePharmacologyEvidence evidence) => #t)
       (check (.ref evidence 'identity)
              => "healthcare/pharmacology/warfarin-tmp-smx-label-evidence/v1")
       (check (length (.ref evidence 'facts)) => 2)
       (check (element? HealthcarePharmacologyEvidence roundtrip) => #t)
       (check (.ref roundtrip 'identity)
              => (.ref evidence 'identity))))

   (test-case "missing AI authority evidence blocks the unsafe Case"
     (let* ((unsafe-case
             (.o (:: @ AIAssistedAntibioticPrescriptionCase)
                 case-id: 'ai-autonomous-antibiotic-prescription
                 ai-advisory-only?: #f))
            (receipt (ontology-compose-case unsafe-case))
            (assessment
             (assessment-by-profile
              receipt
              "lambda-episteme/ontology/healthcare/ai-clinical-decision-support")))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'governance-handoff-ready?) => #f)
       (check (memq 'governance-handoff-blocked
                    (ontology-case-diagnostic-codes receipt))
              ? values)
       (check (.ref assessment 'unresolved-threats)
              => '("healthcare/ai-cds/threat/autonomous-prescription"))))

   (test-case "Cedar rejects the Case until independent assurance is closed"
     (let* ((receipt
             (ontology-compose-case AIAssistedAntibioticPrescriptionCase))
            (root (if (file-exists? "modules/ontology/interface.ss")
                    "." "lambda-episteme"))
            (context
             (poo-flow-cedar-authority-context
              "healthcare-authority" "prescription-runtime" 1
              qualification-digest 1 1 0))
            (handoff
             (poo-flow-cedar-runtime-handoff
              1 #u8(1 2 3) qualification-digest qualification-digest
              qualification-digest qualification-digest)))
       (check (healthcare-cedar-governance-projection-canonical receipt)
              => '(("lambda-episteme/ontology/healthcare/pharmacology-safety"
                    #t #t #t)
                   ("lambda-episteme/ontology/healthcare/ai-clinical-decision-support"
                    #t #t #t)))
       (check-exception
        (healthcare-case-cedar-snapshot
         receipt qualification-digest root context
         (case-proof receipt qualification-digest))
        true)
       (check-exception
        (healthcare-case-cedar-request
         receipt qualification-digest qualification-digest handoff)
        true)))))
