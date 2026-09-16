;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Scenario-local policy helper: Profiles name required Case evidence while the
;;; POO Flow Governance core remains the sole assessment/receipt owner.
(import (only-in :clan/poo/object .ref .slot?)
        (only-in :poo-flow/src/modules/governance/objects
                 poo-flow-governance-assessment-value
                 poo-flow-governance-threat-blocking?))

(export healthcare-contextual-governance-assessment)

(def (healthcare-unique-text values)
  (let ((seen (make-hash-table))
        (result-reverse '()))
    (for-each
     (lambda (value)
       (unless (hash-get seen value)
         (hash-put! seen value #t)
         (set! result-reverse (cons value result-reverse))))
     values)
    (reverse result-reverse)))

(def (healthcare-contextual-governance-assessment
      profile context required-evidence)
  (let* ((model (.ref profile 'threat-model))
         (static-blockers
          (map (lambda (threat) (.ref threat 'identity))
               (filter poo-flow-governance-threat-blocking?
                       (.ref model 'threats))))
         (missing-evidence
          (filter values
                  (map
                   (lambda (requirement)
                     (let ((slot (car requirement))
                           (threat (cdr requirement)))
                       (and (not (and (.slot? context slot)
                                      (.ref context slot)))
                            threat)))
                   required-evidence)))
         (unresolved
          (healthcare-unique-text
           (append static-blockers missing-evidence))))
    (poo-flow-governance-assessment-value
     profile model unresolved context)))
