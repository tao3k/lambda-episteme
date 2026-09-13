;;; User-owned review assembly. No release is authorized by this source report.
(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        (only-in :std/srfi/1 filter))
(export nasa-release-review)
(def (nasa-release-review class-value project context nodes edges)
  (let* ((applicability-values (nasa-project-obligations class-value context))
         (traces (map (lambda (rule) (sdlc-trace-review project rule nodes edges))
                      (nasa-trace-rules class-value)))
         (pending (filter (lambda (a)
                            (memq (.ref a 'status) '(institutional-review-required context-review-required)))
                          applicability-values)))
    (.o kind: 'sdlc.release-review subject: (.ref project 'subject)
        revision: (.ref project 'revision) software-class: class-value
        applicability: applicability-values traceability: traces pending-context: pending
        release-authorized?: #f compliance: 'not-evaluated runtime-executed?: #f)))
