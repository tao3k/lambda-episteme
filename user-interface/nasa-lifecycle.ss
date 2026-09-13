;;; Independent UI exercise. The host supplies its verifier and clock.
;;; No example callback silently approves content or authority signatures.
(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-review
        :lambda-episteme/modules/sdlc/standards/nasa-lifecycle)
(export nasa-lifecycle-example)
(def (nasa-lifecycle-example artifact-digest)
  (let* ((project (sdlc-project "example-flight" "baseline-1" "flight-software" #t))
         (context (.o safety-critical?: #f health-medical?: #f))
         (evidence (list (nasa-verifiable-evidence
                          (nasa-criterion-evidence "plan-review" project "SWE-013" "SWE-013/p1" "example-reviewer" 'pass)
                          artifact-digest)))
         (policies (list (nasa-stage-policy "planning" '("SWE-013"))
                         (nasa-stage-policy "planning-review" '("SWE-013")))))
    (.o verification-requests: (cons (nasa-context-request project 'a context)
                                    (map nasa-evidence-request evidence))
        evaluate:
        (lambda (adapter receipts now)
          (let* ((first (nasa-transition (nasa-lifecycle-start project) policies "planning"
                                        project 'a context evidence adapter receipts now))
                 (second (and (.ref first 'advanced?)
                              (nasa-transition (.ref first 'state) policies "planning-review"
                                               project 'a context evidence adapter receipts now))))
            (.o planning: first planning-review: second release-authorized?: #f))))))
