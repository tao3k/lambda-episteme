(import :std/test
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/contribution/verification
        :lambda-episteme/modules/sdlc/standards/nasa-lifecycle
        :lambda-episteme/user-interface/nasa-lifecycle)
(export nasa-lifecycle-test)
(def nasa-lifecycle-test
  (test-suite "Independent verified lifecycle UI"
  (test-case "host supplies verification; pending, admitted and expired remain distinct"
    (let* ((example (nasa-lifecycle-example (make-string 64 #\a)))
           (requests (.ref example 'verification-requests))
           ;; Test fixture permits these exact request objects only.
           (adapter (nasa-verification-adapter "ui-test-only"
                      (lambda (request now until) (and (memq request requests) (= now 0) (= until 10) #t))))
           (evaluate (.ref example 'evaluate))
           (pending (evaluate adapter '() 1))
           (receipts (map (lambda (r) (poo-flow-verify adapter r 0 10)) requests))
           (admitted (evaluate adapter receipts 1))
           (expired (evaluate adapter receipts 10)))
      (check-equal? (.ref (.ref pending 'planning) 'advanced?) #f)
      (check-equal? (.ref pending 'planning-review) #f)
      (check-equal? (.ref (.ref admitted 'planning-review) 'advanced?) #t)
      (check-equal? (.ref admitted 'release-authorized?) #f)
      (check-equal? (.ref (.ref expired 'planning) 'advanced?) #f)))))
