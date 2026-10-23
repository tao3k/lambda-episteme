;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref)
        :std/list/list
        (only-in :std/test check-equal? test-case test-suite)
        (only-in :asp-gerbil-scheme/benchmark-api
                 benchmark-fixture-contract-pass?
                 benchmark-receipt-pass?
                 benchmark-run)
        (only-in :core/graph/types
                 agentic-ai-lab-graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-edge-from
                 agentic-ai-lab-graph-edge-kind agentic-ai-lab-graph-node
                 agentic-ai-lab-graph-node-id agentic-ai-lab-graph-node-payload)
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/objects
                 ontology-required-relation-rule
                 ontology-rule-evaluate))

(export required-relation-index-test)

(def fixture-relative-path
  "t/scenarios/performance/ontology-required-relation-index/benchmark.ss")
(def fixture-path
  (if (file-exists? fixture-relative-path)
    fixture-relative-path
    (string-append "packages/lambda-episteme/" fixture-relative-path)))
(def fixture (call-with-input-file fixture-path read))

(def (required-relation-graph node-count)
  (agentic-ai-lab-graph
   'ontology-required-relation/performance
   (cons (agentic-ai-lab-graph-node 'account 'Account)
         (map (lambda (id) (agentic-ai-lab-graph-node id 'Transaction))
              (iota node-count)))
   (map (lambda (id) (agentic-ai-lab-graph-edge id 'account 'postsTo))
        (iota (- node-count 1)))))

(def required-relation-rule
  (ontology-required-relation-rule
   'transaction-posts-to-account 'Transaction 'postsTo 'source))

;;; Test-only predecessor used for a deterministic algorithmic A/B receipt.
;;; It deliberately counts the former node-by-edge search at a bounded scale.
(def (reference-required-relation-result graph node-count)
  (let ((comparisons 0)
        (edges (.ref graph 'edges)))
    (let (missing-count
          (length
           (filter
            values
            (map
             (lambda (node)
               (and
                (eq? (agentic-ai-lab-graph-node-payload node) 'Transaction)
                (not
                 (find
                  (lambda (edge)
                    (set! comparisons (+ comparisons 1))
                    (and (eq? (agentic-ai-lab-graph-edge-kind edge) 'postsTo)
                         (eq? (agentic-ai-lab-graph-edge-from edge)
                              (agentic-ai-lab-graph-node-id node))))
                  edges))))
             (.ref graph 'nodes)))))
      (list (cons 'node-count node-count)
            (cons 'edge-count (- node-count 1))
            (cons 'missing-count missing-count)
            (cons 'reference-edge-comparisons comparisons)
            (cons 'indexed-node-and-edge-visits (+ node-count node-count))))))

(def (row-ref row key) (cdr (assoc key row)))

(def required-relation-index-test
  (test-suite "Ontology required-relation indexed evaluation"
    (test-case "removes the quadratic node-by-edge scan"
      (let* ((node-count 1000)
             (graph (required-relation-graph node-count))
             (receipt (reference-required-relation-result graph node-count)))
        (check-equal? (row-ref receipt 'missing-count) 1)
        (check-equal?
         (row-ref receipt 'reference-edge-comparisons)
         500499)
        (check-equal?
         (> (quotient (row-ref receipt 'reference-edge-comparisons)
                      (row-ref receipt 'indexed-node-and-edge-visits))
            200)
         #t)))
    (test-case "evaluates a 10,000-node Case graph through the hash index"
      (let* ((graph (required-relation-graph 10000))
             (summary
              (lambda ()
                (length
                 (ontology-rule-evaluate
                  required-relation-rule required-relation-rule graph))))
             (receipt (benchmark-run fixture summary)))
        (check-equal? (benchmark-fixture-contract-pass? fixture) #t)
        (check-equal? (summary) 1)
        (display "[lambda-episteme-benchmark] ontology-required-relation-index ")
        (write receipt)
        (newline)
        (force-output)
        (check-equal? (benchmark-receipt-pass? receipt) #t)))))
