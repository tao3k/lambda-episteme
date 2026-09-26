;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: import an executed HL7 Validator OperationOutcome as
;;; immutable reference evidence.  This module never downloads or launches the
;;; validator and never treats unavailable output as a successful comparison.
(import (only-in :std/encoding/json JSONReadOptions string->json)
        (only-in :gerbil/core string-prefix?)
        (only-in :poo-flow/modules/standards/funs
                 poo-flow-standard-digest
                 poo-flow-standard-make-reference-observation))

(export +poo-flow-fhir-reference-validator-identity+
        poo-flow-fhir-reference-observation-from-operation-outcome
        poo-flow-fhir-reference-observation-from-bundle)

(def +poo-flow-fhir-reference-validator-identity+ "hl7.fhir.validator-cli")
(def +poo-flow-fhir-contribution-prefix+ "packages/lambda-episteme/")
(def +poo-flow-fhir-reference-json-read-options+
  (JSONReadOptions key-as-symbol: #f
                   array-as-vector: #f
                   object-as-hash: #t))

;;; Reference receipts keep the caller's portable source-ref, while reading
;;; from either supported checkout shape: POO Flow's registered mount or the
;;; Lambda contribution root itself.
(def (resolve-fhir-reference-output-path path)
  (cond
   ((file-exists? path) path)
   ((string-prefix? +poo-flow-fhir-contribution-prefix+ path)
    (let (relative
          (substring path
                     (string-length +poo-flow-fhir-contribution-prefix+)
                     (string-length path)))
      (if (file-exists? relative)
        relative
        (error "FHIR reference output is unavailable" path))))
   ((file-exists? (string-append +poo-flow-fhir-contribution-prefix+ path))
    (string-append +poo-flow-fhir-contribution-prefix+ path))
   (else (error "FHIR reference output is unavailable" path))))

(def (json-ref object key default)
  (if (hash-table? object) (hash-ref object key default) default))

(def (operation-outcome-issue-identity issue)
  (let ((severity (json-ref issue "severity" "unknown"))
        (code (json-ref issue "code" "unknown")))
    (string-append severity ":" code)))

(def (operation-outcome-error? issue)
  (let (severity (json-ref issue "severity" "unknown"))
    (or (string=? severity "fatal") (string=? severity "error"))))

(def (reference-output-operation-outcome decoded output-path entry-index)
  (let (resource-type (json-ref decoded "resourceType" #f))
    (cond
     ((and (string? resource-type)
           (string=? resource-type "OperationOutcome")
           (not entry-index))
      decoded)
     ((and (string? resource-type)
           (string=? resource-type "Bundle")
           (exact-integer? entry-index)
           (>= entry-index 0))
      (let* ((entries (json-ref decoded "entry" '()))
             (entry (and (< entry-index (length entries))
                         (list-ref entries entry-index)))
             (resource (and entry (json-ref entry "resource" #f))))
        (unless (and resource
                     (string=? (json-ref resource "resourceType" "")
                               "OperationOutcome"))
          (error "FHIR reference Bundle entry is not an OperationOutcome"
                 output-path entry-index))
        resource))
     (else
      (error "FHIR reference output has the wrong resource shape"
             output-path entry-index)))))

(def (reference-observation-from-output
      validator-version validator-binary-digest fixture-identity subject
      profile-identities output-path entry-index)
  (let* ((resolved-output-path
          (resolve-fhir-reference-output-path output-path))
         (raw-output (read-file-string resolved-output-path))
         (decoded
          (string->json raw-output
                        +poo-flow-fhir-reference-json-read-options+))
         (operation-outcome
          (reference-output-operation-outcome
           decoded output-path entry-index))
         (issues (json-ref operation-outcome "issue" '()))
         (issue-identities (map operation-outcome-issue-identity issues))
         (outcome (if (ormap operation-outcome-error? issues)
                    'invalid
                    'valid)))
    (poo-flow-standard-make-reference-observation
     +poo-flow-fhir-reference-validator-identity+
     validator-version validator-binary-digest fixture-identity
     (poo-flow-standard-digest subject) profile-identities outcome
     issue-identities
     (poo-flow-standard-digest (list raw-output entry-index))
     (append
      (list (cons 'source-ref output-path)
            (cons 'representation 'fhir-operation-outcome-json))
      (if entry-index (list (cons 'bundle-entry-index entry-index)) '())))))

(def (poo-flow-fhir-reference-observation-from-operation-outcome
      validator-version validator-binary-digest fixture-identity subject
      profile-identities output-path)
  (reference-observation-from-output
   validator-version validator-binary-digest fixture-identity subject
   profile-identities output-path #f))

(def (poo-flow-fhir-reference-observation-from-bundle
      validator-version validator-binary-digest fixture-identity subject
      profile-identities output-path entry-index)
  (reference-observation-from-output
   validator-version validator-binary-digest fixture-identity subject
   profile-identities output-path entry-index))
