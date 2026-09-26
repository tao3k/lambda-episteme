;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph-edge-kind
                 poo-flow-graph-edges
                 poo-flow-graph-node-id
                 poo-flow-graph-nodes)
        (only-in :poo-flow/src/module-system/profile-composition/interface
                 poo-flow-scenario-case-name)
        (only-in :poo-flow/modules/standards/interface
                 poo-flow-standard-governance-interface?)
        :poo-flow/lambda-episteme/modules/healthcare/standards/migration/interface
        :poo-flow/lambda-episteme/modules/ontology/interface
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/au-legacy-interface-fhir-migration/case)

(export healthcare-standard-migration-case-test)

(def migration-case-composition-receipt
  (ontology-compose-case AULegacyInterfaceFHIRMigrationCase))

(def healthcare-standard-migration-case-test
  (test-suite
   "AI-assisted AU HL7v2 to FHIR migration Ontology Case"

   (test-case "the demand-loaded Case composes only migration governance"
     (check-equal?
      (ontology-case-composition-receipt?
       migration-case-composition-receipt) #t)
     (check-equal? (.ref migration-case-composition-receipt 'accepted?) #t)
     (check-equal? (.ref migration-case-composition-receipt 'scenario)
                   'healthcare)
     (check-equal?
      (map poo-flow-scenario-case-name
           (.ref AULegacyInterfaceFHIRMigrationCase 'compositions))
      '(common healthcare regions))
     (check-equal?
      (map (lambda (profile) (.ref profile 'name))
           (.ref migration-case-composition-receipt 'profiles))
      '(evidence privacy healthcare-base australia-standard-migration))
     (check-equal?
      (.ref migration-case-composition-receipt 'governance-handoff-ready?) #t))

   (test-case "the Case pins one exact migration path rather than latest"
     (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase 'case-id)
                   'au-legacy-interface-fhir-migration)
     (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase
                         'migration-path-id)
                   'au-hl7v2-adt-a08-to-au-core-patient)
     (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase
                         'source-standard-edition)
                   "HL7v2@2.5.1/ADT^A08")
     (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase
                         'target-standard-edition)
                   "hl7.fhir.au.core@1.0.0")
     (check-equal? (.ref AULegacyHL7v2PatientMigrationCase
                         'target-standard-edition)
                   "hl7.fhir.au.core@1.0.0"))

   (test-case "AI analysis is typed, evidence-bound and advisory"
     (let (analysis
           (.ref AULegacyInterfaceFHIRMigrationCase 'ai-migration-analysis))
       (check-equal?
        (healthcare-standard-migration-ai-analysis? analysis) #t)
       (check-equal? (.ref analysis 'workflow-stages)
                     +healthcare-standard-migration-ai-workflow-stages+)
       (check-equal? (.ref analysis 'unmapped-required-fields) '())
       (check-equal?
        (.ref (.ref (.ref analysis 'field-mappings) 'patient-identifier)
              'target-path)
        "Patient.identifier[0]")
       (check-equal? (.ref analysis 'ai-role) 'advisory-only)
       (check-equal? (.ref analysis 'cutover-strategy)
                     'shadow-validate-then-phased-cutover)
       (check-equal?
        (.ref (.ref AULegacyInterfaceFHIRMigrationCase 'migration-proposal)
              'ai-analysis-digest)
        (.ref analysis 'analysis-digest))))

   (test-case "the Case exposes mandatory Standard governance"
     (let* ((governance HealthcareStandardMigrationGovernanceInterface)
            (admit ((.ref governance '.validate-governance) 'admit))
            (cutover ((.ref governance '.validate-governance) 'cutover)))
       (check-equal? (poo-flow-standard-governance-interface? governance) #t)
       (check-equal?
        (.ref AULegacyInterfaceFHIRMigrationCase
              'standard-governance-interface-identity)
        (.ref governance 'identity))
       (check-equal? (.ref admit 'valid?) #t)
       (check-equal? (.ref cutover 'valid?) #f)
       (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase
                           'formal-impact-bound?) #t)
       (check-equal? (.ref AULegacyInterfaceFHIRMigrationCase
                           'cedar-human-authorization-required?) #t)))

   (test-case "the Case graph exposes the complete governed migration flow"
     (let* ((graph (.ref AULegacyInterfaceFHIRMigrationCase 'graph))
            (node-ids (map poo-flow-graph-node-id
                           (poo-flow-graph-nodes graph)))
            (edge-kinds (map poo-flow-graph-edge-kind
                             (poo-flow-graph-edges graph))))
       (check-equal?
        node-ids
        '(legacy-interface parser-receipt ai-migration-analysis
          ai-mapping-proposal human-review au-core-candidate
          conformance-receipt tla-formal-model lean-refinement-proof
          formal-impact-contract migration-admission
          cedar-human-authorization-request
          cedar-human-authorization-decision phased-cutover-readiness))
       (check-equal?
        edge-kinds
        '(PARSED_WITH_EVIDENCE BOUNDS_ANALYSIS BOUNDS_PROPOSAL REVIEWED_BY
          APPROVES_CANDIDATE VALIDATED_BY CHECKED_BY_MODEL REFINED_BY
          BOUND_BY_IMPACT GATES_ADMISSION GATES_ADMISSION
          REQUESTS_HUMAN_AUTHORIZATION AUTHORIZED_BY GATES_CUTOVER))))))
