;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare owns these exact bounded pack identities; these
;;; are not claims that the complete upstream implementation guides are copied.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/srfi/1 filter-map find)
        (only-in :poo-flow/src/modules/standards/types
                 +poo-flow-standard-validation-provider-kind+
                 poo-flow-standard-artifact?)
        (only-in :poo-flow/src/modules/standards/objects
                 poo-flow-standard-artifact
                 poo-flow-standard-artifact-ref
                 poo-flow-standard-artifact-source
                 poo-flow-standard-catalog
                 poo-flow-standard-edition-ref
                 poo-flow-standard-family)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/objects
                 healthcare-standard-validate)
        "objects.ss"
        "sources.ss"
        "source.ss"
        "funs.ss")

(export +poo-flow-fhir-provider-identity+
        +poo-flow-fhir-medication-request-artifact-identity+
        +poo-flow-fhir-au-core-patient-artifact-identity+
        FHIRStandardFamily
        FHIRR4StandardRef
        AUBaseStandardRef
        AUCoreStandardRef
        FHIRStandardsCatalog
        FHIRValidationProfiles
        FHIRValidationCapabilities
        FHIRValidationProvider
        poo-flow-fhir-validation-profile
        poo-flow-fhir-medication-request-constraints
        poo-flow-fhir-au-core-patient-constraints)

(def +poo-flow-fhir-provider-identity+
  "lambda-episteme/healthcare/standards/provider/fhir/v1")
(def +poo-flow-fhir-medication-request-artifact-identity+
  "hl7.fhir.r4.core@4.0.1/MedicationRequest")
(def +poo-flow-fhir-au-core-patient-artifact-identity+
  "hl7.fhir.au.core@1.0.0/StructureDefinition/au-core-patient")

;;; A bounded Provider and one reference fixture must not be projected as
;;; blanket support for the whole FHIR conformance surface.
(def FHIRValidationCapabilities
  (.o bounded-structure:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/bounded-structure/v1"
       'bounded-structure 'native-bounded "lambda-healthcare" '()
       "named structural constraints admitted by the selected closure")
      au-core-patient-reference:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/au-core-patient-reference/v1"
       'au-core-patient-reference 'reference-qualified
       "hl7.fhir.validator-cli"
       '("sha256:0e53ab1d1a6f1e35f505255c0b8ce10a35fcf27e6e96b503640f784cd07e5ad6"
         "sha256:a152b8d0656bbf8d61559dae318922550471db4f6026a6884b460eca0cc1337c")
       "four AU Core Patient fixtures replayed by Validator 6.9.12")
      fhirpath-syntax:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/fhirpath-syntax/v1"
       'fhirpath-syntax 'syntax-qualified "gerbil-parser"
       '("sha256:cf2a7cf29475e29b1a9188fcabea77782db59c9309b200059b3ef3f781eaae13"
         "sha256:0ea46f50855a85b6721fc425ecb5b4ba977b3f1cf3a68eb507b0e07c51d4d5ed")
       "FHIRPath 2.0.0 normative syntax; no evaluation semantics")
      general-fhirpath:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/general-fhirpath/v1"
       'general-fhirpath 'not-evaluated "gerbil-parser" '()
       "syntax is qualified separately; no general evaluator is admitted")
      slicing:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/slicing/v1"
       'slicing 'not-evaluated "lambda-healthcare" '()
       "no complete slicing acceptance suite is admitted")
      terminology:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/terminology/v1"
       'terminology 'not-evaluated "lambda-healthcare" '()
       "the reference run uses tx n/a and makes no terminology claim")
      remote-reference-resolution:
      (poo-flow-fhir-capability
       "lambda-episteme/fhir/capability/remote-reference-resolution/v1"
       'remote-reference-resolution 'not-evaluated "lambda-healthcare" '()
       "remote reference resolution is outside the bounded Provider")))

(def fhir-r4-package-source-entry
  (poo-flow-fhir-source-lock-entry
   +poo-flow-fhir-r4-package-source-identity+))
(def fhir-medication-request-source-entry
  (poo-flow-fhir-source-lock-entry
   +poo-flow-fhir-medication-request-source-identity+))
(def au-base-package-source-entry
  (poo-flow-fhir-source-lock-entry
   +poo-flow-fhir-au-base-package-source-identity+))
(def au-core-package-source-entry
  (poo-flow-fhir-source-lock-entry
   +poo-flow-fhir-au-core-package-source-identity+))
(def au-core-patient-source-entry
  (poo-flow-fhir-source-lock-entry
   +poo-flow-fhir-au-core-patient-source-identity+))

(def FHIRStandardFamily
  (poo-flow-standard-family
   "http://hl7.org/fhir" "HL7 International" 'healthcare-interoperability
   '(json xml) "CC0-1.0"
   '((canonical-uri . "http://hl7.org/fhir"))))

(def (fhir-structure-element decoded identity)
  (or (find
       (lambda (element)
         (string=? (poo-flow-fhir-json-ref element "id" "") identity))
       (poo-flow-fhir-json-elements decoded "snapshot"))
      (error "fixed FHIR StructureDefinition element is absent" identity)))

(def (fhir-element-type-codes element)
  (map (lambda (type) (poo-flow-fhir-json-ref type "code" ""))
       (poo-flow-fhir-json-ref element "type" '())))

(def (require-fhir-element-shape decoded identity minimum maximum type-codes)
  (let (element (fhir-structure-element decoded identity))
    (unless
     (and (= (poo-flow-fhir-json-ref element "min" -1) minimum)
          (string=? (poo-flow-fhir-json-ref element "max" "") maximum)
          (equal? (fhir-element-type-codes element) type-codes))
      (error "fixed FHIR StructureDefinition element changed"
             identity element))
    element))

(def (source-bound-fhir-constraint identity kind path expected element)
  (.o (:: @ (poo-flow-fhir-constraint
              identity kind path expected 'supported))
      source-element-id: (poo-flow-fhir-json-ref element "id")
      source-min: (poo-flow-fhir-json-ref element "min")
      source-max: (poo-flow-fhir-json-ref element "max")
      source-types: (fhir-element-type-codes element)))

(def (materialize-fhir-medication-request-source source)
  (let* ((decoded (poo-flow-fhir-parse-json-medication-request source))
         (status
          (require-fhir-element-shape
           decoded "MedicationRequest.status" 1 "1" '("code")))
         (intent
          (require-fhir-element-shape
           decoded "MedicationRequest.intent" 1 "1" '("code")))
         (medication
          (require-fhir-element-shape
           decoded "MedicationRequest.medication[x]" 1 "1"
           '("CodeableConcept" "Reference")))
         (subject
          (require-fhir-element-shape
           decoded "MedicationRequest.subject" 1 "1" '("Reference"))))
    (list
     (cons 'structure-definition-identity
           (list (cons 'resource-type "StructureDefinition")
                 (cons 'id "MedicationRequest")
                 (cons 'canonical
                       "http://hl7.org/fhir/StructureDefinition/MedicationRequest")
                 (cons 'version "4.0.1")))
     (cons
      'constraints
      (list
       (poo-flow-fhir-constraint
        "fhir/r4/MedicationRequest/resourceType"
        'resource-type '(resourceType) "MedicationRequest" 'supported)
       (source-bound-fhir-constraint
        "fhir/r4/MedicationRequest/status" 'required-field '(status) #t status)
       (source-bound-fhir-constraint
        "fhir/r4/MedicationRequest/intent" 'required-field '(intent) #t intent)
       (source-bound-fhir-constraint
        "fhir/r4/MedicationRequest/medication[x]" 'choice-field '()
        '(medicationCodeableConcept medicationReference) medication)
       (source-bound-fhir-constraint
        "fhir/r4/MedicationRequest/subject" 'required-field '(subject) #t
        subject))))))

(def (materialize-fhir-package-manifest
      source expected-name expected-version expected-canonical)
  (let (decoded
        (poo-flow-fhir-parse-json-package-manifest
         source expected-name expected-version expected-canonical))
    (list (cons 'package (poo-flow-fhir-json-ref decoded "name"))
          (cons 'version (poo-flow-fhir-json-ref decoded "version"))
          (cons 'canonical (poo-flow-fhir-json-ref decoded "canonical"))
          (cons 'fhir-versions
                (poo-flow-fhir-json-ref decoded "fhirVersions"))
          (cons 'dependencies
                (poo-flow-fhir-json-ref decoded "dependencies" '())))))

(def (poo-flow-fhir-medication-request-constraints artifact)
  (unless (and (poo-flow-standard-artifact? artifact)
               (string=? (.ref artifact 'identity)
                         +poo-flow-fhir-medication-request-artifact-identity+))
    (error "invalid materialized FHIR MedicationRequest artifact" artifact))
  (let (entry (assoc 'constraints (.ref artifact 'payload)))
    (if entry
      (cdr entry)
      (error "materialized FHIR artifact has no constraints" artifact))))

(def (poo-flow-fhir-au-core-patient-constraints artifact)
  (unless (and (poo-flow-standard-artifact? artifact)
               (string=? (.ref artifact 'identity)
                         +poo-flow-fhir-au-core-patient-artifact-identity+))
    (error "invalid materialized AU Core Patient artifact" artifact))
  (let (entry (assoc 'constraints (.ref artifact 'payload)))
    (if entry
      (cdr entry)
      (error "materialized AU Core Patient artifact has no constraints" artifact))))

(def +poo-flow-fhir-data-absent-reason-url+
  "http://hl7.org/fhir/StructureDefinition/data-absent-reason")

(def au-core-patient-supported-constraint-index
  (let (index (make-hash-table))
    (hash-put!
     index "au-core-pat-01"
     (list 'au-core-patient-identifier-xor-data-absent-reason
           '(identifier)
           "(identifier.where(system.count() + value.count() >1)).exists() xor identifier.extension('http://hl7.org/fhir/StructureDefinition/data-absent-reason').exists()"))
    (hash-put!
     index "au-core-pat-02"
     (list 'au-core-patient-family-xor-data-absent-reason
           '(name)
           "name.family.exists() xor name.extension('http://hl7.org/fhir/StructureDefinition/data-absent-reason').exists()"))
    (hash-put!
     index "au-core-pat-03"
     (list 'au-core-patient-name-content-xor-data-absent-reason
           '(name)
           "(text.exists() or family.exists() or given.exists()) xor extension('http://hl7.org/fhir/StructureDefinition/data-absent-reason').exists()"))
    index))

(def (materialize-au-core-patient-constraint declaration)
  (let* ((key (poo-flow-fhir-json-ref declaration "key" ""))
         (spec (hash-get au-core-patient-supported-constraint-index key)))
    (and
     spec
     (let ((expression (poo-flow-fhir-json-ref declaration "expression" ""))
           (severity (poo-flow-fhir-json-ref declaration "severity" "")))
       (unless (and (string=? severity "error")
                    (string=? expression (caddr spec)))
         (error "fixed AU Core Patient constraint changed"
                key severity expression))
       (.o (:: @
               (poo-flow-fhir-constraint
                (string-append "fhir/au/core/1.0.0/Patient/" key)
                (car spec) (cadr spec)
                +poo-flow-fhir-data-absent-reason-url+ 'supported))
           source-expression: expression
           source-severity: severity)))))

(def (materialize-au-core-patient-source source)
  (let* ((decoded (poo-flow-fhir-parse-json-structure-definition source))
         (constraints
          (filter-map materialize-au-core-patient-constraint
                      (poo-flow-fhir-json-constraints decoded))))
    (unless (= (length constraints) 3)
      (error "fixed AU Core Patient constraint closure is incomplete"
             (map (lambda (constraint) (.ref constraint 'identity))
                  constraints)))
    ;; Keep only the admitted semantic identity in the materialized artifact.
    ;; The generated XHTML narrative in text.div is merely a JSON string; it is
    ;; neither parsed as markup nor retained in the runtime artifact.
    (list
     (cons 'structure-definition-identity
           (list
            (cons 'resource-type
                  (poo-flow-fhir-json-ref decoded "resourceType"))
            (cons 'id (poo-flow-fhir-json-ref decoded "id"))
            (cons 'canonical (poo-flow-fhir-json-ref decoded "url"))
            (cons 'version (poo-flow-fhir-json-ref decoded "version"))
            (cons 'type (poo-flow-fhir-json-ref decoded "type"))
            (cons 'base-definition
                  (poo-flow-fhir-json-ref decoded "baseDefinition"))))
     (cons
      'constraints
      (cons
       (poo-flow-fhir-constraint
        "fhir/au/core/1.0.0/Patient/resourceType"
        'resource-type '(resourceType) "Patient" 'supported)
       constraints)))))

(def (fixed-json-artifact-ref identity canonical exact-version artifact-kind
                              source-identity dependencies materialize)
  (let* ((source-entry (poo-flow-fhir-source-lock-entry source-identity))
         (digest (.ref source-entry 'digest))
         (size-bytes (.ref source-entry 'size-bytes)))
    (poo-flow-standard-artifact-ref
     identity canonical exact-version artifact-kind 'json digest dependencies
     size-bytes
     (lambda ()
       (call-with-values
        (lambda () (poo-flow-fhir-load-fixed-source source-identity))
        (lambda (entry receipt source)
          (poo-flow-standard-artifact-source
           identity (.ref entry 'digest) 'json source (.ref entry 'size-bytes)
           (list (cons 'source-url (.ref entry 'canonical-uri))
                 (cons 'source-lock-id (.ref FHIRSourcesLock 'lock-id))
                 (cons 'source-lock-digest (.ref FHIRSourcesLock 'digest))
                 (cons 'source-lock-receipt receipt))))))
     (lambda (loaded-source)
       (poo-flow-standard-artifact
        identity digest 'json
        (materialize (.ref loaded-source 'payload))
        (list (cons 'source-kind 'official-fixed-json))))
     (list (cons 'source-identity source-identity)
           (cons 'source-url (.ref source-entry 'canonical-uri))
           (cons 'source-lock-id (.ref FHIRSourcesLock 'lock-id))))))

(def fhir-r4-artifact
  (fixed-json-artifact-ref
   +poo-flow-fhir-medication-request-artifact-identity+
   "http://hl7.org/fhir/StructureDefinition/MedicationRequest"
   "4.0.1" 'structure-definition
   +poo-flow-fhir-medication-request-source-identity+ '()
   materialize-fhir-medication-request-source))

(def au-base-artifact
  (fixed-json-artifact-ref
   "hl7.fhir.au.base@5.0.0/package"
   "http://hl7.org.au/fhir/package" "5.0.0" 'implementation-guide
   +poo-flow-fhir-au-base-package-source-identity+
   (list +poo-flow-fhir-medication-request-artifact-identity+)
   (lambda (source)
     (materialize-fhir-package-manifest
      source "hl7.fhir.au.base" "5.0.0" "http://hl7.org.au/fhir"))))

(def au-core-artifact
  (fixed-json-artifact-ref
   "hl7.fhir.au.core@1.0.0/package"
   "http://hl7.org.au/fhir/core/package" "1.0.0" 'implementation-guide
   +poo-flow-fhir-au-core-package-source-identity+
   (list +poo-flow-fhir-au-core-patient-artifact-identity+)
   (lambda (source)
     (materialize-fhir-package-manifest
      source "hl7.fhir.au.core" "1.0.0"
      "http://hl7.org.au/fhir/core"))))

(def au-core-patient-artifact
  (poo-flow-standard-artifact-ref
   +poo-flow-fhir-au-core-patient-artifact-identity+
   "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"
   "1.0.0" 'structure-definition 'json
   (.ref au-core-patient-source-entry 'digest)
   '("hl7.fhir.au.base@5.0.0/package")
   (.ref au-core-patient-source-entry 'size-bytes)
   (lambda ()
     (call-with-values
      (lambda ()
        (poo-flow-fhir-load-fixed-source
         +poo-flow-fhir-au-core-patient-source-identity+))
      (lambda (entry receipt source)
        (poo-flow-standard-artifact-source
         +poo-flow-fhir-au-core-patient-artifact-identity+
         (.ref entry 'digest) (.ref entry 'representation) source
         (.ref entry 'size-bytes)
         (list
          (cons 'source-url (.ref entry 'canonical-uri))
          (cons 'source-path (.ref entry 'path))
          (cons 'source-lock-id (.ref FHIRSourcesLock 'lock-id))
          (cons 'source-lock-digest (.ref FHIRSourcesLock 'digest))
          (cons 'source-lock-receipt receipt))))))
   (lambda (loaded-source)
     (poo-flow-standard-artifact
      +poo-flow-fhir-au-core-patient-artifact-identity+
      (.ref au-core-patient-source-entry 'digest) 'json
      (materialize-au-core-patient-source (.ref loaded-source 'payload))
      (list (cons 'source-kind 'official-structure-definition))))
   (list (cons 'license "CC0-1.0")
         (cons 'source-url
               (.ref au-core-patient-source-entry 'canonical-uri))
         (cons 'source-lock-id (.ref FHIRSourcesLock 'lock-id)))))

(def FHIRR4StandardRef
  (poo-flow-standard-edition-ref
   "hl7.fhir.r4.core@4.0.1" FHIRStandardFamily "http://hl7.org/fhir/R4"
   "4.0.1" "FHIR R4" 'global (.ref fhir-r4-package-source-entry 'digest)
   "https://hl7.org/fhir/R4/" '() (list fhir-r4-artifact)
   (list +poo-flow-fhir-medication-request-artifact-identity+) 'active '()
   '((package . "hl7.fhir.r4.core"))))

(def AUBaseStandardRef
  (poo-flow-standard-edition-ref
   "hl7.fhir.au.base@5.0.0" FHIRStandardFamily "http://hl7.org.au/fhir"
   "5.0.0" "FHIR R4" 'AU (.ref au-base-package-source-entry 'digest)
   "https://hl7.org.au/fhir/" '("hl7.fhir.r4.core@4.0.1")
   (list au-base-artifact) '("hl7.fhir.au.base@5.0.0/package") 'active '()
   '((package . "hl7.fhir.au.base"))))

(def AUCoreStandardRef
  (poo-flow-standard-edition-ref
   "hl7.fhir.au.core@1.0.0" FHIRStandardFamily
   "http://hl7.org.au/fhir/core" "1.0.0" "FHIR R4" 'AU
   (.ref au-core-package-source-entry 'digest) "https://hl7.org.au/fhir/core/"
   '("hl7.fhir.au.base@5.0.0") (list au-core-artifact au-core-patient-artifact)
   '("hl7.fhir.au.core@1.0.0/package") 'active '()
   '((package . "hl7.fhir.au.core"))))

(def FHIRStandardsCatalog
  (poo-flow-standard-catalog
   "lambda-episteme/healthcare/standards/catalog/fhir-au/v1"
   (list FHIRR4StandardRef AUBaseStandardRef AUCoreStandardRef) '()))

(def FHIRValidationProfiles
  (list FHIRMedicationRequestStandardProfile FHIRAUCorePatientStandardProfile))

(def fhir-validation-profile-index
  (let (index (make-hash-table))
    (for-each
     (lambda (profile)
       (hash-put! index (.ref profile 'identity) profile))
     FHIRValidationProfiles)
    index))

(def (poo-flow-fhir-validation-profile identity)
  (or (hash-get fhir-validation-profile-index identity)
      (error "unsupported FHIR Standard Profile" identity)))

(def FHIRValidationProvider
  (.o kind: +poo-flow-standard-validation-provider-kind+
      identity: +poo-flow-fhir-provider-identity+
      supported-families: '("http://hl7.org/fhir")
      .validate-standard:
      (lambda (validation-closure subject)
        (healthcare-standard-validate
         FHIRValidationExecutor
         (poo-flow-fhir-validation-profile (.ref validation-closure 'identity))
         validation-closure subject))))
