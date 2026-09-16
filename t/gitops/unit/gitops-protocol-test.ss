(import :std/test
        (only-in :clan/poo/object .cc .ref)
        (only-in :clan/poo/mop element?)
        :poo-flow/src/module-system/poo-clos/interface
        :poo-flow/lambda-episteme/modules/gitops/interface)
(export gitops-protocol-test)

(.defclass TestGitOpsEvaluator (GitOpsEvaluator) ())
(def TestGitOpsMethod
  (poo-clos-method
   'gitops/test-evaluation
   (list (poo-clos-class-specializer TestGitOpsEvaluator)
         (poo-clos-any-specializer) (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _evaluator _composition _change _checks)
     'specialized-evaluation)))
(.defmethod-bundle TestGitOpsMethods GitOpsEvaluationProtocol TestGitOpsMethod)
(define-gitops-profile test-dev OpenGitOpsV1Profile
  environment: 'dev event: 'pull-request target-ref: "develop"
  required-checks: '(build test)
  reconciliation: 'automatic next-profile: 'staging)
(define-gitops-profile base-dev OpenGitOpsV1Profile
  environment: 'dev event: 'pull-request target-ref: "develop"
  required-checks: '(build)
  reconciliation: 'automatic next-profile: 'staging)

(def gitops-protocol-test
  (test-suite "GitOps native dispatch closure"
    (test-case "POO prototype validates a declarative Profile"
      (check-equal? (gitops-profile? test-dev) #t)
      (check-equal?
       (gitops-profile-matches?
        test-dev (gitops-change 'github 'pull-request "owner/repo" "sha"
                                "feature/x" "develop" 7))
       #t))
    (test-case "slot dispatch remains open to profile refinement"
      (let (refined (.cc base-dev '.matches? (lambda (_change) #t)))
        (check-equal?
         (gitops-profile-matches?
          refined (gitops-change 'github 'push "owner/repo" "sha"
                                 "other" "other" #f))
         #t)))
    (test-case "CLOS class specialization composes through a checked bundle"
      (let ((generic (poo-clos-generic-function
                      'gitops/test-generic 4
                      protocol: GitOpsEvaluationProtocol))
            (evaluator (poo-clos-make-instance TestGitOpsEvaluator)))
        (poo-clos-compose-method-bundle generic TestGitOpsMethods)
        (check-equal? (element? ClosMethodBundle TestGitOpsMethods) #t)
        (check-equal? (poo-clos-call generic evaluator #f #f '())
                      'specialized-evaluation)))))
