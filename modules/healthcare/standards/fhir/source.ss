;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Representation boundary for fixed FHIR source snapshots. Source identity
;;; is admitted by the generated lock before JSON parsing or conformance.
(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-file-u8vector)
        (only-in :std/srfi/1 append-map)
        (only-in :std/text/json
                 bytes->json-object
                 read-json-array-as-vector?
                 read-json-key-as-symbol?
                 read-json-object-as-walist?)
        (only-in :poo-flow/src/feature-system/source-lock-feature
                 require-source-lock-payload
                 sources-lock-ref)
        "sources.ss")

(export poo-flow-fhir-source-lock-entry
        poo-flow-fhir-load-fixed-source
        poo-flow-fhir-parse-json-package-manifest
        poo-flow-fhir-parse-json-medication-request
        poo-flow-fhir-parse-json-structure-definition
        poo-flow-fhir-json-ref
        poo-flow-fhir-json-elements
        poo-flow-fhir-json-constraints)

(def (poo-flow-fhir-source-lock-entry identity)
  (or (sources-lock-ref FHIRSourcesLock identity)
      (error "FHIR source identity is absent from the generated lock"
             identity)))

;;; The contribution is valid both as an independent checkout and at POO
;;; Flow's registered mount. The lock keeps the portable contribution-relative
;;; path; this boundary resolves exactly those two declared repository shapes.
(def (poo-flow-fhir-resolve-source-path path)
  (cond
   ((file-exists? path) path)
   ((file-exists? (string-append "packages/lambda-episteme/" path))
    (string-append "packages/lambda-episteme/" path))
   (else (error "locked FHIR source path is unavailable" path))))

;;; Returns the admitted lock entry, verification receipt, and native bytes.
;;; Callers derive every identity field from the entry instead of maintaining
;;; digest, path, URI, version, or size constants beside the lock.
(def (poo-flow-fhir-load-fixed-source identity)
  (let* ((entry (poo-flow-fhir-source-lock-entry identity))
         (representation (.ref entry 'representation)))
    (unless (eq? representation 'json)
      (error "unsupported fixed FHIR source representation"
             representation (.ref entry 'canonical-uri)))
    (let* ((path (poo-flow-fhir-resolve-source-path (.ref entry 'path)))
           (bytes (read-file-u8vector path))
           (receipt
            (require-source-lock-payload FHIRSourcesLock identity bytes)))
      (values entry receipt bytes))))

(def (poo-flow-fhir-json-ref object key (default #f))
  (if (hash-table? object) (hash-ref object key default) default))

(def (poo-flow-fhir-decode-json-source source)
  (unless (u8vector? source)
    (error "invalid fixed FHIR JSON source" source))
  (parameterize ((read-json-key-as-symbol? #f)
                 (read-json-object-as-walist? #f)
                 (read-json-array-as-vector? #f))
    (bytes->json-object source)))

(def (poo-flow-fhir-parse-json-package-manifest
      source expected-name expected-version expected-canonical)
  (let (decoded (poo-flow-fhir-decode-json-source source))
    (unless
     (and (string=? (poo-flow-fhir-json-ref decoded "name" "") expected-name)
          (string=? (poo-flow-fhir-json-ref decoded "version" "")
                    expected-version)
          (string=? (poo-flow-fhir-json-ref decoded "canonical" "")
                    expected-canonical)
          (member "4.0.1"
                  (poo-flow-fhir-json-ref decoded "fhirVersions" '())))
      (error "unexpected fixed FHIR package manifest"
             expected-name expected-version decoded))
    decoded))

(def (poo-flow-fhir-parse-json-medication-request source)
  (let (decoded (poo-flow-fhir-decode-json-source source))
    (unless
     (and (string=? (poo-flow-fhir-json-ref decoded "resourceType" "")
                    "StructureDefinition")
          (string=? (poo-flow-fhir-json-ref decoded "id" "")
                    "MedicationRequest")
          (string=? (poo-flow-fhir-json-ref decoded "url" "")
                    "http://hl7.org/fhir/StructureDefinition/MedicationRequest")
          (string=? (poo-flow-fhir-json-ref decoded "version" "") "4.0.1")
          (string=? (poo-flow-fhir-json-ref decoded "type" "")
                    "MedicationRequest"))
      (error "unexpected FHIR R4 MedicationRequest StructureDefinition"
             decoded))
    decoded))

(def (poo-flow-fhir-validate-structure-definition-metadata decoded)
  (unless
   (and (string=? (poo-flow-fhir-json-ref decoded "resourceType" "")
                  "StructureDefinition")
        (string=? (poo-flow-fhir-json-ref decoded "id" "")
                  "au-core-patient")
        (string=? (poo-flow-fhir-json-ref decoded "url" "")
                  "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")
        (string=? (poo-flow-fhir-json-ref decoded "version" "") "1.0.0"))
    (error "unexpected AU Core Patient StructureDefinition metadata" decoded))
  decoded)

(def (poo-flow-fhir-parse-json-structure-definition source)
  (poo-flow-fhir-validate-structure-definition-metadata
   (poo-flow-fhir-decode-json-source source)))

(def (poo-flow-fhir-json-elements decoded section-name)
  (let (section (poo-flow-fhir-json-ref decoded section-name #f))
    (if section
      (poo-flow-fhir-json-ref section "element" '())
      '())))

(def (poo-flow-fhir-json-constraints decoded)
  (let* ((differential
          (poo-flow-fhir-json-ref decoded "differential" #f))
         (elements
          (poo-flow-fhir-json-ref differential "element" '())))
    (append-map
     (lambda (element)
       (poo-flow-fhir-json-ref element "constraint" '()))
     elements)))
