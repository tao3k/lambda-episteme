;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :poo-flow/src/graph/types
                  graph poo-flow-graph-edge poo-flow-graph-node)
         (graph Graph))
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/migration/interface
                 AULegacyHealthcareInterfaceLandscape
                 AULegacyHL7v2PatientFHIRCandidate
                 AULegacyHL7v2PatientMigrationCase
                 AULegacyHL7v2PatientMigrationProposal
                 AULegacyHL7v2PatientMigrationReview)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/regions/australia
                 AustraliaHealthcareRegionProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario))

(export AULegacyInterfaceFHIRMigrationCase)

;;; Case: an Australian provider keeps its legacy interfaces online while an
;;; AI assistant proposes an AU Core Patient candidate.  Parser evidence,
;;; deterministic conformance and human review remain independent gates.
(.def (AULegacyInterfaceFHIRMigrationCase @ OntologyCase)
  (case-id 'au-legacy-interface-fhir-migration)
  (scenario HealthcareScenario)
  (legacy-interface-landscape AULegacyHealthcareInterfaceLandscape)
  (migration-contract AULegacyHL7v2PatientMigrationCase)
  (migration-candidate AULegacyHL7v2PatientFHIRCandidate)
  (migration-proposal AULegacyHL7v2PatientMigrationProposal)
  (migration-review AULegacyHL7v2PatientMigrationReview)
  (legacy-interface-remains-active? #t)
  (parser-receipt-bound? #t)
  (ai-advisory-only? #t)
  (independent-human-review? #t)
  (target-conformance-required? #t)
  (rollback-source-snapshot-retained? #t)

  (.use-composition
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile)
       regions:
       (.o australia: AustraliaHealthcareRegionProfile)))

  (graph
   (.o (:: @ Graph)
       graph-id: 'au-legacy-interface-fhir-migration
       .add-node:
       (.o legacy-interface:
           (poo-flow-graph-node 'legacy-interface 'HL7v2Interface)
           parser-receipt:
           (poo-flow-graph-node 'parser-receipt 'ParserReceipt)
           ai-mapping-proposal:
           (poo-flow-graph-node 'ai-mapping-proposal 'AIMappingProposal)
           human-review:
           (poo-flow-graph-node 'human-review 'HumanReview)
           au-core-candidate:
           (poo-flow-graph-node 'au-core-candidate 'FHIRPatient)
           conformance-receipt:
           (poo-flow-graph-node 'conformance-receipt 'ConformanceReceipt)
           migration-admission:
           (poo-flow-graph-node 'migration-admission 'MigrationAdmission))
       .add-edge:
       (.o parser-reads-legacy:
           (poo-flow-graph-edge
            'legacy-interface 'parser-receipt 'PARSED_WITH_EVIDENCE)
           proposal-uses-parser-evidence:
           (poo-flow-graph-edge
            'parser-receipt 'ai-mapping-proposal 'BOUNDS_PROPOSAL)
           proposal-reviewed-by-human:
           (poo-flow-graph-edge
            'ai-mapping-proposal 'human-review 'REVIEWED_BY)
           review-approves-candidate:
           (poo-flow-graph-edge
            'human-review 'au-core-candidate 'APPROVES_CANDIDATE)
           candidate-has-conformance:
           (poo-flow-graph-edge
            'au-core-candidate 'conformance-receipt 'VALIDATED_BY)
           conformance-gates-admission:
           (poo-flow-graph-edge
            'conformance-receipt 'migration-admission 'GATES_ADMISSION)))))
