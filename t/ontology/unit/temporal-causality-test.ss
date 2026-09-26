;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        :std/list/list
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph-edge-kind poo-flow-graph-edges)
        :poo-flow/modules/temporal-causality/interface
        :poo-flow/lambda-episteme/modules/ontology/interface
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/wrong-prescription-review/case)

(export temporal-causality-test)

(def temporal-causality-test
  (test-suite
   "Ontology temporal causality"
   (test-case "wrong prescription keeps future candidates outside the cut"
     (let* ((receipt (ontology-compose-case WrongPrescriptionReviewCase))
            (event-graph
             (poo-flow-causal-event-graph
              "patient-1" (.ref receipt 'events)))
            (cut (poo-flow-causal-cut event-graph 4))
            (classification
             (poo-flow-temporal-causal-classify
              event-graph cut "prescription-1/rev1" 6))
            (reasoning (ontology-case-reasoning-graph receipt))
            (edge-kinds
             (map poo-flow-graph-edge-kind
                  (poo-flow-graph-edges reasoning))))
       (check (.ref receipt 'accepted?) => #t)
       (check (length (.ref receipt 'events)) => 7)
       (check (map (lambda (event) (.ref event 'identity))
                   (.ref cut 'events))
              => '("prescription-1/rev1"
                   "administration-1"
                   "contraindication-observation-1"
                   "prescription-error-discovered-1"))
       (check (.ref classification 'status)
              => 'bounded-temporal-classification)
       (check (.ref classification 'past-event-ids)
              => '("prescription-1/rev1"
                   "administration-1"
                   "contraindication-observation-1"))
       (check (.ref classification 'current-event-ids)
              => '("prescription-error-discovered-1"))
       (check (.ref classification 'future-event-ids)
              => '("scheduled-administration-2" "care-reassessment-1"))
       (check (.ref classification 'hypothesized-event-ids) => '())
       (check (.ref classification 'counterfactual-event-ids)
              => '("corrected-prescription-1"))
       (check (.ref classification 'unknown-frontier) => '())
       (check (length (filter (lambda (kind) (eq? kind 'HAS_EVENT))
                              edge-kinds))
              => 7)
       (check (length (filter (lambda (kind) (eq? kind 'CAUSAL_PARENT))
                              edge-kinds))
              => 6)
       (check (.ref classification 'assurance-closed?) => #f)
       (check (.ref classification 'release-authorized?) => #f)))))
