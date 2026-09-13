(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/review
        :lambda-episteme/user-interface/sdlc-cases)
(export sdlc-cases-test)
(def sdlc-cases-test
  (test-suite "independent SDLC user scenarios"
    (test-case "complex source facts preserve review and execution boundaries"
      (for-each (lambda (value)
                  (let ((result (run-sdlc-case value)))
                    (check-equal? (list (.ref value 'name) (.ref result 'status))
                                  (list (.ref value 'name) (.ref value 'expected)))
                    (check-equal? (.ref result 'compliance) 'not-evaluated)
                    (check-equal? (.ref result 'runtime-executed?) #f))) sdlc-cases))
    (test-case "derived malformed facts cannot bypass validation"
      (let ((base (car sdlc-cases)))
        (check-exception (run-sdlc-case (.o (:: @ base) project: (.o))) Error?)
        (check-exception (run-sdlc-case (.o (:: @ base) evidence: (list (.o)))) Error?)
        (check-exception (sdlc-project "p" "r" "scope" 'complete) Error?)))))
