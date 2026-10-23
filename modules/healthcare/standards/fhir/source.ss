;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Representation boundary for fixed FHIR source snapshots. Source identity
;;; is admitted by the generated lock before JSON parsing or conformance.
(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/ports read-file-u8vector)
        :std/list/list
        (only-in :std/encoding/json JSONReadOptions u8vector->json)
        (only-in :core/feature-system/source-lock-feature
                 require-source-lock-payload
                 sources-lock-ref)
        "sources.ss")

(export agentic-ai-lab-fhir-source-lock-entry
        agentic-ai-lab-fhir-load-fixed-source
        agentic-ai-lab-fhir-parse-json-package-manifest
        agentic-ai-lab-fhir-parse-json-medication-request
        agentic-ai-lab-fhir-parse-json-structure-definition
        agentic-ai-lab-fhir-json-ref
        agentic-ai-lab-fhir-json-elements
        agentic-ai-lab-fhir-json-constraints)

(def +agentic-ai-lab-fhir-json-read-options+
  (JSONReadOptions key-as-symbol: #f
                   array-as-vector: #f
                   object-as-hash: #t))

(def (agentic-ai-lab-fhir-source-lock-entry identity)
  (or (sources-lock-ref FHIRSourcesLock identity)
      (error "FHIR source identity is absent from the generated lock"
             identity)))

;;; The contribution is valid both as an independent checkout and at POO
;;; Flow's registered mount. The lock keeps the portable contribution-relative
;;; path; this boundary resolves exactly those two declared repository shapes.
(def (agentic-ai-lab-fhir-resolve-source-path path)
  (cond
   ((file-exists? path) path)
   ((file-exists? (string-append "packages/lambda-episteme/" path))
    (string-append "packages/lambda-episteme/" path))
   (else (error "locked FHIR source path is unavailable" path))))

;;; Returns the admitted lock entry, verification receipt, and native bytes.
;;; Callers derive every identity field from the entry instead of maintaining
;;; digest, path, URI, version, or size constants beside the lock.
(def (agentic-ai-lab-fhir-load-fixed-source identity)
  (let* ((entry (agentic-ai-lab-fhir-source-lock-entry identity))
         (representation (.ref entry 'representation)))
    (unless (eq? representation 'json)
      (error "unsupported fixed FHIR source representation"
             representation (.ref entry 'canonical-uri)))
    (let* ((path (agentic-ai-lab-fhir-resolve-source-path (.ref entry 'path)))
           (bytes (read-file-u8vector path))
           (receipt
            (require-source-lock-payload FHIRSourcesLock identity bytes)))
      (values entry receipt bytes))))

(def (agentic-ai-lab-fhir-json-ref object key (default #f))
  (if (hash-table? object) (hash-ref object key default) default))

(def (agentic-ai-lab-fhir-decode-json-source source)
  (unless (u8vector? source)
    (error "invalid fixed FHIR JSON source" source))
  (u8vector->json source +agentic-ai-lab-fhir-json-read-options+))

(def (agentic-ai-lab-fhir-parse-json-package-manifest
      source expected-name expected-version expected-canonical)
  (let (decoded (agentic-ai-lab-fhir-decode-json-source source))
    (unless
     (and (string=? (agentic-ai-lab-fhir-json-ref decoded "name" "") expected-name)
          (string=? (agentic-ai-lab-fhir-json-ref decoded "version" "")
                    expected-version)
          (string=? (agentic-ai-lab-fhir-json-ref decoded "canonical" "")
                    expected-canonical)
          (member "4.0.1"
                  (agentic-ai-lab-fhir-json-ref decoded "fhirVersions" '())))
      (error "unexpected fixed FHIR package manifest"
             expected-name expected-version decoded))
    decoded))

(def (agentic-ai-lab-fhir-parse-json-medication-request source)
  (let (decoded (agentic-ai-lab-fhir-decode-json-source source))
    (unless
     (and (string=? (agentic-ai-lab-fhir-json-ref decoded "resourceType" "")
                    "StructureDefinition")
          (string=? (agentic-ai-lab-fhir-json-ref decoded "id" "")
                    "MedicationRequest")
          (string=? (agentic-ai-lab-fhir-json-ref decoded "url" "")
                    "http://hl7.org/fhir/StructureDefinition/MedicationRequest")
          (string=? (agentic-ai-lab-fhir-json-ref decoded "version" "") "4.0.1")
          (string=? (agentic-ai-lab-fhir-json-ref decoded "type" "")
                    "MedicationRequest"))
      (error "unexpected FHIR R4 MedicationRequest StructureDefinition"
             decoded))
    decoded))

(def (agentic-ai-lab-fhir-validate-structure-definition-metadata decoded)
  (unless
   (and (string=? (agentic-ai-lab-fhir-json-ref decoded "resourceType" "")
                  "StructureDefinition")
        (string=? (agentic-ai-lab-fhir-json-ref decoded "id" "")
                  "au-core-patient")
        (string=? (agentic-ai-lab-fhir-json-ref decoded "url" "")
                  "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")
        (string=? (agentic-ai-lab-fhir-json-ref decoded "version" "") "1.0.0"))
    (error "unexpected AU Core Patient StructureDefinition metadata" decoded))
  decoded)

(def (agentic-ai-lab-fhir-parse-json-structure-definition source)
  (agentic-ai-lab-fhir-validate-structure-definition-metadata
   (agentic-ai-lab-fhir-decode-json-source source)))

(def (agentic-ai-lab-fhir-json-elements decoded section-name)
  (let (section (agentic-ai-lab-fhir-json-ref decoded section-name #f))
    (if section
      (agentic-ai-lab-fhir-json-ref section "element" '())
      '())))

(def (agentic-ai-lab-fhir-json-constraints decoded)
  (let* ((differential
          (agentic-ai-lab-fhir-json-ref decoded "differential" #f))
         (elements
          (agentic-ai-lab-fhir-json-ref differential "element" '())))
    (concatenate (map
     (lambda (element)
       (agentic-ai-lab-fhir-json-ref element "constraint" '()))
     elements))))
