(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/contribution/verification
        :poo-flow/lambda-episteme/modules/sdlc/interface
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-review
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-structured
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-lifecycle
        (only-in :std/srfi/1 append-map))
(export nasa-structured-test)
(include "../support/inventories.ss")
(def project (sdlc-project "structured-flight" "r1" "software" #t))
(def context (.o safety-critical?: #t health-medical?: #f))
(def digest (make-string 64 #\a))
(def inventories (test-inventories project 'a digest))
(def safety (car inventories))
(def trace (cadr inventories))
(def (safety-with coverage complexity)
  (.o (:: @ safety) components: (list (nasa-safety-component "controller" project #t coverage complexity))))
(def (passes? id inventory) (.ref (nasa-structured-review project 'a id inventory) 'passed?))
(def (test-adapter)
  ;; The synthetic verifier may accept a bad measurement. Local checks must
  ;; still reject it; the callback cannot replace deterministic evaluation.
  (nasa-verification-adapter "structured-test-only"
    (lambda (r now until) (and (equal? (.ref r 'subject) "structured-flight") (= now 0) (= until 10)))))
(def (evidence ids)
  (append-map (lambda (id)
                (map (lambda (c) (nasa-verifiable-evidence
                                 (nasa-criterion-evidence (.ref c 'identity) project id (.ref c 'identity) "synthetic" 'pass) digest))
                     (nasa-requirement-criteria id))) ids))
(def (receipts adapter records inventory-values)
  (map (lambda (r) (poo-flow-verify adapter r 0 10))
       (append (list (nasa-context-request project 'a context))
               (map nasa-evidence-request records)
               (map (lambda (i) (nasa-inventory-request i 'a)) inventory-values))))
(def nasa-structured-test
  (test-suite "NASA structured inventory admission"
    (test-case "coverage and complexity are evaluated independently at exact thresholds"
      (check-equal? (passes? "SWE-219" safety) #t)
      (check-equal? (passes? "SWE-220" safety) #t)
      (check-equal? (passes? "SWE-219" (safety-with 99 15)) #f)
      (check-equal? (passes? "SWE-220" (safety-with 99 15)) #t)
      (check-equal? (passes? "SWE-219" (safety-with 100 16)) #t)
      (check-equal? (passes? "SWE-220" (safety-with 100 16)) #f)
      (check-equal? (passes? "SWE-219" (safety-with 'unknown 15)) #f)
      (check-equal? (passes? "SWE-220" (safety-with 100 'unknown)) #f)
      (check-equal? (passes? "SWE-219" (.o (:: @ safety) complete?: #f)) #f)
      (check-equal? (passes? "SWE-219" (.o (:: @ safety) revision: "old")) #f)
      (check-equal? (passes? "SWE-219" (.o (:: @ safety) components: '())) #f)
      (check-exception (nasa-safety-inventory "bad" project "not-a-digest" '()) Error?))
    (test-case "trace rules require all current endpoints in both directions"
      (check-equal? (passes? "SWE-052" trace) #t)
      (check-equal? (passes? "SWE-052" (.o (:: @ trace) edges: (cdr (.ref trace 'edges)))) #f)
      (check-equal? (passes? "SWE-052" (.o (:: @ trace) nodes: (cdr (.ref trace 'nodes)))) #f)
      (check-equal? (passes? "SWE-052" (.o (:: @ trace) complete?: #f)) #f)
      (check-equal? (passes? "SWE-052" (.o (:: @ trace) nodes: (cons (.o (:: @ (car (.ref trace 'nodes))) revision: "old") (cdr (.ref trace 'nodes))))) #f)
      (check-exception (nasa-structured-review project 'a "SWE-219" trace) Error?))
    (test-case "a content pass and even an inventory receipt cannot hide a measured failure"
      (let* ((ids '("SWE-219" "SWE-220" "SWE-052")) (policy (nasa-stage-policy "safety-review" ids))
             (records (evidence ids)) (a (test-adapter)) (proofs (receipts a records inventories))
             (gate (lambda (is rs) (nasa-stage-gate policy project 'a context records a rs 1 inventories: is))))
        (check-equal? (.ref (gate '() proofs) 'admitted?) #f)
        (check-equal? (.ref (gate inventories (receipts a records '())) 'admitted?) #f)
        (check-equal? (.ref (gate inventories proofs) 'admitted?) #t)
        (let* ((bad (list (safety-with 99 16) trace)) (signed (receipts a records bad)))
          (check-equal? (.ref (gate bad signed) 'admitted?) #f))
        (check-equal? (.ref (gate (list (safety-with 100 14) trace) proofs) 'admitted?) #f)
        (check-equal? (.ref (gate (cons safety inventories) proofs) 'admitted?) #f)
        (check-equal? (.ref (nasa-stage-gate policy project 'a context records a proofs 10 inventories: inventories) 'admitted?) #f)
        (poo-flow-revoke-verification! a (car (reverse proofs)))
        (check-equal? (.ref (gate inventories proofs) 'admitted?) #f)))
    (test-case "cumulative transitions preserve inventory requirements"
      (let* ((p (nasa-stage-policy "safety" '("SWE-219")))
             (next (nasa-stage-policy "review" '("SWE-013")))
             (records (evidence '("SWE-219" "SWE-013"))) (a (test-adapter))
             (proofs (receipts a records inventories))
             (first (nasa-transition (nasa-lifecycle-start project) (list p next) "safety" project 'a context records a proofs 1 inventories: inventories)))
        (check-equal? (.ref first 'advanced?) #t)
        (check-equal? (.ref (nasa-transition (.ref first 'state) (list p next) "review" project 'a context records a proofs 1) 'advanced?) #f)
        (check-equal? (.ref (nasa-transition (.ref first 'state) (list p next) "review" project 'a context records a proofs 1 inventories: inventories) 'advanced?) #t)))))
