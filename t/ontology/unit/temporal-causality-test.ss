;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        :std/list/list
        (only-in :yuanxu/graph/types
                 agentic-ai-lab-graph-edge-kind agentic-ai-lab-graph-edges)
        :agentic-ai-lab/modules/temporal-causality/interface
        :agentic-ai-lab/lambda-episteme/modules/ontology/interface
        :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/cases/wrong-prescription-review/case)

(export temporal-causality-test)

(def temporal-causality-test
  (test-suite
   "Ontology temporal causality"
   (test-case "wrong prescription keeps future candidates outside the cut"
     (let* ((receipt (ontology-compose-case WrongPrescriptionReviewCase))
            (event-graph
             (agentic-ai-lab-causal-event-graph
              "patient-1" (.ref receipt 'events)))
            (cut (agentic-ai-lab-causal-cut event-graph 4))
            (classification
             (agentic-ai-lab-temporal-causal-classify
              event-graph cut "prescription-1/rev1" 6))
            (reasoning (ontology-case-reasoning-graph receipt))
            (edge-kinds
             (map agentic-ai-lab-graph-edge-kind
                  (agentic-ai-lab-graph-edges reasoning))))
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
