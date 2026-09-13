;;; Standalone, reusable user scenarios in the package's single build graph.
(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/load
        :lambda-episteme/modules/sdlc/config
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/review)
(export user-sdlc-profile sdlc-cases run-sdlc-case)
(def selected
  (sdlc-config (caar (poo-flow-modules! :custom (sdlc "../modules/sdlc" +nasa-7150-2d)))))
(def team-standard
  (.o (:: @ StandardProfile.) identity: "team/release-v1" edition: "1"
      source-url: "user-interface/README.org#team-release-policy"
      requirements: (list (.o identity: "RELEASE-REVIEW"))))
(def user-sdlc-profile
  (sdlc-with-standards (.ref selected 'profile)
    (append (.ref (.ref selected 'profile) 'standards) (list team-standard))))
(def project (sdlc-project "flight-planner" "r2" "release-inputs" #t))
(def obligation (sdlc-obligation "nasa/npr-7150.2d" "SWE-034" 'applicable))
(def (evidence id revision outcome)
  (sdlc-evidence id "flight-planner" revision "release-inputs"
                 "nasa/npr-7150.2d" "SWE-034" "review-team" outcome))
(def (scenario name-value project-value obligation-value evidence-values requests-value expected-value)
  (.o name: name-value project: project-value obligation: obligation-value
      evidence: evidence-values requests: requests-value expected: expected-value))
(def sdlc-cases
  (list
    (scenario 'missing project obligation '() '() 'missing-evidence)
    (scenario 'incomplete (.o (:: @ project) complete?: #f) obligation '() '() 'unknown)
    (scenario 'baseline-change project obligation (list (evidence "old" "r1" 'pass)) '() 'stale-evidence)
    (scenario 'current project obligation (list (evidence "current" "r2" 'pass)) '() 'evidence-present)
    (scenario 'conflicting-evidence project obligation
              (list (evidence "pass" "r2" 'pass) (evidence "fail" "r2" 'fail)) '() 'reported-failure)
    (scenario 'wrong-subject project obligation
              (list (.o (:: @ (evidence "foreign" "r2" 'pass)) subject: "another-project")) '() 'missing-evidence)
    (scenario 'wrong-scope project obligation
              (list (.o (:: @ (evidence "foreign-scope" "r2" 'pass)) scope: "unrelated")) '() 'missing-evidence)
    (scenario 'unknown-applicability project
              (.o (:: @ obligation) applicability: 'unknown) '() '() 'applicability-review-required)
    (scenario 'claimed-exemption project
              (.o (:: @ obligation) applicability: 'not-applicable) '() '() 'applicability-review-required)
    (scenario 'unapproved-tailoring project obligation (list (evidence "ready" "r2" 'pass))
              (list (sdlc-tailoring-request "flight-planner" "r2" "nasa/npr-7150.2d" "SWE-034" "alternate review"))
              'tailoring-review-required)
    (scenario 'unmapped-clause project (.o (:: @ obligation) requirement: "SWE-999") '() '() 'unmapped-obligation)
    (scenario 'other-standard project (sdlc-obligation "team/release-v1" "RELEASE-REVIEW" 'applicable)
              (list (sdlc-evidence "team-review" "flight-planner" "r2" "release-inputs"
                                   "team/release-v1" "RELEASE-REVIEW" "maintainer" 'pass))
              '() 'evidence-present)))
(def (run-sdlc-case value)
  (sdlc-review user-sdlc-profile (.ref value 'project) (.ref value 'obligation)
               (.ref value 'evidence) (.ref value 'requests)))
