;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :std/error Error?)
        :std/list/list
        (only-in :clan/poo/object .o .ref .slot?)
        (only-in :poo-flow/src/feature-system/source-lock-feature
                 require-source-lock-payload)
        :poo-flow/src/modules/standards/interface
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/fhir/reference
                 poo-flow-fhir-reference-observation-from-bundle)
        :poo-flow/lambda-episteme/modules/healthcare/interface)

(export standards-fhir-test)

(def terminology-snapshot
  (poo-flow-standard-digest 'fhir-au-test-terminology-snapshot))

(def reference-validator-binary-digest
  "sha256:0e53ab1d1a6f1e35f505255c0b8ce10a35fcf27e6e96b503640f784cd07e5ad6")

(def au-core-patient-reference-output
  "packages/lambda-episteme/t/healthcare/standards/fixtures/au-core-patient-validator-6.9.12-operation-outcomes.json")

(def (make-validation-closure constraints subject)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution)))
    (poo-flow-standard-make-validation-closure
     (.ref FHIRMedicationRequestStandardProfile 'identity)
     bundle +poo-flow-fhir-provider-identity+
     'fhir-json (poo-flow-standard-digest subject) constraints)))

(def (make-patient-validation-closure constraints subject)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution)))
    (poo-flow-standard-make-validation-closure
     (.ref FHIRAUCorePatientStandardProfile 'identity)
     bundle +poo-flow-fhir-provider-identity+
     'fhir-json (poo-flow-standard-digest subject) constraints)))

(def (materialized-medication-request-constraints)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution))
         (context
          (poo-flow-standard-materialization-context
           "test/fhir/materialization" (.ref bundle 'artifacts)))
         (receipt
          (poo-flow-standard-materialize
           context +poo-flow-fhir-medication-request-artifact-identity+)))
    (poo-flow-fhir-medication-request-constraints
     (poo-flow-standard-materialization-receipt-artifact receipt))))

(def (materialized-au-core-patient-constraints)
  (let* ((resolution
          (poo-flow-standard-resolve
           FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
           poo-flow-standard-default-budget terminology-snapshot))
         (bundle (poo-flow-standard-resolution-receipt-bundle resolution))
         (context
          (poo-flow-standard-materialization-context
           "test/fhir/patient-materialization" (.ref bundle 'artifacts)))
         (receipt
          (poo-flow-standard-materialize
           context +poo-flow-fhir-au-core-patient-artifact-identity+)))
    (poo-flow-fhir-au-core-patient-constraints
     (poo-flow-standard-materialization-receipt-artifact receipt))))

(def valid-medication-request
  '((resourceType . "MedicationRequest")
    (status . "active")
    (intent . "order")
    (medicationCodeableConcept . ((text . "amoxicillin")))
    (subject . ((reference . "Patient/example")))))

(def valid-general-medication-request
  '((resourceType . "MedicationRequest")
    (status . "draft")
    (intent . "proposal")
    (medicationReference . ((reference . "Medication/example")))
    (subject . ((reference . "Group/example")))))

(def valid-au-core-patient
  '((resourceType . "Patient")
    (meta . ((profile . ("http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"))))
    (gender . "female")
    (birthDate . "1990-01-01")
    (identifier . (((system . "http://example.test/mrn")
                    (value . "12345"))))
    (name . (((family . "Ng")
              (given . ("Alice")))))))

(def data-absent-au-core-patient
  '((resourceType . "Patient")
    (meta . ((profile . ("http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"))))
    (gender . "female")
    (birthDate . "1990-01-01")
    (identifier
     . (((extension
          . (((url . "http://hl7.org/fhir/StructureDefinition/data-absent-reason")
              (valueCode . "unknown")))))))
    (name
     . (((extension
          . (((url . "http://hl7.org/fhir/StructureDefinition/data-absent-reason")
              (valueCode . "unknown")))))))))

(def invalid-au-core-patient
  '((resourceType . "Patient")
    (meta . ((profile . ("http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"))))
    (gender . "female")
    (birthDate . "1990-01-01")
    (identifier . (((system . "http://example.test/mrn"))))
    (name . (((given . ("Alice")))
             ((extension
               . (((url . "http://example.test/not-data-absent-reason")))))))))

(def conflicting-au-core-patient
  '((resourceType . "Patient")
    (meta . ((profile . ("http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"))))
    (gender . "female")
    (birthDate . "1990-01-01")
    (identifier
     . (((system . "http://example.test/mrn")
         (value . "12345")
         (extension
          . (((url . "http://hl7.org/fhir/StructureDefinition/data-absent-reason")
              (valueCode . "unknown")))))))
    (name
     . (((family . "Ng")
         (extension
          . (((url . "http://hl7.org/fhir/StructureDefinition/data-absent-reason")
              (valueCode . "unknown")))))))))

(def (reference-observation fixture subject outcome issues)
  (poo-flow-standard-make-reference-observation
   "hl7.fhir.validator-cli" "6.9.12" reference-validator-binary-digest
   fixture (poo-flow-standard-digest subject)
   '("hl7.fhir.au.core@1.0.0") outcome issues
   (poo-flow-standard-digest (list fixture outcome issues))
   '((qualification . synthetic-contract-test))))

(def standards-fhir-test
  (test-suite "Lambda Healthcare FHIR Standard Provider"
    (test-case "capabilities separate bounded, reference, and unevaluated claims"
      (check-equal?
       (.ref (.ref FHIRValidationCapabilities 'bounded-structure) 'state)
       'native-bounded)
      (check-equal?
       (.ref (.ref FHIRValidationCapabilities 'au-core-patient-reference)
             'state)
       'reference-qualified)
      (let (syntax-capability
            (.ref FHIRValidationCapabilities 'fhirpath-syntax))
        (check-equal? (poo-flow-fhir-capability? syntax-capability) #t)
        (check-equal? (.ref syntax-capability 'state) 'syntax-qualified)
        (check-equal? (.ref syntax-capability 'owner) "gerbil-parser")
        (check-equal? (length (.ref syntax-capability 'evidence-digests)) 2))
      (for-each
       (lambda (capability)
         (check-equal? (poo-flow-fhir-capability? capability) #t)
         (check-equal? (.ref capability 'state) 'not-evaluated))
       (list (.ref FHIRValidationCapabilities 'general-fhirpath)
             (.ref FHIRValidationCapabilities 'slicing)
             (.ref FHIRValidationCapabilities 'terminology)
             (.ref FHIRValidationCapabilities 'remote-reference-resolution))))
    (test-case "Healthcare composes the core Standards module as its public root"
      (let (standards (.ref HealthcareModule 'standards))
        (check-equal? (lambda-healthcare-module? HealthcareModule) #t)
        (check-equal? (poo-flow-standards-module? standards) #t)
        (check-equal? (.ref standards 'industry) 'healthcare)
        (check-equal? (.ref (.ref standards 'providers) 'fhir)
                      FHIRValidationProvider)
        (check-equal? (.ref (.ref standards 'profiles) 'medication-request)
                      FHIRMedicationRequestStandardProfile)
        (check-equal? (.ref (.ref standards 'profiles) 'au-core-patient)
                      FHIRAUCorePatientStandardProfile)
        (check-equal?
         (poo-flow-fhir-validation-profile
          "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")
         FHIRAUCorePatientStandardProfile)))
    (test-case "AU Core resolution is exact, transitive, and lazy"
      (let* ((receipt
             (poo-flow-standard-resolve
               FHIRStandardsCatalog '("hl7.fhir.au.core@1.0.0")
               poo-flow-standard-default-budget terminology-snapshot))
             (bundle (poo-flow-standard-resolution-receipt-bundle receipt))
             (context
              (poo-flow-standard-materialization-context
               "test/fhir/lazy-closure" (.ref bundle 'artifacts))))
        (check-equal? (poo-flow-standard-resolution-receipt-valid? receipt) #t)
        (check-equal? (.ref bundle 'edition-count) 3)
        (check-equal? (.ref bundle 'artifact-count) 4)
        (check-equal? (.ref (poo-flow-standard-catalog-observe FHIRStandardsCatalog)
                            'realized-artifact-count)
                      0)
        (check-equal? (.ref (poo-flow-standard-materialization-stats context)
                            'load-count)
                      0)
        (check-equal? (.ref (poo-flow-standard-materialization-stats context)
                            'materialization-count)
                      0)
        (check-equal?
         (.ref (poo-flow-standard-materialize
                context "hl7.fhir.au.core@1.0.0/package")
               'valid?)
         #t)
        (let* ((patient-receipt
                (poo-flow-standard-materialize
                 context +poo-flow-fhir-au-core-patient-artifact-identity+))
               (patient-artifact
                (poo-flow-standard-materialization-receipt-artifact
                 patient-receipt))
               (patient-payload (.ref patient-artifact 'payload)))
          (check-equal?
           (pair? (assoc 'structure-definition-identity patient-payload)) #t)
          (check-equal? (assoc 'structure-definition patient-payload) #f))
        (check-equal? (.ref (poo-flow-standard-materialization-stats context)
                            'load-count)
                      4)
        (check-equal? (.ref (poo-flow-standard-materialization-stats context)
                            'source-load-count)
                      4)
        (check-equal? (.ref (poo-flow-standard-materialization-stats context)
                            'materialization-count)
                      4)))
    (test-case "official AU Core Patient JSON is fixed and parsed only on demand"
      (call-with-values
       (lambda ()
         (poo-flow-fhir-load-fixed-source
          +poo-flow-fhir-au-core-patient-source-identity+))
       (lambda (entry receipt source)
         (let* ((decoded
                 (poo-flow-fhir-parse-json-structure-definition source))
                (constraints (poo-flow-fhir-json-constraints decoded)))
           (check-equal? (u8vector? source) #t)
           (check-equal? (.ref receipt 'valid?) #t)
           (check-equal? (.ref receipt 'source-identity)
                         +poo-flow-fhir-au-core-patient-source-identity+)
           (check-equal? (u8vector-length source) (.ref entry 'size-bytes))
           (check-equal?
            (poo-flow-fhir-json-ref decoded "resourceType")
            "StructureDefinition")
           (check-equal?
            (poo-flow-fhir-json-ref decoded "id") "au-core-patient")
           (check-equal?
            (poo-flow-fhir-json-ref decoded "url")
            "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")
           (check-equal?
            (poo-flow-fhir-json-ref decoded "version") "1.0.0")
           (check-equal?
            (map (lambda (constraint)
                   (poo-flow-fhir-json-ref constraint "key"))
                 (filter
                  (lambda (constraint)
                    (member (poo-flow-fhir-json-ref constraint "key")
                            '("au-core-pat-01"
                              "au-core-pat-02"
                              "au-core-pat-03")))
                  constraints))
            '("au-core-pat-01" "au-core-pat-02" "au-core-pat-03"))))))
    (test-case "FHIR source lock rejects absent and changed source identities"
      (check-exception
       (poo-flow-fhir-source-lock-entry "hl7.fhir.au.core@9/source/missing")
       Error?)
      (let (tampered (string->utf8 "{}"))
        (check-exception
         (require-source-lock-payload
          FHIRSourcesLock
         +poo-flow-fhir-au-core-patient-source-identity+
         tampered)
         Error?)))
    (test-case "all selected FHIR and AU package JSON sources are locked"
      (let (identities
            (list +poo-flow-fhir-r4-package-source-identity+
                  +poo-flow-fhir-medication-request-source-identity+
                  +poo-flow-fhir-au-base-package-source-identity+
                  +poo-flow-fhir-au-base-ig-source-identity+
                  +poo-flow-fhir-au-core-package-source-identity+
                  +poo-flow-fhir-au-core-ig-source-identity+
                  +poo-flow-fhir-au-core-patient-source-identity+))
        (check-equal? (.ref FHIRSourcesLock 'entry-count) 7)
        (check-equal? (.ref FHIRSourcesLock 'byte-count) 610534)
        (for-each
         (lambda (identity)
           (call-with-values
            (lambda () (poo-flow-fhir-load-fixed-source identity))
            (lambda (_entry receipt source)
              (check-equal? (.ref receipt 'valid?) #t)
              (check-equal? (u8vector? source) #t))))
         identities)))
    (test-case "source-bound MedicationRequest constraints preserve base FHIR semantics"
      (let* ((validation-closure (make-validation-closure (materialized-medication-request-constraints)
                              valid-medication-request))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure valid-medication-request)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #t)
        (check-equal? (length (.ref receipt 'evaluated-constraints)) 5)
        (check-equal? (.ref receipt 'unsupported-constraints) '())
        (let* ((constraints (materialized-medication-request-constraints))
               (general-closure
                (make-validation-closure
                 constraints valid-general-medication-request))
               (general-receipt
                (poo-flow-standard-validate
                 FHIRValidationProvider general-closure
                 valid-general-medication-request)))
          (check-equal?
           (map (lambda (constraint)
                  (and (.slot? constraint 'source-element-id)
                       (.ref constraint 'source-element-id)))
                (cdr constraints))
           '("MedicationRequest.status"
             "MedicationRequest.intent"
             "MedicationRequest.medication[x]"
             "MedicationRequest.subject"))
          (check-equal?
           (poo-flow-standard-conformance-receipt-valid? general-receipt) #t))))
    (test-case "AU Core Patient dispatch validates published bounded invariants"
      (let* ((constraints (materialized-au-core-patient-constraints))
             (validation-closure
              (make-patient-validation-closure constraints valid-au-core-patient))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure valid-au-core-patient)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #t)
        (check-equal? (length (.ref receipt 'evaluated-constraints)) 4)
        (check-equal? (.ref receipt 'unsupported-constraints) '())
        (check-equal?
         (.ref (cadr constraints) 'source-severity) "error")))
    (test-case "AU Core Patient accepts the Data Absent Reason alternative"
      (let* ((constraints (materialized-au-core-patient-constraints))
             (validation-closure
              (make-patient-validation-closure
               constraints data-absent-au-core-patient))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure
               data-absent-au-core-patient)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #t)
        (check-equal? (length (.ref receipt 'evaluated-constraints)) 4)))
    (test-case "AU Core Patient rejects incomplete identifiers and names"
      (let* ((constraints (materialized-au-core-patient-constraints))
             (validation-closure
              (make-patient-validation-closure constraints invalid-au-core-patient))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure invalid-au-core-patient)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #f)
        (check-equal? (.ref (car (.ref receipt 'failures)) 'code)
                      'standard-validation-failed)))
    (test-case "AU Core Patient XOR invariants reject content plus Data Absent Reason"
      (let* ((constraints (materialized-au-core-patient-constraints))
             (validation-closure
              (make-patient-validation-closure
               constraints conflicting-au-core-patient))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure
               conflicting-au-core-patient)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #f)
        (check-equal? (.ref (car (.ref receipt 'failures)) 'code)
                      'standard-validation-failed)))
    (test-case "multi-dispatch fails closed for an unsupported Standard Profile"
      (let* ((validation-closure (make-validation-closure (materialized-medication-request-constraints)
                              valid-medication-request))
             (unknown-profile
              (.o identity: "example/UnknownFHIRProfile"
                  provider-identity: +poo-flow-fhir-provider-identity+)))
        (check-exception
         (healthcare-standard-validate
          FHIRValidationExecutor unknown-profile validation-closure valid-medication-request)
         Error?)
        (check-exception
         (poo-flow-fhir-validation-profile (.ref unknown-profile 'identity))
         Error?)))
    (test-case "structural failures preserve the first typed cause"
      (let* ((subject
              '((resourceType . "Observation")
                (status . "active")
                (intent . "proposal")
                (subject . ((reference . "Practitioner/example")))))
             (validation-closure
              (make-validation-closure (materialized-medication-request-constraints) subject))
             (receipt
              (poo-flow-standard-validate FHIRValidationProvider validation-closure subject)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #f)
        (check-equal? (.ref (car (.ref receipt 'failures)) 'code)
                      'standard-validation-failed)))
    (test-case "nested choice fields resolve their parent path once"
      (let* ((constraint
              (poo-flow-fhir-constraint
               "fhir/test/nested-choice" 'choice-field '(payload)
               '(valueString valueReference) 'supported))
             (valid-subject
              '((payload . ((valueReference . ((reference . "Patient/1")))))))
             (conflicting-subject
              '((payload . ((valueString . "Alice")
                            (valueReference . ((reference . "Patient/1")))))))
             (valid-receipt
              (poo-flow-standard-validate
               FHIRValidationProvider
               (make-validation-closure (list constraint) valid-subject)
               valid-subject))
             (conflicting-receipt
              (poo-flow-standard-validate
               FHIRValidationProvider
               (make-validation-closure (list constraint) conflicting-subject)
               conflicting-subject)))
        (check-equal?
         (poo-flow-standard-conformance-receipt-valid? valid-receipt) #t)
        (check-equal?
         (poo-flow-standard-conformance-receipt-valid? conflicting-receipt) #f)))
    (test-case "unsupported constraints fail closed"
      (let* ((unsupported
              (poo-flow-fhir-constraint
               "fhir/r4/MedicationRequest/invariant/fhirpath"
               'fhirpath-invariant '() "medication.exists()" 'unsupported))
             (validation-closure (make-validation-closure (list unsupported) valid-medication-request))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure valid-medication-request)))
        (check-equal? (poo-flow-standard-conformance-receipt-valid? receipt) #f)
        (check-equal? (.ref receipt 'unsupported-constraints)
                      '("fhir/r4/MedicationRequest/invariant/fhirpath"))
        (check-equal? (.ref (car (.ref receipt 'failures)) 'code)
                      'standard-constraint-unsupported)))
    (test-case "reference-validator observations agree on positive and negative fixtures"
      (let* ((constraints (materialized-medication-request-constraints))
             (positive-validation-closure (make-validation-closure constraints valid-medication-request))
             (positive-receipt
              (poo-flow-standard-validate
               FHIRValidationProvider positive-validation-closure valid-medication-request))
             (positive-comparison
              (poo-flow-standard-compare-reference-observation
               positive-validation-closure positive-receipt
               (reference-observation
                "fhir/MedicationRequest/valid" valid-medication-request
                'valid '())))
             (invalid-medication-request
              '((resourceType . "Observation")
                (status . "active")
                (intent . "proposal")
                (subject . ((reference . "Practitioner/example")))))
             (negative-validation-closure (make-validation-closure constraints invalid-medication-request))
             (negative-receipt
              (poo-flow-standard-validate
               FHIRValidationProvider negative-validation-closure invalid-medication-request))
             (negative-comparison
              (poo-flow-standard-compare-reference-observation
               negative-validation-closure negative-receipt
               (reference-observation
                "fhir/MedicationRequest/invalid" invalid-medication-request
                'invalid '("reference-validation-error")))))
        (check-equal?
         (poo-flow-standard-comparison-receipt? positive-comparison) #t)
        (check-equal?
         (poo-flow-standard-comparison-receipt-valid? positive-comparison) #t)
        (check-equal? (.ref positive-comparison 'agreement?) #t)
        (check-equal?
         (poo-flow-standard-comparison-receipt-valid? negative-comparison) #t)
        (check-equal? (.ref negative-comparison 'agreement?) #t)))
    (test-case "pinned HL7 Validator agrees on all AU Core Patient fixtures"
      (let (constraints (materialized-au-core-patient-constraints))
        (for-each
         (lambda (fixture)
           (let* ((fixture-identity (car fixture))
                  (subject (cadr fixture))
                  (entry-index (caddr fixture))
                  (expected-outcome (cadddr fixture))
                  (validation-closure
                   (make-patient-validation-closure constraints subject))
                  (conformance
                   (poo-flow-standard-validate
                    FHIRValidationProvider validation-closure subject))
                  (reference
                   (poo-flow-fhir-reference-observation-from-bundle
                    "6.9.12" reference-validator-binary-digest
                    fixture-identity subject
                    '("hl7.fhir.au.core@1.0.0")
                    au-core-patient-reference-output entry-index))
                  (comparison
                   (poo-flow-standard-compare-reference-observation
                    validation-closure conformance reference)))
             (check-equal? (.ref reference 'outcome) expected-outcome)
             (check-equal?
              (poo-flow-standard-comparison-receipt-valid? comparison) #t)
             (check-equal? (.ref comparison 'agreement?) #t)))
         (list
          (list "fhir/AUCorePatient/valid" valid-au-core-patient 0 'valid)
          (list "fhir/AUCorePatient/data-absent"
                data-absent-au-core-patient 1 'valid)
          (list "fhir/AUCorePatient/invalid"
                invalid-au-core-patient 2 'invalid)
          (list "fhir/AUCorePatient/xor-conflict"
                conflicting-au-core-patient 3 'invalid)))))
    (test-case "reference-validator mismatch and non-evaluation fail closed"
      (let* ((constraints (materialized-medication-request-constraints))
             (validation-closure (make-validation-closure constraints valid-medication-request))
             (receipt
              (poo-flow-standard-validate
               FHIRValidationProvider validation-closure valid-medication-request))
             (disagreement
              (poo-flow-standard-compare-reference-observation
               validation-closure receipt
               (reference-observation
                "fhir/MedicationRequest/disagreement" valid-medication-request
                'invalid '("synthetic-disagreement"))))
             (not-evaluated
              (poo-flow-standard-compare-reference-observation
               validation-closure receipt
               (reference-observation
                "fhir/MedicationRequest/not-evaluated" valid-medication-request
                'not-evaluated '("reference-validator-unavailable")))))
        (check-equal? (.ref disagreement 'valid?) #f)
        (check-equal? (.ref (car (.ref disagreement 'failures)) 'code)
                      'standard-reference-validator-disagreement)
        (check-equal? (.ref not-evaluated 'valid?) #f)
        (check-equal? (.ref (car (.ref not-evaluated 'failures)) 'code)
                      'standard-reference-validator-not-evaluated)))
    (test-case "FHIR adapter imports OperationOutcome evidence without execution"
      (let ((positive
             (poo-flow-fhir-reference-observation-from-operation-outcome
              "6.9.12" reference-validator-binary-digest
              "fhir/MedicationRequest/valid" valid-medication-request
              '("hl7.fhir.au.core@1.0.0")
              "packages/lambda-episteme/t/healthcare/standards/fixtures/reference-valid-operation-outcome.json"))
            (negative
             (poo-flow-fhir-reference-observation-from-operation-outcome
              "6.9.12" reference-validator-binary-digest
              "fhir/MedicationRequest/invalid" valid-medication-request
              '("hl7.fhir.au.core@1.0.0")
              "packages/lambda-episteme/t/healthcare/standards/fixtures/reference-invalid-operation-outcome.json")))
        (check-equal? (poo-flow-standard-reference-observation? positive) #t)
        (check-equal? (.ref positive 'outcome) 'valid)
        (check-equal? (.ref negative 'outcome) 'invalid)
        (check-equal? (.ref negative 'issues) '("error:invalid"))))))
