(import :std/test
        (only-in :clan/poo/object .ref)
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/lambda-episteme/user-interface/config
        :poo-flow/lambda-episteme/user-interface/scenarios/github-gitops)
(export github-workflow-test)

(def repository "tao3k/poo-flow")
(def revision "0123456789abcdef")
(def (successful-checks names (at-revision revision))
  (map (lambda (name) (github-check name repository at-revision 'success)) names))
(def dev-checks '(commit-policy build unit-test nasa-7150-2d))
(def (run-github-gitops change checks)
  (github-run-gitops github-gitops-sdlc change checks))

(def github-workflow-test
  (test-suite "GitHub GitOps SDLC lifecycle"
    (test-case "Dev Staging Production are GitOps Profiles; NASA is one Standard"
      (check-equal? (poo-flow-composition-name github-gitops-sdlc)
                    'github-gitops-sdlc)
      (check-equal? (map (lambda (profile) (.ref profile 'name))
                         (poo-flow-composition-profiles github-gitops-sdlc))
                    '(actions dev staging production nasa-7150-2d))
      (check-equal? (map (lambda (standard) (.ref standard 'identity))
                         (.ref nasa-7150-2d 'standards))
                    '("nasa/npr-7150.2d")))
    (test-case "PR into develop advances Dev only with current checks and Standard assessment"
      (let* ((change (github-change 'pull-request repository revision
                                    "feature/gitops" "develop" 42))
             (decision (run-github-gitops change (successful-checks dev-checks))))
        (check-equal? (.ref decision 'profile) 'dev)
        (check-equal? (.ref decision 'environment) 'dev)
        (check-equal? (.ref decision 'accepted) #t)
        (check-equal? (.ref decision 'next-profile) 'staging)
        (check-equal? (.ref decision 'standards) '(nasa-7150-2d))))
    (test-case "missing NASA assessment fails closed"
      (let (decision
            (run-github-gitops
             (github-change 'pull-request repository revision
                            "feature/gitops" "develop" 42)
             (successful-checks '(commit-policy build unit-test))))
        (check-equal? (.ref decision 'accepted) #f)
        (check-equal? (.ref decision 'missing-checks) '(nasa-7150-2d))))
    (test-case "checks for another Git revision cannot authorize promotion"
      (let (decision
            (run-github-gitops
             (github-change 'pull-request repository revision
                            "feature/gitops" "develop" 42)
             (successful-checks dev-checks "previous-revision")))
        (check-equal? (.ref decision 'accepted) #f)
        (check-equal? (.ref decision 'stale-checks) dev-checks)))
    (test-case "merge and protected release select different Profiles"
      (let* ((staging-decision
              (run-github-gitops
               (github-change 'push repository revision "develop" "develop" #f)
               (successful-checks
                '(integration-test security-review nasa-7150-2d))))
             (production-decision
              (run-github-gitops
               (github-change 'workflow-dispatch repository revision
                              "develop" "production" #f)
               (successful-checks
                '(release-authority signed-provenance nasa-7150-2d)))))
        (check-equal? (.ref staging-decision 'profile) 'staging)
        (check-equal? (.ref staging-decision 'next-profile) 'production)
        (check-equal? (.ref production-decision 'profile) 'production)
        (check-equal? (.ref production-decision 'environment) 'production)
        (check-equal? (.ref production-decision 'next-profile) 'complete)))
    (test-case "unrelated Git changes do not enter an environment Profile"
      (let (decision
            (run-github-gitops
             (github-change 'push repository revision "feature/x" "feature/x" #f)
             '()))
        (check-equal? (.ref decision 'profile) 'unmatched)
        (check-equal? (.ref decision 'reasons)
                      '(no-gitops-profile-matches-change))))))
