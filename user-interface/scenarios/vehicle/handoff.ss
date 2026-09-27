;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref)
        (only-in :gerbil/core hash-put!)
        (only-in :std/encoding/json json->string)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-case-evaluation-receipt?))

(export vehicle-tara-reference-candidate vehicle-tara-reference-json)

;; Project the five fields consumed by Cedar-POO's TaraReference. An empty
;; approvalRef records a missing external approval; this function cannot
;; authorize a policy publication or verify the TARA work product.
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

;; JSON is a boundary artifact for downstream consumers. The POO candidate
;; remains the Lambda-owned semantic value; only TaraReference fields cross.
(def (vehicle-tara-reference-json candidate)
  (unless (eq? (.ref candidate 'kind)
               'lambda-episteme.vehicle-tara-reference-candidate)
    (error "invalid Vehicle TARA reference candidate" candidate))
  (let* ((tara (.ref candidate 'tara))
         (payload (make-hash-table)))
    (for-each
     (lambda (field)
       (hash-put! payload (symbol->string field) (.ref tara field)))
     '(source workProductId revision approvalRef treatmentGoal))
    (json->string payload)))
