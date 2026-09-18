;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .all-slots .ref)
        :poo-flow/src/modules/standards/interface
        :poo-flow/lambda-episteme/modules/healthcare/standards/interface)

(export standards-healthcare-migration-test)

(def migration-terminology-snapshot
  (poo-flow-standard-digest 'au-legacy-migration-test-terminology))

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

(def (migration-case-with ai-role review-decision)
  (let* ((base-proposal (.ref AULegacyHL7v2PatientMigrationCase 'proposal))
         (proposal
          (healthcare-standard-migration-proposal
           (.ref base-proposal 'identity)
           (.ref base-proposal 'source-interface)
           (.ref base-proposal 'target-profile)
           (.ref base-proposal 'candidate-digest)
           (.ref base-proposal 'mapping-evidence-digest)
           (.ref base-proposal 'proposed-by)
           ai-role))
         (review
          (healthcare-standard-migration-review
           proposal "human-reviewer/test" review-decision
           (poo-flow-standard-digest
            (list 'test-review-evidence review-decision)))))
    (healthcare-standard-migration-case
     (.ref AULegacyHL7v2PatientMigrationCase 'identity)
     (.ref AULegacyHL7v2PatientMigrationCase 'jurisdiction)
     (.ref AULegacyHL7v2PatientMigrationCase 'source-interface)
     (.ref AULegacyHL7v2PatientMigrationCase 'source-version)
     (.ref AULegacyHL7v2PatientMigrationCase 'source-snapshot-digest)
     (.ref AULegacyHL7v2PatientMigrationCase 'parser-receipt-digest)
     proposal review)))

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
         (.ref AULegacyHealthcareInterfaceLandscape 'target-profile)
         "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")))
    (test-case "fixture binds advisory proposal and independent human review"
      (check-equal? (.ref AULegacyHealthcareInterfaceLandscape 'ai-role)
                    'advisory-only)
      (check-equal? (.ref AULegacyHealthcareInterfaceLandscape
                          'authorization-owner)
                    'human-reviewer)
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
    (test-case "reviewed AI proposal is admitted only after AU Core conformance"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let (receipt
               (healthcare-standard-migration-admit
                AULegacyHL7v2PatientMigrationCase closure conformance))
           (check-equal? (.ref conformance 'valid?) #t)
           (check-equal? (.ref receipt 'valid?) #t)
           (check-equal? (length (.ref receipt 'evidence-digests)) 6)
           (check-equal? (.ref receipt 'failures) '())))))
    (test-case "AI authority or rejected human review fails closed"
      (call-with-values
       (lambda ()
         (migration-validation AULegacyHL7v2PatientFHIRCandidate))
       (lambda (closure conformance)
         (let* ((receipt
                 (healthcare-standard-migration-admit
                  (migration-case-with 'automated-decision 'rejected)
                  closure conformance))
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
