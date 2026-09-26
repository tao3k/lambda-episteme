;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Vertical human-authorization meaning for Standard migration.  Cedar owns
;;; policy execution; this module owns the exact reviewer/action/resource
;;; projection and the admitted governance Binding returned to an Agent.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/modules/authorization/providers/cedar/interface
                 CedarAuthorizationProvider
                 poo-flow-cedar-authorization-request
                 poo-flow-cedar-authorization-request?
                 poo-flow-cedar-decision-permit?
                 poo-flow-cedar-runtime-handoff?)
        (only-in :poo-flow/modules/standards/interface
                 poo-flow-standard-digest
                 poo-flow-standard-governance-binding)
        "types.ss")

(export HealthcareStandardMigrationHumanAuthorizationInterface
        healthcare-standard-migration-cedar-request
        healthcare-standard-migration-human-authorization-binding)

(def +migration-action+
  "Healthcare::Action::\"approveStandardMigrationCutover\"")

(def (healthcare-standard-migration-cedar-request
      migration-case migration-receipt formal-assurance-digest handoff)
  (unless (and (healthcare-standard-migration-case? migration-case)
               (healthcare-standard-migration-receipt? migration-receipt)
               (.ref migration-receipt 'valid?)
               (string=? (.ref migration-case 'identity)
                         (.ref migration-receipt 'case-identity))
               (poo-flow-cedar-runtime-handoff? handoff))
    (error "Cedar migration request requires an admitted exact migration"
           migration-case migration-receipt))
  (let (review (.ref migration-case 'review))
    (unless (eq? (.ref review 'decision) 'approved)
      (error "Cedar migration request requires approved human review" review))
    (poo-flow-cedar-authorization-request
     (string-append "Healthcare::MigrationReviewer::\""
                    (.ref review 'reviewer-identity) "\"")
     +migration-action+
     (string-append "Healthcare::StandardMigration::\""
                    (.ref migration-case 'identity) "\"")
     (.o migrationDigest: (.ref migration-receipt 'migration-digest)
         formalAssuranceDigest: formal-assurance-digest
         humanReviewDigest: (.ref review 'review-digest)
         targetStandardEdition:
         (.ref migration-case 'target-standard-edition)
         aiAuthority: #f)
     (.ref migration-receipt 'migration-digest)
     handoff)))

(def (healthcare-standard-migration-human-authorization-binding
      request-value decision-value)
  (unless (and (poo-flow-cedar-authorization-request? request-value)
               (string=? (.ref request-value 'action) +migration-action+)
               (poo-flow-cedar-decision-permit? decision-value))
    (error "Standard migration cutover requires an exact Cedar permit"
           request-value decision-value))
  (let (binding-digest
        (poo-flow-standard-digest
         (list 'lambda-episteme.healthcare-standard-migration-cedar-permit.v1
               (.ref request-value 'principal) (.ref request-value 'action)
               (.ref request-value 'resource) (.ref request-value 'intent)
               (.ref decision-value 'decision-digest))))
    (poo-flow-standard-governance-binding
     'human-authorization "lambda-healthcare/standard-migration"
     'cedar-human-permit binding-digest 'admitted #t
     (.o request: request-value decision: decision-value))))

(def HealthcareStandardMigrationHumanAuthorizationInterface
  (.o kind: 'lambda-episteme.healthcare-standard-migration-human-authorization-interface
      provider: CedarAuthorizationProvider
      policy-source:
      "user-interface/scenarios/healthcare/authorization/standard-migration.cedar"
      schema-source:
      "user-interface/scenarios/healthcare/authorization/standard-migration-schema.json"
      principal-kind: 'Healthcare::MigrationReviewer
      action: +migration-action+
      resource-kind: 'Healthcare::StandardMigration
      .request: healthcare-standard-migration-cedar-request
      .admit-decision:
      healthcare-standard-migration-human-authorization-binding
      runtime-executed?: #f))
