(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        (only-in :std/srfi/1 delete-duplicates filter))
(export nasa-catalog-test)
(def nasa-catalog-test
  (test-suite "NASA source catalog and invocation matrix"
    (test-case "complete catalog retains unique edition-bound identities"
      (let ((rows (.ref Nasa7150_2D 'requirements)))
        (check-equal? (length rows) 130)
        (check-equal? (length (delete-duplicates (map (lambda (r) (.ref r 'identity)) rows))) 130)
        (check-equal? (length (filter (lambda (r) (.slot? r 'class-matrix)) rows)) 100)
        (for-each (lambda (r)
                    (check-equal? (.ref r 'standard) "nasa/npr-7150.2d")
                    (check-equal? (.ref r 'assessment) 'not-evaluated)) rows)))
    (test-case "matrix blanks never become unconditional exemptions"
      (check-equal? (nasa-matrix-invocation "SWE-013" 'e) 'invoked)
      (check-equal? (nasa-matrix-invocation "SWE-034" 'e) 'not-invoked)
      (check-equal? (nasa-matrix-invocation "SWE-002" 'a) 'requirement-text)
      (check-exception (nasa-matrix-invocation "SWE-013" 'z) Error?)
      (check-exception (nasa-requirement-by-id "SWE-999") Error?))))
