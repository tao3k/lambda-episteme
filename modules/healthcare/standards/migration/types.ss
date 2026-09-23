;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: typed, inert legacy-to-modern migration values.
(import (only-in :clan/poo/object .all-slots .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        :std/list/list
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-digest?
                 poo-flow-standard-failure?
                 poo-flow-standard-text?))

(export +healthcare-standard-migration-case-kind+
        +healthcare-standard-migration-ai-analysis-kind+
        +healthcare-standard-migration-ai-workflow-stages+
        +healthcare-standard-migration-field-mapping-kind+
        +healthcare-standard-migration-proposal-kind+
        +healthcare-standard-migration-review-kind+
        +healthcare-standard-migration-failure-kind+
        +healthcare-standard-migration-failure-codes+
        +healthcare-standard-migration-receipt-kind+
        HealthcareStandardMigrationCase
        HealthcareStandardMigrationAIAnalysis
        HealthcareStandardMigrationFieldMapping
        HealthcareStandardMigrationProposal
        HealthcareStandardMigrationReview
        HealthcareStandardMigrationFailure
        HealthcareStandardMigrationReceipt
        healthcare-standard-migration-case?
        healthcare-standard-migration-ai-analysis?
        healthcare-standard-migration-field-mapping?
        healthcare-standard-migration-proposal?
        healthcare-standard-migration-review?
        healthcare-standard-migration-failure?
        healthcare-standard-migration-receipt?)

(def +healthcare-standard-migration-case-kind+
  'lambda-episteme.healthcare-standard-migration-case.v1)
(def +healthcare-standard-migration-ai-analysis-kind+
  'lambda-episteme.healthcare-standard-migration-ai-analysis.v1)
(def +healthcare-standard-migration-ai-workflow-stages+
  '(inventory normalize map assess-risk generate-candidate validate
    explain-conformance review rehearse-cutover admit))
(def +healthcare-standard-migration-field-mapping-kind+
  'lambda-episteme.healthcare-standard-migration-field-mapping.v1)
(def +healthcare-standard-migration-proposal-kind+
  'lambda-episteme.healthcare-standard-migration-proposal.v1)
(def +healthcare-standard-migration-review-kind+
  'lambda-episteme.healthcare-standard-migration-review.v1)
(def +healthcare-standard-migration-failure-kind+
  'lambda-episteme.healthcare-standard-migration-failure.v1)
(def +healthcare-standard-migration-failure-codes+
  '(healthcare-migration-ai-authority-forbidden
    healthcare-migration-ai-analysis-unbound
    healthcare-migration-human-approval-missing
    healthcare-migration-governance-incomplete
    healthcare-migration-required-mapping-unresolved
    healthcare-migration-review-unbound
    healthcare-migration-source-interface-unqualified
    healthcare-migration-source-qualification-unbound
    healthcare-migration-source-interface-mismatch
    healthcare-migration-target-edition-mismatch
    healthcare-migration-target-profile-mismatch
    healthcare-migration-conformance-unbound))
(def +healthcare-standard-migration-receipt-kind+
  'lambda-episteme.healthcare-standard-migration-receipt.v1)

(def (migration-field-mapping-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +healthcare-standard-migration-field-mapping-kind+)
       (poo-flow-standard-text? (.ref value 'source-path))
       (poo-flow-standard-text? (.ref value 'target-path))
       (symbol? (.ref value 'transformation))
       (poo-flow-standard-text? (.ref value 'clinical-rationale))
       (poo-flow-standard-digest? (.ref value 'mapping-digest))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (HealthcareStandardMigrationFieldMapping @ Type.)
  .element?: migration-field-mapping-shape?)

(def (migration-ai-analysis-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind)
            +healthcare-standard-migration-ai-analysis-kind+)
       (poo-flow-standard-text? (.ref value 'identity))
       (memq (.ref value 'source-interface) '(hl7v2 cda national-service))
       (poo-flow-standard-text? (.ref value 'source-version))
       (poo-flow-standard-digest? (.ref value 'source-snapshot-digest))
       (poo-flow-standard-text? (.ref value 'target-standard-edition))
       (poo-flow-standard-text? (.ref value 'target-profile))
       (equal? (.ref value 'workflow-stages)
               +healthcare-standard-migration-ai-workflow-stages+)
       (let ((mappings (.ref value 'field-mappings)))
         (and (object? mappings)
              (pair? (.all-slots mappings))
              (every
               (lambda (slot)
                 (healthcare-standard-migration-field-mapping?
                  (.ref mappings slot)))
               (.all-slots mappings))))
       (poo-flow-standard-digest? (.ref value 'mapping-evidence-digest))
       (and (list? (.ref value 'unmapped-required-fields))
            (every symbol? (.ref value 'unmapped-required-fields)))
       (and (list? (.ref value 'risk-codes))
            (every symbol? (.ref value 'risk-codes)))
       (symbol? (.ref value 'cutover-strategy))
       (poo-flow-standard-text? (.ref value 'proposed-by))
       (symbol? (.ref value 'ai-role))
       (poo-flow-standard-digest? (.ref value 'analysis-digest))
       (eq? (.ref value 'runtime-executed?) #f)))

(define-type (HealthcareStandardMigrationAIAnalysis @ Type.)
  .element?: migration-ai-analysis-shape?)

(def (migration-proposal-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +healthcare-standard-migration-proposal-kind+)
       (poo-flow-standard-text? (.ref value 'identity))
       (memq (.ref value 'source-interface) '(hl7v2 cda national-service))
       (poo-flow-standard-text? (.ref value 'target-profile))
       (poo-flow-standard-digest? (.ref value 'candidate-digest))
       (poo-flow-standard-digest? (.ref value 'mapping-evidence-digest))
       (poo-flow-standard-digest? (.ref value 'ai-analysis-digest))
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
       (poo-flow-standard-text? (.ref value 'target-standard-edition))
       (poo-flow-standard-digest? (.ref value 'source-snapshot-digest))
       (poo-flow-standard-digest? (.ref value 'parser-receipt-digest))
       (poo-flow-standard-digest? (.ref value 'parser-grammar-digest))
       (memq (.ref value 'source-qualification-state)
             '(qualified declared-only))
       (poo-flow-standard-digest?
        (.ref value 'source-qualification-digest))
       (healthcare-standard-migration-ai-analysis?
        (.ref value 'ai-analysis))
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
       (poo-flow-standard-digest? (.ref value 'ai-analysis-digest))
       (equal? (.ref value 'workflow-stages)
               +healthcare-standard-migration-ai-workflow-stages+)
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

(def (healthcare-standard-migration-ai-analysis? value)
  (element? HealthcareStandardMigrationAIAnalysis value))

(def (healthcare-standard-migration-field-mapping? value)
  (element? HealthcareStandardMigrationFieldMapping value))

(def (healthcare-standard-migration-proposal? value)
  (element? HealthcareStandardMigrationProposal value))

(def (healthcare-standard-migration-review? value)
  (element? HealthcareStandardMigrationReview value))

(def (healthcare-standard-migration-failure? value)
  (element? HealthcareStandardMigrationFailure value))

(def (healthcare-standard-migration-receipt? value)
  (element? HealthcareStandardMigrationReceipt value))
