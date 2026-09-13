(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/user-interface/change-review)
(export change-review-test)
(def change-review-test
  (test-suite "transitive change review over a scoped source inventory"
  (test-case "downstream verification is reopened with a concrete witness"
    (let ((r (change-review)))
      (check-equal? (.ref r 'status) 'scoped-impact-complete)
      (check-equal? (.ref r 'affected-identities) '("code" "design" "requirement" "verification"))
      (check-equal? (.ref r 'recheck-verifications) '("verification"))
      (check-equal? (.ref (car (reverse (.ref r 'witnesses))) 'edge-path) '("r-d" "d-c" "c-v"))
      (check-equal? (.ref r 'release-authorized?) #f)))
  (test-case "cycles terminate and ordering does not change selected paths"
    (let* ((cycle (sdlc-trace-edge "cycle" "implements" "code" "requirement" change-project))
           (edges (cons cycle change-edges))
           (a (sdlc-change-impact change-project change-nodes edges '("requirement") '("implements" "verifies")))
           (b (sdlc-change-impact change-project (reverse change-nodes) (reverse edges) '("requirement") '("implements" "verifies"))))
      (check-equal? (.ref a 'affected-identities) (.ref b 'affected-identities))
      (check-equal? (map (lambda (w) (.ref w 'edge-path)) (.ref a 'witnesses))
                    (map (lambda (w) (.ref w 'edge-path)) (.ref b 'witnesses)))))
  (test-case "partial scopes and missing endpoints never claim complete impact"
    (check-equal? (.ref (sdlc-change-impact (.o (:: @ change-project) complete?: #f)
                         change-nodes change-edges '("requirement") '("implements")) 'status) 'partial-impact)
    (let ((bad (cons (sdlc-trace-edge "bad" "implements" "code" "absent" change-project) change-edges)))
      (check-equal? (.ref (sdlc-change-impact change-project change-nodes bad '("requirement") '("implements")) 'status) 'invalid-inventory)))
  (test-case "stale links cannot carry changes into another baseline"
    (let ((edges (cons (.o (:: @ (car change-edges)) revision: "old") (cdr change-edges))))
      (check-equal? (.ref (sdlc-change-impact change-project change-nodes edges '("requirement") '("implements" "verifies")) 'affected-identities) '("requirement"))))
  (test-case "unknown seeds and duplicate identities fail closed"
    (check-exception (sdlc-change-impact change-project change-nodes change-edges '("absent") '("implements")) Error?)
    (check-exception (sdlc-change-impact change-project (cons (car change-nodes) change-nodes) change-edges '("requirement") '("implements")) Error?))))
