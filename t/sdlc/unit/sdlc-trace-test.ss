(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/sdlc/interface
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d)
(def project (sdlc-project "flight" "r2" "software" #t))
(def rule (sdlc-trace-rule "SWE-052/verification" 'requirement 'verification))
(def req (sdlc-trace-node "req" 'requirement project))
(def test (sdlc-trace-node "test" 'verification project))
(def edge (sdlc-trace-edge "link" "SWE-052/verification" "req" "test" project))
(def (review nodes edges (p project)) (sdlc-trace-review p rule nodes edges))
(export sdlc-trace-test)
(def sdlc-trace-test
  (test-suite "NASA traceability and conditional applicability"
    (test-case "classification selects exactly the official trace pairs"
      (check-equal? (map (lambda (c) (length (nasa-trace-rules c))) '(a b c d e f)) '(6 6 6 3 0 3))
      (check-equal? (map (lambda (r) (.ref r 'identity)) (nasa-trace-rules 'f))
                    '("SWE-052/higher-requirements" "SWE-052/verification" "SWE-052/nonconformances")))
    (test-case "one witness supports both directions; empty inventories do not pass"
      (check-equal? (.ref (review (list req test) (list edge)) 'status) 'trace-evidence-present)
      (check-equal? (.ref (review (list req test) (list edge)) 'missing-backward) '())
      (check-equal? (.ref (review '() '()) 'status) 'inventory-review-required)
      (let ((r (review (list req test) '())))
        (check-equal? (.ref r 'missing-forward) '("req"))
        (check-equal? (.ref r 'missing-backward) '("test"))))
    (test-case "wrong targets, stale evidence and partial inventory are distinguished"
      (check-equal? (.ref (review (list req test) (list (.o (:: @ edge) target: "absent"))) 'status) 'invalid-endpoints)
      (check-equal? (.ref (review (list req test) (list (.o (:: @ edge) revision: "r1"))) 'status) 'trace-gaps)
      (check-equal? (.ref (review (list req test) '() (.o (:: @ project) complete?: #f)) 'status) 'unknown)
      (let ((result (review (list req) (list edge) (.o (:: @ project) complete?: #f))))
        (check-equal? (.ref result 'status) 'unknown)
        (check-equal? (.ref result 'invalid-edges) '())
        (check-equal? (.ref result 'unresolved-edges) '("link")))
      (check-exception (review (list req req test) (list edge)) Error?)
      (check-exception (review (list req test) (list edge edge)) Error?))
    (test-case "conditional clauses never infer missing facts or approve tailoring"
      (check-equal? (.ref (nasa-applicability "SWE-219" 'a (.o)) 'status) 'context-review-required)
      (check-equal? (.ref (nasa-applicability "SWE-219" 'a (.o safety-critical?: #t)) 'status) 'applicable)
      (check-equal? (.ref (nasa-applicability "SWE-219" 'a (.o safety-critical?: #t)) 'invocation) 'invoked)
      (check-equal? (.ref (nasa-applicability "SWE-219" 'a (.o safety-critical?: #f)) 'status) 'condition-not-triggered)
      (check-equal? (.ref (nasa-applicability "SWE-134" 'a (.o mission-critical?: #t)) 'status) 'applicable)
      (check-equal? (.ref (nasa-applicability "SWE-131" 'a (.o ivv-required?: #f)) 'status) 'condition-not-triggered)
      (check-equal? (.ref (nasa-applicability "SWE-034" 'e (.o)) 'status) 'not-invoked)
      (check-equal? (.ref (nasa-applicability "SWE-002" 'a (.o)) 'status) 'institutional-review-required)
      (check-equal? (length (nasa-project-obligations 'a (.o))) 130)
      (check-exception (nasa-applicability "SWE-219" 'a (.o safety-critical?: 'yes)) Error?))))
