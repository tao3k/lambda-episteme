;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :poo-flow/modules/authorization/providers/cedar/interface
                 poo-flow-cedar-policy)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-case-evaluation-receipt?))

(export vehicle-tara-reference-candidate
        vehicle-cedar-treatment-candidate)

;; Project a selected TARA reference for review. An empty approvalRef records
;; a missing external approval; this function cannot authorize publication.
(def (vehicle-tara-reference-candidate evaluation)
  (unless (and (ontology-case-evaluation-receipt? evaluation)
               (.ref evaluation 'accepted?))
    (error "Vehicle TARA handoff requires an accepted Case evaluation"
           evaluation))
  (let* ((case-value (.ref (.ref evaluation 'composition) 'case))
         (case-id (.ref case-value 'case-id)))
    (unless (eq? case-id 'vehicle-ota-treatment-handoff)
      (error "unsupported Vehicle TARA Case" case-id))
    (let* ((assessment (.ref case-value 'assessment-reference))
           (approval (.ref assessment 'approval-reference))
           (approval-ref (if (string? approval) approval "")))
      (.o kind: 'lambda-episteme.vehicle-tara-reference-candidate
          tara:
          (.o source: (.ref assessment 'source)
              workProductId: (.ref assessment 'work-product-id)
              revision: (.ref assessment 'revision)
              approvalRef: approval-ref
              treatmentGoal: (.ref case-value 'treatment-goal-id))
          approval-reference-present?: (not (equal? approval-ref ""))
          external-approval-verified?: #f
          publication: #f))))

;; Read one Lean-POO/Rust exported Cedar file through the existing POO Flow
;; Provider value. This constructs a candidate; the native Cedar authority
;; and the application host own parsing, approval, publication and effects.
(def (vehicle-cedar-treatment-candidate evaluation identity path)
  (let (tara (vehicle-tara-reference-candidate evaluation))
    (unless (and (string? path)
                 (>= (string-length path) 6)
                 (string=? (substring path (- (string-length path) 6)
                                      (string-length path))
                           ".cedar"))
      (error "Vehicle treatment requires an exported .cedar file" path))
    (let (policy
          (poo-flow-cedar-policy
           identity
           (call-with-input-file path read-all-as-string)))
      (.o kind: 'lambda-episteme.vehicle-cedar-treatment-candidate
          tara: tara
          cedar-policy: policy
          publication: #f
          runtime-executed?: #f))))
