;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .all-slots .cc .ref)
        :poo-flow/src/modules/standards/interface
        (only-in :poo-flow/src/modules/authorization/providers/cedar/interface
                 poo-flow-cedar-authorization-request?
                 poo-flow-cedar-decision
                 poo-flow-cedar-runtime-handoff)
        :poo-flow/lambda-episteme/modules/healthcare/standards/interface)

(export standards-healthcare-migration-test)

(def migration-terminology-snapshot
  (poo-flow-standard-digest 'au-legacy-migration-test-terminology))

(def migration-test-digest
  (poo-flow-standard-digest 'au-legacy-migration-test-evidence))

(def (materialized-au-core-patient-constraints)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget migration-terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution))
         (context
          (poo-flow-standard-materialization-context
           "test/healthcare/migration/materialization"
           (.ref bundle 'artifacts)))
         (receipt
          (poo-flow-standard-materialize
           context +poo-flow-fhir-au-core-patient-artifact-identity+)))
    (poo-flow-fhir-au-core-patient-constraints
     (poo-flow-standard-materialization-receipt-artifact receipt))))

(def (migration-validation candidate)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget migration-terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution))
         (closure
          (poo-flow-standard-make-validation-closure
           (.ref FHIRAUCorePatientStandardProfile 'identity)
           bundle +poo-flow-fhir-provider-identity+ 'fhir-json
           (poo-flow-standard-digest candidate)
           (materialized-au-core-patient-constraints)))
         (conformance
          (healthcare-standard-validate
           FHIRValidationExecutor FHIRAUCorePatientStandardProfile
           closure candidate)))
    (values closure conformance)))

(def (migration-case-variant source-interface source-version
                             qualification-state target-standard-edition
                             unmapped-required-fields ai-role review-decision)
  (let* ((base-case AULegacyHL7v2PatientMigrationCase)
         (base-proposal (.ref base-case 'proposal))
         (source-snapshot-digest
          (poo-flow-standard-digest
           (list 'test-source source-interface source-version)))
         (mapping-evidence-digest
          (.ref base-proposal 'mapping-evidence-digest))
         (field-mappings
          (.ref (.ref base-case 'ai-analysis) 'field-mappings))
         (analysis
          (healthcare-standard-migration-ai-analysis
           (string-append "test/ai-analysis/"
                          (symbol->string source-interface))
           source-interface source-version source-snapshot-digest
           target-standard-edition (.ref base-proposal 'target-profile)
           field-mappings unmapped-required-fields
           '(semantic-drift parallel-interface-divergence)
           'shadow-validate-then-phased-cutover
           "ai-mapping-assistant/test" ai-role))
         (proposal
          (healthcare-standard-migration-proposal
           (.ref base-proposal 'identity)
           source-interface
           (.ref base-proposal 'target-profile)
           (.ref base-proposal 'candidate-digest)
           mapping-evidence-digest
           (.ref analysis 'analysis-digest)
           (.ref base-proposal 'proposed-by)
           ai-role))
         (review
          (healthcare-standard-migration-review
           proposal "human-reviewer/test" review-decision
           (poo-flow-standard-digest
            (list 'test-review-evidence review-decision)))))
    (healthcare-standard-migration-case
     (.ref base-case 'identity) (.ref base-case 'jurisdiction)
     source-interface source-version target-standard-edition
     source-snapshot-digest
     (poo-flow-standard-digest (list source-interface 'parser-receipt))
     (poo-flow-standard-digest (list source-interface 'parser-grammar))
     qualification-state
     (poo-flow-standard-digest
      (list 'gerbil-parser-hl7v2-qualification
            source-snapshot-digest
            (poo-flow-standard-digest
             (list source-interface 'parser-grammar))
            (poo-flow-standard-digest
             (list source-interface 'parser-receipt))))
     analysis proposal review)))

(def (migration-case-with ai-role review-decision)
  (migration-case-variant
   'hl7v2 "2.5.1" 'qualified "hl7.fhir.au.core@1.0.0" '()
   ai-role review-decision))

(def (migration-case-with-interface source-interface qualification-state)
  (migration-case-variant
   source-interface "unqualified" qualification-state
   "hl7.fhir.au.core@1.0.0" '() 'advisory-only 'approved))

(def standards-healthcare-migration-test
  (test-suite "AU legacy healthcare interface to FHIR migration Case"
    (test-case "Australia explicitly models coexisting interface families"
      (let* ((feature
              (.ref (.ref HealthcareStandardsModule 'features) 'migration))
             (fixture (.ref (.ref feature 'fixtures) 'australia))
             (interfaces
              (.ref AULegacyHealthcareInterfaceLandscape 'legacy-interfaces)))
        (check-equal? (poo-flow-standard-feature-module? feature) #t)
        (check-equal? (.ref feature 'feature-kind) 'migration)
        (check-equal? (.ref fixture 'landscape)
                      AULegacyHealthcareInterfaceLandscape)
        (check-equal? (length (.all-slots interfaces)) 3)
        (check-equal? (and (member 'hl7v2 (.all-slots interfaces)) #t) #t)
        (check-equal? (and (member 'cda (.all-slots interfaces)) #t) #t)
        (check-equal?
         (and (member 'national-service (.all-slots interfaces)) #t) #t)
        (check-equal?
         (.ref (.ref interfaces 'hl7v2) 'syntax-owner) 'gerbil-parser)
        (check-equal?
         (.ref (.ref interfaces 'hl7v2) 'qualification-state) 'qualified)
        (check-equal?
         (.ref (.ref interfaces 'cda) 'qualification-state) 'declared-only)
        (check-equal?
         (.ref (.ref interfaces 'national-service) 'qualification-state)
         'declared-only)
        (check-equal?
         (.ref AULegacyHealthcareInterfaceLandscape 'target-profile)
         "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")))
    (test-case "fixture binds advisory proposal and independent human review"
      (check-equal? (.ref AULegacyHealthcareInterfaceLandscape 'ai-role)
                    'advisory-only)
      (check-equal? (.ref AULegacyHealthcareInterfaceLandscape
                          'authorization-owner)
                    'human-reviewer)
      (check-equal?
       (healthcare-standard-migration-ai-analysis?
        (.ref AULegacyHL7v2PatientMigrationCase 'ai-analysis)) #t)
      (check-equal?
       (.ref AULegacyHL7v2PatientAIAnalysis 'workflow-stages)
       +healthcare-standard-migration-ai-workflow-stages+)
      (check-equal?
       (.ref AULegacyHL7v2PatientAIAnalysis 'target-standard-edition)
       "hl7.fhir.au.core@1.0.0")
      (check-equal?
       (.ref AULegacyHL7v2PatientAIAnalysis 'unmapped-required-fields) '())
      (check-equal?
       (.ref (.ref AULegacyHL7v2PatientFieldMappings 'patient-identifier)
             'source-path) "PID-3")
      (check-equal?
       (.ref (.ref AULegacyHL7v2PatientFieldMappings 'patient-name)
             'target-path) "Patient.name[0]")
      (check-equal?
       (healthcare-standard-migration-proposal?
        (.ref AULegacyHL7v2PatientMigrationCase 'proposal)) #t)
      (check-equal?
       (healthcare-standard-migration-review?
        (.ref AULegacyHL7v2PatientMigrationCase 'review)) #t)
      (check-equal? (.ref AULegacyHL7v2PatientMigrationCase
                          'source-interface)
                    'hl7v2)
      (check-equal? (.ref AULegacyHL7v2PatientMigrationReview 'decision)
                    'approved))
    (test-case "governance is a mandatory staged POO Interface"
      (let* ((interface HealthcareStandardMigrationGovernanceInterface)
             (admit
              ((.ref interface '.validate-governance) 'admit))
             (cutover
              ((.ref interface '.validate-governance) 'cutover))
             (impact (.ref (.ref interface 'bindings) 'impact-contract)))
        (check-equal?
         (.ref interface 'required-slots)
         '(authority-provider human-authorization formal-model refinement-proof
           impact-contract conformance audit-receipt))
        (check-equal?
         (.ref interface 'optional-slots)
         '(documentation presentation-metadata reference-implementation
           non-authoritative-analysis))
        (check-equal? (.ref admit 'valid?) #t)
        (check-equal? (.ref cutover 'valid?) #f)
        (check-equal? (.ref cutover 'invalid-status-slots)
                      (.ref interface 'required-slots))
        (check-equal? (.ref impact 'evidence-kind)
                      'tla-to-lean-proof-impact)
        (check-equal?
         (.ref (.ref impact 'payload) 'upstream-source-digest)
         (.ref AUHealthcareMigrationFormalModelEvidence 'source-digest))
        (check-equal?
         (.ref (.ref impact 'payload) 'downstream-source-digest)
         (.ref AUHealthcareMigrationRefinementProofEvidence 'source-digest))
        (check-exception
         ((.ref interface '.write-governance)
          (.cc impact 'payload
               (.cc (.ref impact 'payload) 'upstream-source-digest
                    (poo-flow-standard-digest 'stale-tla-model))))
         true)))
    (test-case "reviewed AI proposal is admitted only after AU Core conformance"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let (receipt
               (healthcare-standard-migration-admit
                AULegacyHL7v2PatientMigrationCase closure conformance
                HealthcareStandardMigrationGovernanceInterface))
           (check-equal? (.ref conformance 'valid?) #t)
           (check-equal? (.ref receipt 'valid?) #t)
           (check-equal? (length (.ref receipt 'evidence-digests)) 10)
           (check-equal? (.ref receipt 'ai-analysis-digest)
                         (.ref AULegacyHL7v2PatientAIAnalysis
                               'analysis-digest))
           (check-equal? (.ref receipt 'workflow-stages)
                         +healthcare-standard-migration-ai-workflow-stages+)
           (check-equal? (.ref receipt 'failures) '())
           (let* ((handoff
                   (poo-flow-cedar-runtime-handoff
                    1 #u8(1 2 3) migration-test-digest migration-test-digest
                    migration-test-digest migration-test-digest))
                  (request
                   (healthcare-standard-migration-cedar-request
                    AULegacyHL7v2PatientMigrationCase receipt
                    (.ref
                     (.ref
                      (.ref HealthcareStandardMigrationGovernanceInterface
                            'bindings)
                      'impact-contract)
                     'content-digest)
                    handoff)))
             (check-equal?
              (poo-flow-cedar-authorization-request? request) #t)
             (check-equal?
              (.ref request 'principal)
              "Healthcare::MigrationReviewer::\"human-reviewer/example-au-clinical-informatician\"")
             (check-equal?
              (.ref request 'action)
              "Healthcare::Action::\"approveStandardMigrationCutover\"")
             (let* ((decision
                     (poo-flow-cedar-decision
                      "migration-human-permit-1" 'permit
                      "healthcare-standard-migration-human-authorization"
                      migration-test-digest migration-test-digest
                      '(independent-human-review)))
                    (binding
                     (healthcare-standard-migration-human-authorization-binding
                      request decision))
                    (updated
                     ((.ref HealthcareStandardMigrationGovernanceInterface
                            '.write-governance)
                      binding))
                    (cutover
                     ((.ref updated '.validate-governance) 'cutover)))
               (check-equal? (.ref binding 'status) 'admitted)
               (check-equal?
                (memq 'human-authorization
                      (.ref cutover 'invalid-status-slots))
                #f)))))))
    (test-case "migration admission fails when mandatory governance is absent"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let* ((receipt
                 (healthcare-standard-migration-admit
                  AULegacyHL7v2PatientMigrationCase closure conformance
                  PooFlowStandardMigrationGovernanceInterface.))
                (codes
                 (map (lambda (failure) (.ref failure 'code))
                      (.ref receipt 'failures))))
           (check-equal? (.ref receipt 'valid?) #f)
           (check-equal?
            (and (member 'healthcare-migration-governance-incomplete codes)
                 #t)
            #t)))))
    (test-case "declared-only CDA and national-service interfaces fail closed"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (for-each
          (lambda (source-interface)
            (let* ((receipt
                    (healthcare-standard-migration-admit
                     (migration-case-with-interface
                      source-interface 'declared-only)
                     closure conformance
                     HealthcareStandardMigrationGovernanceInterface))
                   (codes
                    (map (lambda (failure) (.ref failure 'code))
                         (.ref receipt 'failures))))
              (check-equal? (.ref receipt 'valid?) #f)
              (check-equal?
               (and (member
                     'healthcare-migration-source-interface-unqualified
                     codes)
                    #t)
               #t)))
          '(cda national-service)))))
    (test-case "unresolved AI mapping gaps and target edition drift fail closed"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let* ((receipt
                 (healthcare-standard-migration-admit
                  (migration-case-variant
                   'hl7v2 "2.5.1" 'qualified
                   "hl7.fhir.au.core@future" '(patient-identifier)
                   'advisory-only 'approved)
                  closure conformance
                  HealthcareStandardMigrationGovernanceInterface))
                (codes
                 (map (lambda (failure) (.ref failure 'code))
                      (.ref receipt 'failures))))
           (check-equal? (.ref receipt 'valid?) #f)
           (check-equal?
            (and (member
                  'healthcare-migration-required-mapping-unresolved codes)
                 #t) #t)
           (check-equal?
            (and (member 'healthcare-migration-target-edition-mismatch codes)
                 #t) #t)))))
    (test-case "tampered parser evidence fails source qualification binding"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let* ((tampered
                 (.cc AULegacyHL7v2PatientMigrationCase
                      'parser-receipt-digest
                      (poo-flow-standard-digest '(tampered-parser-receipt))))
                (receipt
                 (healthcare-standard-migration-admit
                  tampered closure conformance
                  HealthcareStandardMigrationGovernanceInterface))
                (codes
                 (map (lambda (failure) (.ref failure 'code))
                      (.ref receipt 'failures))))
           (check-equal? (.ref receipt 'valid?) #f)
           (check-equal?
            (and (member
                  'healthcare-migration-source-qualification-unbound codes)
                 #t) #t)))))
    (test-case "AI authority or rejected human review fails closed"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let* ((receipt
                 (healthcare-standard-migration-admit
                  (migration-case-with 'automated-decision 'rejected)
                  closure conformance
                  HealthcareStandardMigrationGovernanceInterface))
                (codes
                 (map (lambda (failure) (.ref failure 'code))
                      (.ref receipt 'failures))))
           (check-equal? (.ref receipt 'valid?) #f)
           (check-equal?
            (member 'healthcare-migration-ai-authority-forbidden codes)
            '(healthcare-migration-ai-authority-forbidden
              healthcare-migration-human-approval-missing))
           (check-equal?
            (member 'healthcare-migration-human-approval-missing codes)
            '(healthcare-migration-human-approval-missing))))))))
