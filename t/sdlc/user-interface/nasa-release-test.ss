(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/user-interface/nasa-release
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d)
(export nasa-release-test)
(def nasa-release-test
  (test-suite "independent NASA release review"
    (test-case "all selected traces are present but authority remains pending"
      (let* ((project (sdlc-project "flight" "r3" "release" #t))
             (categories '(higher-requirement requirement verification nonconformance))
             (nodes (map (lambda (c) (sdlc-trace-node (symbol->string c) c project)) categories))
             (edges (map (lambda (r)
                           (sdlc-trace-edge (.ref r 'identity) (.ref r 'identity)
                                           (symbol->string (.ref r 'source-category))
                                           (symbol->string (.ref r 'target-category)) project))
                         (nasa-trace-rules 'f)))
             (report (nasa-release-review 'f project (.o) nodes edges)))
        (check-equal? (length (.ref report 'applicability)) 130)
        (check-equal? (map (lambda (r) (.ref r 'status)) (.ref report 'traceability))
                      '(trace-evidence-present trace-evidence-present trace-evidence-present))
        (check-equal? (> (length (.ref report 'pending-context)) 0) #t)
        (check-equal? (.ref report 'release-authorized?) #f)
        (check-equal? (.ref report 'compliance) 'not-evaluated)))
    (test-case "failed evidence is not hidden by a tailoring request"
      (let* ((project (sdlc-project "flight" "r3" "release" #t))
             (obligation (sdlc-obligation "nasa/npr-7150.2d" "SWE-034" 'applicable))
             (evidence (sdlc-evidence "failure" "flight" "r3" "release"
                                      "nasa/npr-7150.2d" "SWE-034" "reviewer" 'fail))
             (requests (list (sdlc-tailoring-request "flight" "r3" "nasa/npr-7150.2d" "SWE-034" "requested relief")))
             (profile (sdlc-with-standards SdlcProfile (list Nasa7150_2D))))
        (check-equal? (.ref (sdlc-review profile project obligation (list evidence) requests) 'status) 'reported-failure)
        (check-exception (sdlc-review profile project obligation (list evidence evidence) '()) Error?)))
    (test-case "duplicate or malformed requirement catalogs are rejected"
      (check-equal? (sdlc-profile? (.o (:: @ SdlcProfile)
                                      standards: (list Nasa7150_2D Nasa7150_2D))) #f)
      (check-equal? (standard-profile? (.o (:: @ Nasa7150_2D) requirements: (list (.o)))) #f)
      (check-equal? (standard-profile? (.o (:: @ Nasa7150_2D)
                                          requirements: (list (.o identity: "x") (.o identity: "x")))) #f))))
