(import :std/test
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/contribution/verification
        :lambda-episteme/modules/sdlc/standards/nasa-lifecycle
        :lambda-episteme/user-interface/nasa-safety-gate)
(export nasa-safety-gate-test)
(def nasa-safety-gate-test
  (test-suite "Independent safety gate UI"
    (test-case "verified reports do not override local safety thresholds"
      (for-each
       (lambda (measurements expected)
         (let* ((example (nasa-safety-gate-example (make-string 64 #\a) (car measurements) (cadr measurements)))
                (requests (.ref example 'verification-requests))
                (adapter (nasa-verification-adapter "synthetic-ui-verifier"
                           (lambda (r now until) (and (memq r requests) (= now 0) (= until 10) #t))))
                (evaluate (.ref example 'evaluate))
                (receipts (map (lambda (r) (poo-flow-verify adapter r 0 10)) requests)))
           (check-equal? (.ref (evaluate adapter '() 1) 'advanced?) #f)
           (check-equal? (.ref (evaluate adapter receipts 1) 'advanced?) expected)
           (check-equal? (.ref (evaluate adapter receipts 10) 'advanced?) #f)
           (check-equal? (.ref (evaluate adapter receipts 1) 'release-authorized?) #f)))
       '((100 15) (99 15) (100 16)) '(#t #f #f)))))
