;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o .ref)
        (rename-in
         (only-in :poo-flow/src/graph/types
                  graph poo-flow-graph-edge poo-flow-graph-node)
         (graph Graph))
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/migration/interface
                 AULegacyHealthcareInterfaceLandscape
                 AULegacyHL7v2PatientAIAnalysis
                 AULegacyHL7v2PatientFHIRCandidate
                 AULegacyHL7v2PatientMigrationCase
                 AULegacyHL7v2PatientMigrationProposal
                 AULegacyHL7v2PatientMigrationReview
                 HealthcareStandardMigrationGovernanceInterface)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/regions/australia-standard-migration
                 AustraliaHealthcareStandardMigrationProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario))

(export AULegacyInterfaceFHIRMigrationCase)

;;; Case: an Australian provider keeps its legacy interfaces online while an
;;; AI assistant proposes an AU Core Patient candidate.  Parser evidence,
;;; deterministic conformance and human review remain independent gates.
(.def (AULegacyInterfaceFHIRMigrationCase @ OntologyCase)
  (case-id 'au-legacy-interface-fhir-migration)
  (scenario HealthcareScenario)
  (migration-path-id 'au-hl7v2-adt-a08-to-au-core-patient)
  (source-standard-edition "HL7v2@2.5.1/ADT^A08")
  (target-standard-edition "hl7.fhir.au.core@1.0.0")
  (legacy-interface-landscape AULegacyHealthcareInterfaceLandscape)
  (ai-migration-analysis AULegacyHL7v2PatientAIAnalysis)
  (migration-contract AULegacyHL7v2PatientMigrationCase)
  (migration-candidate AULegacyHL7v2PatientFHIRCandidate)
  (migration-proposal AULegacyHL7v2PatientMigrationProposal)
  (migration-review AULegacyHL7v2PatientMigrationReview)
  ;; A Case retains the stable interface identity, not the executable Interface
  ;; object whose Agent-write methods close over immutable POO state.  The
  ;; Healthcare Standard Feature remains the sole owner of that Interface.
  (standard-governance-interface-identity
   (.ref HealthcareStandardMigrationGovernanceInterface 'identity))
  (legacy-interface-remains-active? #t)
  (parser-receipt-bound? #t)
  (ai-advisory-only? #t)
  (independent-human-review? #t)
  (target-conformance-required? #t)
  (formal-impact-bound? #t)
  (cedar-human-authorization-required? #t)
  (rollback-source-snapshot-retained? #t)

  (.use-composition
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile)
       regions:
       (.o australia-standard-migration:
           AustraliaHealthcareStandardMigrationProfile)))

  (graph
   (.o (:: @ Graph)
       graph-id: 'au-legacy-interface-fhir-migration
       .add-node:
       (.o legacy-interface:
           (poo-flow-graph-node 'legacy-interface 'HL7v2Interface)
           parser-receipt:
           (poo-flow-graph-node 'parser-receipt 'ParserReceipt)
           ai-migration-analysis:
           (poo-flow-graph-node 'ai-migration-analysis
                                'AIMigrationAnalysis)
           ai-mapping-proposal:
           (poo-flow-graph-node 'ai-mapping-proposal 'AIMappingProposal)
           human-review:
           (poo-flow-graph-node 'human-review 'HumanReview)
           au-core-candidate:
           (poo-flow-graph-node 'au-core-candidate 'FHIRPatient)
           conformance-receipt:
           (poo-flow-graph-node 'conformance-receipt 'ConformanceReceipt)
           tla-formal-model:
           (poo-flow-graph-node 'tla-formal-model 'TLAPlusModelReceipt)
           lean-refinement-proof:
           (poo-flow-graph-node 'lean-refinement-proof 'LeanProofReceipt)
           formal-impact-contract:
           (poo-flow-graph-node 'formal-impact-contract 'ProofImpactContract)
           migration-admission:
           (poo-flow-graph-node 'migration-admission 'MigrationAdmission)
           cedar-human-authorization-request:
           (poo-flow-graph-node 'cedar-human-authorization-request
                                'CedarAuthorizationRequest)
           cedar-human-authorization-decision:
           (poo-flow-graph-node 'cedar-human-authorization-decision
                                'CedarDecision)
           phased-cutover-readiness:
           (poo-flow-graph-node 'phased-cutover-readiness
                                'CutoverReadiness))
       .add-edge:
       (.o parser-reads-legacy:
           (poo-flow-graph-edge
            'legacy-interface 'parser-receipt 'PARSED_WITH_EVIDENCE)
           analysis-uses-parser-evidence:
           (poo-flow-graph-edge
            'parser-receipt 'ai-migration-analysis 'BOUNDS_ANALYSIS)
           proposal-uses-analysis:
           (poo-flow-graph-edge
            'ai-migration-analysis 'ai-mapping-proposal 'BOUNDS_PROPOSAL)
           proposal-reviewed-by-human:
           (poo-flow-graph-edge
            'ai-mapping-proposal 'human-review 'REVIEWED_BY)
           review-approves-candidate:
           (poo-flow-graph-edge
            'human-review 'au-core-candidate 'APPROVES_CANDIDATE)
           candidate-has-conformance:
           (poo-flow-graph-edge
            'au-core-candidate 'conformance-receipt 'VALIDATED_BY)
           conformance-checked-by-model:
           (poo-flow-graph-edge
            'conformance-receipt 'tla-formal-model 'CHECKED_BY_MODEL)
           model-refined-by-lean:
           (poo-flow-graph-edge
            'tla-formal-model 'lean-refinement-proof 'REFINED_BY)
           refinement-bound-by-impact:
           (poo-flow-graph-edge
            'lean-refinement-proof 'formal-impact-contract 'BOUND_BY_IMPACT)
           conformance-gates-admission:
           (poo-flow-graph-edge
            'conformance-receipt 'migration-admission 'GATES_ADMISSION)
           impact-gates-admission:
           (poo-flow-graph-edge
            'formal-impact-contract 'migration-admission 'GATES_ADMISSION)
           admission-requests-human-authorization:
           (poo-flow-graph-edge
            'migration-admission 'cedar-human-authorization-request
            'REQUESTS_HUMAN_AUTHORIZATION)
           human-request-authorized-by-cedar:
           (poo-flow-graph-edge
            'cedar-human-authorization-request
            'cedar-human-authorization-decision 'AUTHORIZED_BY)
           cedar-decision-gates-cutover:
           (poo-flow-graph-edge
            'cedar-human-authorization-decision 'phased-cutover-readiness
            'GATES_CUTOVER)))))
