;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda owns this bounded Healthcare validator.  It does not claim
;;; FHIRPath, slicing, remote reference or terminology-expansion support.
(import (only-in :clan/poo/object .ref)
        (only-in :clan/poo/mop .defmethod-bundle)
        :std/list/list
        :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/src/modules/standards/objects
                 poo-flow-standard-conformance-receipt
                 poo-flow-standard-failure)
        (only-in :poo-flow/src/modules/standards/funs
                 poo-flow-standard-digest)
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-validation-closure?)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/objects
                 HealthcareStandardValidationProtocol
                 HealthcareStandardValidationGeneric)
        "types.ss"
        "objects.ss")

(export poo-flow-fhir-validate-subject
        FHIRMedicationRequestValidationMethod
        FHIRAUCorePatientValidationMethod
        FHIRStandardValidationMethods)

(def (fhir-key-entry object key)
  (and (list? object)
       (or (assoc key object)
           (and (symbol? key) (assoc (symbol->string key) object))
           (and (string? key) (assoc (string->symbol key) object)))))

(def (fhir-path-ref subject path)
  (let loop ((value subject) (rest path))
    (if (null? rest)
      (values #t value)
      (let (entry (fhir-key-entry value (car rest)))
        (if entry
          (loop (cdr entry) (cdr rest))
          (values #f #f))))))

(def (fhir-reference-target? value expected)
  (and (string? value)
       (string? expected)
       (> (string-length value) (string-length expected))
       (string=? (substring value 0 (string-length expected)) expected)
       (char=? (string-ref value (string-length expected)) #\/)))

(def (fhir-truth value)
  (if value #t #f))

(def (fhir-xor left right)
  (not (eq? (fhir-truth left) (fhir-truth right))))

(def (fhir-collection-at subject path)
  (let-values (((present? value) (fhir-path-ref subject path)))
    (if (and present? (list? value)) value '())))

(def (fhir-extension-url-present? object expected-url)
  (let (entry (fhir-key-entry object 'extension))
    (and entry
         (list? (cdr entry))
         (any
          (lambda (extension)
            (let (url-entry (fhir-key-entry extension 'url))
              (and url-entry (equal? (cdr url-entry) expected-url))))
          (cdr entry)))))

(def (fhir-entry-has-all-fields? object fields)
  (every (lambda (field) (fhir-key-entry object field)) fields))

(def (fhir-entry-has-any-field? object fields)
  (any (lambda (field) (fhir-key-entry object field)) fields))

(def (fhir-choice-present-count subject path fields)
  (let-values (((present? parent) (fhir-path-ref subject path)))
    (if present?
      (length
       (filter (lambda (field) (fhir-key-entry parent field)) fields))
      0)))

(def (fhir-au-core-patient-collection-xor-dar?
      subject path content-predicate dar-url)
  (let* ((items (fhir-collection-at subject path))
         (content? (any content-predicate items))
         (dar?
          (any
           (lambda (item) (fhir-extension-url-present? item dar-url))
           items)))
    (fhir-xor content? dar?)))

(def (fhir-au-core-patient-every-name-content-xor-dar?
      subject path dar-url)
  (let (names (fhir-collection-at subject path))
    (and
     (pair? names)
     (every
      (lambda (name)
        (fhir-xor
         (fhir-entry-has-any-field? name '(text family given))
         (fhir-extension-url-present? name dar-url)))
      names))))

(def (fhir-constraint-result constraint subject)
  (let ((kind (.ref constraint 'constraint-kind))
        (path (.ref constraint 'path))
        (expected (.ref constraint 'expected)))
    (if (eq? (.ref constraint 'support-state) 'unsupported)
      (values 'unsupported #f)
      (case kind
        ((resource-type fixed-value)
         (let-values (((present? actual) (fhir-path-ref subject path)))
           (values 'evaluated (and present? (equal? actual expected)))))
        ((required-field)
         (let-values (((present? actual) (fhir-path-ref subject path)))
           (values 'evaluated present?)))
        ((choice-field)
         (let (present-count (fhir-choice-present-count subject path expected))
           (values 'evaluated (= present-count 1))))
        ((reference-target)
         (let-values (((present? actual) (fhir-path-ref subject path)))
           (values 'evaluated
                   (and present? (fhir-reference-target? actual expected)))))
        ((au-core-patient-identifier-xor-data-absent-reason)
         (values
          'evaluated
          (fhir-au-core-patient-collection-xor-dar?
           subject path
           (lambda (identifier)
             (fhir-entry-has-all-fields? identifier '(system value)))
           expected)))
        ((au-core-patient-family-xor-data-absent-reason)
         (values
          'evaluated
          (fhir-au-core-patient-collection-xor-dar?
           subject path
           (lambda (name) (fhir-key-entry name 'family))
           expected)))
        ((au-core-patient-name-content-xor-data-absent-reason)
         (values
          'evaluated
          (fhir-au-core-patient-every-name-content-xor-dar?
           subject path expected)))
        (else (values 'unsupported #f))))))

(def (poo-flow-fhir-validate-subject provider-identity validation-closure subject)
  (unless (poo-flow-standard-validation-closure? validation-closure)
    (error "invalid FHIR validation closure" validation-closure))
  (let ((evaluated-rev '())
        (unsupported-rev '())
        (failures-rev '()))
    (for-each
     (lambda (constraint)
       (unless (poo-flow-fhir-constraint? constraint)
         (error "invalid FHIR constraint" constraint))
       (let (identity (.ref constraint 'identity))
         (let-values (((state passed?)
                       (fhir-constraint-result constraint subject)))
           (if (eq? state 'unsupported)
             (begin
               (set! unsupported-rev (cons identity unsupported-rev))
               (set! failures-rev
                     (cons
                      (poo-flow-standard-failure
                       'standard-constraint-unsupported identity
                       (.ref constraint 'constraint-kind)
                       (.ref constraint 'path))
                      failures-rev)))
             (begin
               (set! evaluated-rev (cons identity evaluated-rev))
               (unless passed?
                 (set! failures-rev
                       (cons
                        (poo-flow-standard-failure
                         'standard-validation-failed identity
                         (list (cons 'constraint-kind
                                     (.ref constraint 'constraint-kind))
                               (cons 'expected (.ref constraint 'expected)))
                         (.ref constraint 'path))
                        failures-rev))))))))
     (.ref validation-closure 'constraints))
    (let* ((evaluated (reverse evaluated-rev))
           (unsupported (reverse unsupported-rev))
           (failures (reverse failures-rev))
           (digest
            (poo-flow-standard-digest
             (list 'poo-flow.fhir-conformance.v1
                   provider-identity
                   (.ref validation-closure 'validation-closure-digest)
                   (.ref validation-closure 'subject-snapshot-digest)
                   evaluated unsupported
                   (map (lambda (failure) (.ref failure 'code)) failures)))))
      (poo-flow-standard-conformance-receipt
       (null? failures) provider-identity (.ref validation-closure 'validation-closure-digest)
       (.ref validation-closure 'subject-snapshot-digest) evaluated unsupported failures
       digest))))

(def FHIRMedicationRequestValidationMethod
  (poo-clos-method
   'healthcare/fhir-medication-request-validation
   (list (poo-clos-class-specializer FHIRStandardValidationExecutor)
         (poo-clos-eql-specializer FHIRMedicationRequestStandardProfile)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _executor profile validation-closure subject)
     (poo-flow-fhir-validate-subject
      (.ref profile 'provider-identity) validation-closure subject))))

(def FHIRAUCorePatientValidationMethod
  (poo-clos-method
   'healthcare/fhir-au-core-patient-validation
   (list (poo-clos-class-specializer FHIRStandardValidationExecutor)
         (poo-clos-eql-specializer FHIRAUCorePatientStandardProfile)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _executor profile validation-closure subject)
     (poo-flow-fhir-validate-subject
      (.ref profile 'provider-identity) validation-closure subject))))

(.defmethod-bundle FHIRStandardValidationMethods
  HealthcareStandardValidationProtocol
  FHIRMedicationRequestValidationMethod
  FHIRAUCorePatientValidationMethod)

(poo-clos-compose-method-bundle
 HealthcareStandardValidationGeneric
 FHIRStandardValidationMethods)
