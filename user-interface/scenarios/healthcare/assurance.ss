;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Exact evidence closure for the AI-assisted prescription Case. Native POO
;;; classification, TLC exhaustion and Lean refinement close safety assurance;
;;; declared GQL is non-authoritative analysis input for a later MRR Runtime.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/src/modules/temporal-causality/interface
                 poo-flow-causal-cut poo-flow-causal-event-graph
                 poo-flow-causal-trajectory-assessment-digest
                 poo-flow-causal-trajectory-assessment?
                 poo-flow-temporal-causal-classify)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-case-composition-receipt?)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/reasoning
                 HealthcareCaseProfileRelationsQuery
                 HealthcareProfileImpactQuery
                 HealthcarePrescriptionCausalTrajectoryQuery
                 healthcare-query-source-path)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/formal-assurance-projection
                 HealthcareLeanAssuranceProjector
                 HealthcareTLAPlusAssuranceProjector
                 healthcare-formal-assurance-project)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/ai-clinical-decision-support
                 AIClinicalDecisionSupportProfile))

(export healthcare-tlc-model-receipt
        healthcare-tlc-model-receipt-read-file
        healthcare-lean-refinement-receipt-read-file
        HealthcareCaseQualificationMetadata
        healthcare-case-qualification-path
        healthcare-case-qualification-gql-paths
        healthcare-publish-lean-refinement-receipt!
        healthcare-case-assurance
        healthcare-case-assurance?
        healthcare-case-assurance-certifications
        healthcare-case-trajectory-assessment-digest
        healthcare-case-assurance-digest)

(def +case-id+ 'ai-assisted-antibiotic-prescription)
(def +tla-source-content-id+
  "sha256:0f5adf60c5206a104c597ee981a53c32a202472d66af5033743665ce91da8c13")
(def +tla-config-content-id+
  "sha256:d53b08f84dfd34c9ec1e92ff14bf9bf62102e9506ff67dfd4833211705c37ab6")
(def +lean-source-content-id+
  "sha256:21f260d13227a4b47accaa45f0987f6e19f3821302efc962e2f203bfc36c629c")
(def +lean-module+
  "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement")
(def +lean-library+ "EpistemeHealthcareProof")
(def +lean-certifications+
  '("EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.wrongAutoApprovalCannotBeAdmitted"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.wrongAdministrationCannotBeAdmitted"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.independentReviewCutExcludesWrongPath"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.alternativePrescriptionHasIndependentHumanParent"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.wrongPathSatisfiesTrajectoryContract"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.errorImpactSatisfiesTrajectoryContract"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.declaredErrorPathCannotBeAdmitted"
    "EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement.declaredErrorImpactCannotBeAdmitted"))

(def +query-contracts+
  (list HealthcareCaseProfileRelationsQuery
        HealthcareProfileImpactQuery
        HealthcarePrescriptionCausalTrajectoryQuery))

;;; The Case owns its evidence layout as declarative Scheme data. Build tools
;;; select and execute qualification capabilities; they do not reconstruct the
;;; Case contract through shell variables.
(def HealthcareCaseQualificationMetadata
  (.o kind: 'lambda-episteme.healthcare-case-qualification-metadata
      repository-root: "."
      contributor-root: "."
      gql-queries: +query-contracts+
      tla-source:
      "user-interface/scenarios/healthcare/cases/ai-assisted-antibiotic-prescription/proof/tla/HealthcareAIAssistedPrescriptionCausality.tla"
      tla-config:
      "user-interface/scenarios/healthcare/cases/ai-assisted-antibiotic-prescription/proof/tla/HealthcareAIAssistedPrescriptionCausality.cfg"
      ;; One deterministic TLC worker is part of this bounded qualification
      ;; profile; Gerbil build parallelism remains independently machine-sized.
      tlc-workers: 1
      tlc-receipt: ".ci/healthcare-ai-temporal/tlc-receipt.ss"
      lean-receipt: ".ci/healthcare-ai-lean/lean-receipt.ss"
      lean-library: +lean-library+
      lean-module: +lean-module+
      lean-source-content-id: +lean-source-content-id+
      lean-certifications: +lean-certifications+))

(def (healthcare-case-qualification-path slot)
  (path-expand
   (.ref HealthcareCaseQualificationMetadata slot)
   (.ref HealthcareCaseQualificationMetadata 'repository-root)))

(def (healthcare-case-qualification-gql-paths)
  (map (lambda (query)
         (healthcare-query-source-path
          query
          (healthcare-case-qualification-path 'contributor-root)))
       (.ref HealthcareCaseQualificationMetadata 'gql-queries)))

(def (healthcare-publish-lean-refinement-receipt!)
  (let ((path (healthcare-case-qualification-path 'lean-receipt))
        (metadata HealthcareCaseQualificationMetadata))
    (create-directory* (path-directory path))
    (call-with-output-file
     path
     (lambda (port)
       (write
        `((schema . "poo-flow.healthcare-lean-refinement.v1")
          (library . ,(.ref metadata 'lean-library))
          (module . ,(.ref metadata 'lean-module))
          (source-digest . ,(.ref metadata 'lean-source-content-id))
          (certifications . ,(.ref metadata 'lean-certifications))
          (admitted . #t))
        port)
       (newline port)))
    path))

(def (query-contract-canonical query)
  (list (.ref query 'identity)
        (.ref query 'revision)
        (.ref query 'expected-source-content-id)
        (.ref query 'graph-kind)))

(def +query-contract-canonical+
  (map query-contract-canonical +query-contracts+))

(def (digest value)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (string->utf8
             (call-with-output-string (lambda (port) (write value port))))))))

(def (healthcare-tlc-model-receipt generated distinct left depth)
  (.o kind: 'lambda-episteme.healthcare-tlc-model-receipt
      case-id: +case-id+
      model: "HealthcareAIAssistedPrescriptionCausality"
      source-content-id: +tla-source-content-id+
      config-content-id: +tla-config-content-id+
      generated-states: generated
      distinct-states: distinct
      states-left: left
      graph-depth: depth
      admitted?: (and (exact-integer? generated) (> generated 0)
                      (exact-integer? distinct) (> distinct 0)
                      (exact-integer? left) (= left 0)
                      (exact-integer? depth) (> depth 0))
      release-authorized?: #f))

(def (healthcare-tlc-model-receipt-read-file path)
  (let* ((datum (call-with-input-file path read))
         (ref (lambda (key)
                (let (entry (assq key datum))
                  (and entry (cdr entry))))))
    (unless (and (equal? (ref 'model)
                         "HealthcareAIAssistedPrescriptionCausality")
                 (equal? (ref 'source-digest) +tla-source-content-id+)
                 (equal? (ref 'config-digest) +tla-config-content-id+)
                 (ref 'admitted))
      (error "TLC receipt does not qualify the exact Healthcare AI Case" path))
    (healthcare-tlc-model-receipt
     (ref 'states-generated) (ref 'distinct-states)
     (ref 'states-left) (ref 'graph-depth))))

(def (healthcare-lean-refinement-receipt-read-file path)
  (let* ((datum (call-with-input-file path read))
         (ref (lambda (key)
                (let (entry (assq key datum))
                  (and entry (cdr entry))))))
    (unless (and (equal? (ref 'library) +lean-library+)
                 (equal? (ref 'module) +lean-module+)
                 (equal? (ref 'source-digest) +lean-source-content-id+)
                 (equal? (ref 'certifications) +lean-certifications+)
                 (ref 'admitted))
      (error "Lean receipt does not qualify the exact Healthcare AI Case" path))
    (.o kind: 'lambda-episteme.healthcare-lean-refinement-receipt
        case-id: +case-id+
        library: +lean-library+
        module: +lean-module+
        source-content-id: +lean-source-content-id+
        certifications: +lean-certifications+
        admitted?: #t
        release-authorized?: #f)))

(def (tlc-receipt-valid? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind case-id model source-content-id config-content-id
                     generated-states distinct-states states-left graph-depth
                     admitted? release-authorized?))
       (eq? (.ref value 'kind)
            'lambda-episteme.healthcare-tlc-model-receipt)
       (eq? (.ref value 'case-id) +case-id+)
       (equal? (.ref value 'source-content-id) +tla-source-content-id+)
       (equal? (.ref value 'config-content-id) +tla-config-content-id+)
       (.ref value 'admitted?)
       (eq? (.ref value 'states-left) 0)
       (eq? (.ref value 'release-authorized?) #f)))

(def (lean-receipt-valid? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind case-id library module source-content-id certifications
                     admitted? release-authorized?))
       (eq? (.ref value 'kind)
            'lambda-episteme.healthcare-lean-refinement-receipt)
       (eq? (.ref value 'case-id) +case-id+)
       (equal? (.ref value 'library) +lean-library+)
       (equal? (.ref value 'module) +lean-module+)
       (equal? (.ref value 'source-content-id) +lean-source-content-id+)
       (equal? (.ref value 'certifications) +lean-certifications+)
       (.ref value 'admitted?)
       (eq? (.ref value 'release-authorized?) #f)))

(def (classification-valid? value)
  (and (eq? (.ref value 'status) 'bounded-temporal-classification)
       (equal? (.ref value 'trigger-event-id)
               "ai-tmp-smx-recommendation-1")
       (equal? (.ref value 'counterfactual-event-ids)
               '("wrong-ai-auto-approval-1"
                 "wrong-tmp-smx-administration-1"))
       (equal? (.ref value 'hypothesized-event-ids)
               '("elevated-anticoagulation-risk-1"))
       (null? (.ref value 'unknown-frontier))
       (eq? (.ref value 'assurance-closed?) #f)
       (eq? (.ref value 'release-authorized?) #f)))

(def (formal-assurance-binding-valid? value trajectory-digest)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind engine profile-identity trajectory-contract-identity
                     trajectory-assessment-digest evidence-source-content-id
                     evidence-admitted?))
       (eq? (.ref value 'kind)
            'lambda-episteme.healthcare-formal-assurance-binding)
       (memq (.ref value 'engine) '(tla-plus lean))
       (equal? (.ref value 'trajectory-assessment-digest)
               trajectory-digest)
       (.ref value 'evidence-admitted?)))

(def (formal-assurance-binding-canonical value)
  (list (.ref value 'engine)
        (.ref value 'profile-identity)
        (.ref value 'trajectory-contract-identity)
        (.ref value 'trajectory-assessment-digest)
        (.ref value 'evidence-source-content-id)
        (if (.slot? value 'evidence-certifications)
          (.ref value 'evidence-certifications)
          '())))

(def (healthcare-case-assurance-digest value)
  (unless (healthcare-case-assurance? value)
    (error "invalid Healthcare Case assurance receipt" value))
  (.ref value 'assurance-digest))

(def (healthcare-case-trajectory-assessment-digest value)
  (unless (healthcare-case-assurance? value)
    (error "invalid Healthcare Case assurance receipt" value))
  (.ref value 'trajectory-assessment-digest))

(def (healthcare-case-assurance-certifications value)
  (unless (healthcare-case-assurance? value)
    (error "invalid Healthcare Case assurance receipt" value))
  (append
   (.ref (.ref value 'lean-receipt) 'certifications)
   '("PooFlowProof.Enterprise.GovernanceThreatAssuranceClosure"
     "PooFlowProof.PooC3.CedarDualEngineArbitration")))

(def (healthcare-case-assurance? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind case-id query-contracts temporal-classification
                     trajectory-assessment trajectory-assessment-digest
                     formal-assurance-bindings
                     tlc-receipt lean-receipt assurance-digest
                     assurance-closed? release-authorized?
                     runtime-executed? analysis-runtime-executed?))
       (eq? (.ref value 'kind)
            'lambda-episteme.healthcare-case-assurance-receipt)
       (eq? (.ref value 'case-id) +case-id+)
       (equal? (.ref value 'query-contracts) +query-contract-canonical+)
       (classification-valid? (.ref value 'temporal-classification))
       (poo-flow-causal-trajectory-assessment?
        (.ref value 'trajectory-assessment))
       (.ref (.ref value 'trajectory-assessment) 'accepted?)
       (equal?
        (.ref value 'trajectory-assessment-digest)
        (poo-flow-causal-trajectory-assessment-digest
         (.ref value 'trajectory-assessment)))
       (let (trajectory-digest (.ref value 'trajectory-assessment-digest))
         (and (list? (.ref value 'formal-assurance-bindings))
              (= (length (.ref value 'formal-assurance-bindings)) 2)
              (every (lambda (binding)
                       (formal-assurance-binding-valid?
                        binding trajectory-digest))
                     (.ref value 'formal-assurance-bindings))))
       (tlc-receipt-valid? (.ref value 'tlc-receipt))
       (lean-receipt-valid? (.ref value 'lean-receipt))
       (string? (.ref value 'assurance-digest))
       (.ref value 'assurance-closed?)
       (eq? (.ref value 'release-authorized?) #f)
       (eq? (.ref value 'analysis-runtime-executed?) #f)
       (.ref value 'runtime-executed?)))

(def (healthcare-case-assurance receipt root tlc-value lean-value)
  (unless (and (ontology-case-composition-receipt? receipt)
               (.ref receipt 'accepted?)
               (.ref receipt 'trajectory-handoff-ready?)
               (.ref receipt 'governance-handoff-ready?)
               (eq? (.ref receipt 'case-id) +case-id+)
               (tlc-receipt-valid? tlc-value)
               (lean-receipt-valid? lean-value))
    (error "Healthcare assurance requires the admitted exact Case and proof receipts"))
  ;; This admits exact source bytes only. Gerbil Parser and any later MRR Rust
  ;; Runtime retain their own independent parser/runtime qualifications.
  (for-each (lambda (query) (healthcare-query-source-path query root))
            +query-contracts+)
  ;; Keep lexical parameter names distinct from .o slot names below. POO slots
  ;; are lazy: `tlc-receipt: tlc-receipt` would resolve the slot recursively.
  (let* ((trajectory-assessments (.ref receipt 'trajectory-assessments))
         (_trajectory-count
          (unless (= (length trajectory-assessments) 1)
            (error "Healthcare Case requires exactly one trajectory assessment"
                   trajectory-assessments)))
         (trajectory-value (car trajectory-assessments))
         (trajectory-digest-value
          (poo-flow-causal-trajectory-assessment-digest
           trajectory-value))
         (assurance-profile
          (find (lambda (profile)
                  (eq? profile AIClinicalDecisionSupportProfile))
                (.ref receipt 'profiles)))
         (_profile-present
          (unless assurance-profile
            (error "Healthcare Case lacks the AI assurance Profile")))
         (formal-bindings-value
          (list
           (healthcare-formal-assurance-project
            HealthcareTLAPlusAssuranceProjector assurance-profile
            trajectory-value tlc-value)
           (healthcare-formal-assurance-project
            HealthcareLeanAssuranceProjector assurance-profile
            trajectory-value lean-value)))
         (event-graph
          (poo-flow-causal-event-graph "patient-1" (.ref receipt 'events)))
         (cut (poo-flow-causal-cut event-graph 6))
         (classification
          (poo-flow-temporal-causal-classify
           event-graph cut "ai-tmp-smx-recommendation-1" 9)))
    (unless (classification-valid? classification)
      (error "Healthcare temporal classification assurance failed"))
    (let* ((canonical
            (list 'lambda-episteme.healthcare-case-assurance.v1
                  +case-id+
                  +query-contract-canonical+
                  (.ref classification 'event-graph-identity)
                  (.ref classification 'cut-identity)
                  (.ref classification 'counterfactual-event-ids)
                  (.ref classification 'hypothesized-event-ids)
                  trajectory-digest-value
                  (map formal-assurance-binding-canonical
                       formal-bindings-value)
                  (map (lambda (slot) (.ref tlc-value slot))
                       '(source-content-id config-content-id generated-states
                         distinct-states states-left graph-depth))
                  (map (lambda (slot) (.ref lean-value slot))
                       '(library module source-content-id certifications))))
           (value
            (.o kind: 'lambda-episteme.healthcare-case-assurance-receipt
                case-id: +case-id+
                query-contracts: +query-contract-canonical+
                temporal-classification: classification
                trajectory-assessment: trajectory-value
                trajectory-assessment-digest: trajectory-digest-value
                formal-assurance-bindings: formal-bindings-value
                tlc-receipt: tlc-value
                lean-receipt: lean-value
                assurance-digest: (digest canonical)
                assurance-closed?: #t
                release-authorized?: #f
                runtime-executed?: #t
                analysis-runtime-executed?: #f)))
      (unless (healthcare-case-assurance? value)
        (error "invalid Healthcare Case assurance closure"))
      value)))
