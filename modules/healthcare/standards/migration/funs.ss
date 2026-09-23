;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The parser receipt proves syntax ownership upstream.  This module maps an
;;; already-normalized healthcare subject; it does not parse HL7v2 or CDA.
(import (only-in :clan/poo/object .o .ref object?)
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-conformance-receipt?
                 poo-flow-standard-governance-interface?
                 poo-flow-standard-validation-closure?)
        (only-in :poo-flow/src/modules/standards/funs
                 poo-flow-standard-digest)
        "types.ss"
        "objects.ss")

(export healthcare-hl7v2-patient-projection->subject
        healthcare-au-legacy-patient->fhir-candidate
        healthcare-standard-migration-admit)

(def (projection-ref projection key)
  (let (entry (assq key projection))
    (and entry (cdr entry))))

;;; This is an admission adapter for a gerbil-parser-owned projection receipt,
;;; not an HL7v2 parser. Syntax, delimiter and field-position handling remain
;;; wholly upstream in gerbil-parser.
(def (healthcare-hl7v2-patient-projection->subject projection)
  (unless (and (list? projection)
               (equal? (projection-ref projection 'schema)
                       "gerbil-parser.hl7v2-adt-a08-patient.v1")
               (equal? (projection-ref projection 'sourceInterface) 'hl7v2)
               (string? (projection-ref projection 'sourceDigest))
               (string? (projection-ref projection 'grammarDigest))
               (string? (projection-ref projection 'sourceMessageType))
               (string? (projection-ref projection 'sourceVersion))
               (string? (projection-ref projection 'identifierSystem))
               (string? (projection-ref projection 'identifierValue))
               (string? (projection-ref projection 'familyName))
               (and (list? (projection-ref projection 'givenNames))
                    (not (null? (projection-ref projection 'givenNames)))
                    (andmap string?
                            (projection-ref projection 'givenNames))))
    (error "invalid gerbil-parser HL7v2 patient projection" projection))
  (.o source-interface: (projection-ref projection 'sourceInterface)
      source-message-type: (projection-ref projection 'sourceMessageType)
      source-version: (projection-ref projection 'sourceVersion)
      source-snapshot-digest: (projection-ref projection 'sourceDigest)
      parser-grammar-digest: (projection-ref projection 'grammarDigest)
      identifier-system: (projection-ref projection 'identifierSystem)
      identifier-value: (projection-ref projection 'identifierValue)
      family-name: (projection-ref projection 'familyName)
      given-names: (projection-ref projection 'givenNames)))

(def (healthcare-au-legacy-patient->fhir-candidate normalized-subject)
  (unless (object? normalized-subject)
    (error "legacy patient input must be a parser-normalized POO object"
           normalized-subject))
  `((resourceType . "Patient")
    (identifier
     . (((system . ,(.ref normalized-subject 'identifier-system))
         (value . ,(.ref normalized-subject 'identifier-value)))))
    (name
     . (((family . ,(.ref normalized-subject 'family-name))
         (given . ,(.ref normalized-subject 'given-names)))))))

(def (migration-failure migration-case code detail path)
  (healthcare-standard-migration-failure
   code (.ref migration-case 'identity) detail path))

(def (healthcare-standard-migration-admit migration-case validation-closure
                                          conformance-receipt
                                          governance-interface)
  (unless (and (healthcare-standard-migration-case? migration-case)
               (poo-flow-standard-validation-closure? validation-closure)
               (poo-flow-standard-conformance-receipt? conformance-receipt)
               (poo-flow-standard-governance-interface?
                governance-interface))
    (error "invalid Healthcare Standard migration admission input"
           migration-case))
  (let* ((governance-receipt
          ((.ref governance-interface '.validate-governance) 'admit))
         (proposal (.ref migration-case 'proposal))
         (review (.ref migration-case 'review))
         (ai-analysis (.ref migration-case 'ai-analysis))
         (target-profile (.ref proposal 'target-profile))
         (target-standard-edition
          (.ref migration-case 'target-standard-edition))
         (target-subject-digest (.ref proposal 'candidate-digest))
         (conformance-digest (.ref conformance-receipt 'conformance-digest))
         (evidence-digests
          (list (.ref migration-case 'source-snapshot-digest)
                (.ref migration-case 'parser-receipt-digest)
                (.ref migration-case 'parser-grammar-digest)
                (.ref migration-case 'source-qualification-digest)
                (.ref ai-analysis 'analysis-digest)
                (.ref proposal 'mapping-evidence-digest)
                (.ref proposal 'proposal-digest)
                (.ref review 'review-evidence-digest)
                (.ref review 'review-digest)
                (.ref governance-receipt 'receipt-digest)))
         (policy-failures
          (append
           (if (.ref governance-receipt 'valid?)
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-governance-incomplete
               "mandatory Standard governance slots are absent or not qualified"
               (append
                '(governance admit)
                (.ref governance-receipt 'missing-slots)
                (.ref governance-receipt 'invalid-status-slots)))))
           (if (eq? (.ref migration-case 'source-qualification-state)
                    'qualified)
             '()
             (list
              (migration-failure
               migration-case
               'healthcare-migration-source-interface-unqualified
               "legacy interface is declared but has no admitted parser or adapter qualification"
               '(source-qualification-state))))
           (if (string=?
                (.ref migration-case 'source-qualification-digest)
                (poo-flow-standard-digest
                 (list 'gerbil-parser-hl7v2-qualification
                       (.ref migration-case 'source-snapshot-digest)
                       (.ref migration-case 'parser-grammar-digest)
                       (.ref migration-case 'parser-receipt-digest))))
             '()
             (list
              (migration-failure
               migration-case
               'healthcare-migration-source-qualification-unbound
               "source qualification does not bind the source, grammar and parser receipt digests"
               '(source-qualification-digest))))
           (if (and (eq? (.ref ai-analysis 'ai-role) 'advisory-only)
                    (eq? (.ref proposal 'ai-role) 'advisory-only))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-ai-authority-forbidden
               "AI may propose mappings but cannot authorize migration"
               '(ai-role))))
           (if (and
                (eq? (.ref ai-analysis 'source-interface)
                     (.ref migration-case 'source-interface))
                (string=? (.ref ai-analysis 'source-version)
                          (.ref migration-case 'source-version))
                (string=? (.ref ai-analysis 'source-snapshot-digest)
                          (.ref migration-case 'source-snapshot-digest))
                (string=? (.ref ai-analysis 'target-standard-edition)
                          target-standard-edition)
                (string=? (.ref ai-analysis 'target-profile) target-profile)
                (string=? (.ref ai-analysis 'mapping-evidence-digest)
                          (.ref proposal 'mapping-evidence-digest))
                (string=? (.ref ai-analysis 'analysis-digest)
                          (.ref proposal 'ai-analysis-digest)))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-ai-analysis-unbound
               "AI analysis is not bound to the source snapshot, exact target edition and mapping proposal"
               '(ai-analysis analysis-digest))))
           (if (null? (.ref ai-analysis 'unmapped-required-fields))
             '()
             (list
              (migration-failure
               migration-case
               'healthcare-migration-required-mapping-unresolved
               "required source fields remain unmapped"
               '(ai-analysis unmapped-required-fields))))
           (if (eq? (.ref review 'decision) 'approved)
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-human-approval-missing
               "a human reviewer must approve the mapping before admission"
               '(review decision))))
           (if (and
                (string=? (.ref review 'proposal-identity)
                          (.ref proposal 'identity))
                (string=? (.ref review 'proposal-digest)
                          (.ref proposal 'proposal-digest)))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-review-unbound
               "review evidence is not bound to this proposal"
               '(review proposal-digest))))
           (if (eq? (.ref migration-case 'source-interface)
                    (.ref proposal 'source-interface))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-source-interface-mismatch
               "proposal belongs to another legacy interface family"
               '(proposal source-interface))))
           (if (string=? target-profile (.ref validation-closure 'identity))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-target-profile-mismatch
               "validation closure targets another Standard Profile"
               '(target-profile))))
           (if (any
                (lambda (edition)
                  (string=? (.ref edition 'identity)
                            target-standard-edition))
                (.ref (.ref validation-closure 'bundle) 'editions))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-target-edition-mismatch
               "validation closure does not contain the exact target Standard edition"
               '(target-standard-edition))))
           (if (and
                (string=? target-subject-digest
                          (.ref validation-closure 'subject-snapshot-digest))
                (string=? target-subject-digest
                          (.ref conformance-receipt 'subject-snapshot-digest))
                (string=? (.ref validation-closure 'validation-closure-digest)
                          (.ref conformance-receipt
                                'validation-closure-digest)))
             '()
             (list
              (migration-failure
               migration-case 'healthcare-migration-conformance-unbound
               "conformance evidence is not bound to this candidate"
               '(target-subject-digest))))))
         (failures
          (append (.ref conformance-receipt 'failures) policy-failures))
         (migration-digest
          (poo-flow-standard-digest
           (list 'lambda-episteme.healthcare-standard-migration.v1
                 (.ref migration-case 'identity)
                 (.ref migration-case 'source-interface)
                 (.ref migration-case 'source-qualification-state)
                 target-standard-edition
                 (.ref ai-analysis 'analysis-digest)
                 (.ref ai-analysis 'workflow-stages)
                 target-profile target-subject-digest conformance-digest
                 evidence-digests (.ref review 'decision)
                 (map (lambda (failure) (.ref failure 'code)) failures)))))
    (healthcare-standard-migration-receipt
     (.ref migration-case 'identity)
     (.ref migration-case 'source-interface)
     target-profile (.ref ai-analysis 'analysis-digest)
     (.ref ai-analysis 'workflow-stages) conformance-digest
     evidence-digests failures migration-digest)))
