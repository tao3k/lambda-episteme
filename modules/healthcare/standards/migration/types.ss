;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: typed, inert legacy-to-modern migration values.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :std/srfi/1 every)
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-digest?
                 poo-flow-standard-failure?
                 poo-flow-standard-text?))

(export +healthcare-standard-migration-case-kind+
        +healthcare-standard-migration-proposal-kind+
        +healthcare-standard-migration-review-kind+
        +healthcare-standard-migration-failure-kind+
        +healthcare-standard-migration-failure-codes+
        +healthcare-standard-migration-receipt-kind+
        HealthcareStandardMigrationCase
        HealthcareStandardMigrationProposal
        HealthcareStandardMigrationReview
        HealthcareStandardMigrationFailure
        HealthcareStandardMigrationReceipt
        healthcare-standard-migration-case?
        healthcare-standard-migration-proposal?
        healthcare-standard-migration-review?
        healthcare-standard-migration-failure?
        healthcare-standard-migration-receipt?)

(def +healthcare-standard-migration-case-kind+
  'lambda-episteme.healthcare-standard-migration-case.v1)
(def +healthcare-standard-migration-proposal-kind+
  'lambda-episteme.healthcare-standard-migration-proposal.v1)
(def +healthcare-standard-migration-review-kind+
  'lambda-episteme.healthcare-standard-migration-review.v1)
(def +healthcare-standard-migration-failure-kind+
  'lambda-episteme.healthcare-standard-migration-failure.v1)
(def +healthcare-standard-migration-failure-codes+
  '(healthcare-migration-ai-authority-forbidden
    healthcare-migration-human-approval-missing
    healthcare-migration-review-unbound
    healthcare-migration-source-interface-mismatch
    healthcare-migration-target-profile-mismatch
    healthcare-migration-conformance-unbound))
(def +healthcare-standard-migration-receipt-kind+
  'lambda-episteme.healthcare-standard-migration-receipt.v1)

(def (migration-proposal-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-proposal-kind+)
       (poo-flow-standard-text? (.ref value 'identity))
       (memq (.ref value 'source-interface) '(hl7v2 cda national-service))
       (poo-flow-standard-text? (.ref value 'target-profile))
       (poo-flow-standard-digest? (.ref value 'candidate-digest))
       (poo-flow-standard-digest? (.ref value 'mapping-evidence-digest))
       (poo-flow-standard-text? (.ref value 'proposed-by))
       (symbol? (.ref value 'ai-role))
       (poo-flow-standard-digest? (.ref value 'proposal-digest))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (HealthcareStandardMigrationProposal @ Type.)
  .element?: migration-proposal-shape?)

(def (migration-review-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-review-kind+)
       (poo-flow-standard-text? (.ref value 'proposal-identity))
       (poo-flow-standard-digest? (.ref value 'proposal-digest))
       (poo-flow-standard-text? (.ref value 'reviewer-identity))
       (memq (.ref value 'decision) '(approved rejected))
       (poo-flow-standard-digest? (.ref value 'review-evidence-digest))
       (poo-flow-standard-digest? (.ref value 'review-digest))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (HealthcareStandardMigrationReview @ Type.)
  .element?: migration-review-shape?)

(def (migration-case-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-case-kind+)
       (poo-flow-standard-text? (.ref value 'identity))
       (symbol? (.ref value 'jurisdiction))
       (memq (.ref value 'source-interface) '(hl7v2 cda national-service))
       (poo-flow-standard-text? (.ref value 'source-version))
       (poo-flow-standard-digest? (.ref value 'source-snapshot-digest))
       (poo-flow-standard-digest? (.ref value 'parser-receipt-digest))
       (healthcare-standard-migration-proposal? (.ref value 'proposal))
       (healthcare-standard-migration-review? (.ref value 'review))))

(define-type (HealthcareStandardMigrationCase @ Type.)
  .element?: migration-case-shape?)

(def (migration-failure-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-failure-kind+)
       (memq (.ref value 'code)
             +healthcare-standard-migration-failure-codes+)
       (poo-flow-standard-text? (.ref value 'subject))
       (poo-flow-standard-text? (.ref value 'detail))
       (list? (.ref value 'path))))

(define-type (HealthcareStandardMigrationFailure @ Type.)
  .element?: migration-failure-shape?)

(def (migration-receipt-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-receipt-kind+)
       (boolean? (.ref value 'valid?))
       (poo-flow-standard-text? (.ref value 'case-identity))
       (memq (.ref value 'source-interface) '(hl7v2 cda national-service))
       (poo-flow-standard-text? (.ref value 'target-profile))
       (poo-flow-standard-digest? (.ref value 'conformance-digest))
       (and (list? (.ref value 'evidence-digests))
            (every poo-flow-standard-digest? (.ref value 'evidence-digests)))
       (and (list? (.ref value 'failures))
            (every
             (lambda (failure)
               (or (poo-flow-standard-failure? failure)
                   (healthcare-standard-migration-failure? failure)))
             (.ref value 'failures)))
       (eq? (.ref value 'valid?) (null? (.ref value 'failures)))
       (poo-flow-standard-digest? (.ref value 'migration-digest))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (HealthcareStandardMigrationReceipt @ Type.)
  .element?: migration-receipt-shape?)

(def (healthcare-standard-migration-case? value)
  (element? HealthcareStandardMigrationCase value))

(def (healthcare-standard-migration-proposal? value)
  (element? HealthcareStandardMigrationProposal value))

(def (healthcare-standard-migration-review? value)
  (element? HealthcareStandardMigrationReview value))

(def (healthcare-standard-migration-failure? value)
  (element? HealthcareStandardMigrationFailure value))

(def (healthcare-standard-migration-receipt? value)
  (element? HealthcareStandardMigrationReceipt value))
