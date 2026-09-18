;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref)
        (only-in :clan/poo/mop validate)
        (only-in :poo-flow/src/modules/standards/funs
                 poo-flow-standard-digest)
        "types.ss")

(export healthcare-standard-migration-proposal
        healthcare-standard-migration-review
        healthcare-standard-migration-case
        healthcare-standard-migration-failure
        healthcare-standard-migration-receipt)

(def (healthcare-standard-migration-proposal
      identity-value source-interface-value target-profile-value
      candidate-digest-value mapping-evidence-digest-value proposed-by-value
      ai-role-value)
  (let* ((proposal-digest-value
          (poo-flow-standard-digest
           (list 'lambda-episteme.healthcare-standard-migration-proposal.v1
                 identity-value source-interface-value target-profile-value
                 candidate-digest-value mapping-evidence-digest-value
                 proposed-by-value ai-role-value))))
    (validate
     HealthcareStandardMigrationProposal
     (.o kind: +healthcare-standard-migration-proposal-kind+
         identity: identity-value
         source-interface: source-interface-value
         target-profile: target-profile-value
         candidate-digest: candidate-digest-value
         mapping-evidence-digest: mapping-evidence-digest-value
         proposed-by: proposed-by-value
         ai-role: ai-role-value
         proposal-digest: proposal-digest-value
         runtime-executed?: #f))))

(def (healthcare-standard-migration-review
      proposal-value reviewer-identity-value decision-value
      review-evidence-digest-value)
  (let* ((review-digest-value
          (poo-flow-standard-digest
           (list 'lambda-episteme.healthcare-standard-migration-review.v1
                 (.ref proposal-value 'identity)
                 (.ref proposal-value 'proposal-digest)
                 reviewer-identity-value decision-value
                 review-evidence-digest-value))))
    (validate
     HealthcareStandardMigrationReview
     (.o kind: +healthcare-standard-migration-review-kind+
         proposal-identity: (.ref proposal-value 'identity)
         proposal-digest: (.ref proposal-value 'proposal-digest)
         reviewer-identity: reviewer-identity-value
         decision: decision-value
         review-evidence-digest: review-evidence-digest-value
         review-digest: review-digest-value
         runtime-executed?: #f))))

(def (healthcare-standard-migration-case
      identity-value jurisdiction-value source-interface-value
      source-version-value source-snapshot-digest-value
      parser-receipt-digest-value proposal-value review-value)
  (validate
   HealthcareStandardMigrationCase
   (.o kind: +healthcare-standard-migration-case-kind+
       identity: identity-value
       jurisdiction: jurisdiction-value
       source-interface: source-interface-value
       source-version: source-version-value
       source-snapshot-digest: source-snapshot-digest-value
       parser-receipt-digest: parser-receipt-digest-value
       proposal: proposal-value
       review: review-value)))

(def (healthcare-standard-migration-failure code-value subject-value
                                            detail-value path-value)
  (validate
   HealthcareStandardMigrationFailure
   (.o kind: +healthcare-standard-migration-failure-kind+
       code: code-value
       subject: subject-value
       detail: detail-value
       path: path-value)))

(def (healthcare-standard-migration-receipt
      case-identity-value source-interface-value target-profile-value
      conformance-digest-value evidence-digest-values failure-values
      migration-digest-value)
  (validate
   HealthcareStandardMigrationReceipt
   (.o kind: +healthcare-standard-migration-receipt-kind+
       valid?: (null? failure-values)
       case-identity: case-identity-value
       source-interface: source-interface-value
       target-profile: target-profile-value
       conformance-digest: conformance-digest-value
       evidence-digests: evidence-digest-values
       failures: failure-values
       migration-digest: migration-digest-value
       runtime-executed?: #f)))
