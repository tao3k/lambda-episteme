(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/sdlc/interface
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d)
(def ProjectSdlcProfile (sdlc-with-standards SdlcProfile (list Nasa7150_2D)))
(def project-sdlc-module (sdlc-contribution ProjectSdlcProfile))
(export sdlc-test)
(def sdlc-test
  (test-suite "SDLC source composition, without parsers or execution backends"
    (test-case "SDLC is usable without a standard or backend"
      (check-equal? (.ref SdlcProfile 'standards) '())
      (check-equal? (.ref sdlc-module 'requires) '())
      (check-equal? (.ref (admit-contributions (list sdlc-module) '()) 'accepted?) #t))
    (test-case "NASA is explicit and leaves the original profile unchanged"
      (check-equal? (standard-profile? Nasa7150_2D) #t)
      (check-equal? (length (.ref ProjectSdlcProfile 'standards)) 1)
      (check-equal? (.ref SdlcProfile 'standards) '())
      (check-equal? (.ref Nasa7150_2D 'coverage) 'partial)
      (check-equal? (.ref Nasa7150_2D 'assessment) 'not-evaluated))
    (test-case "clause references preserve edition and source location"
      (let ((clause (nasa-requirement-by-id "SWE-013")))
        (check-equal? (.ref clause 'identity) "SWE-013")
        (check-equal? (.ref clause 'standard) "nasa/npr-7150.2d")
        (check-equal? (.ref clause 'section) "3.1.3")
        (check-equal? (.ref clause 'topic) 'lifecycle-planning)))
    (test-case "other standards compose without changing SDLC or NASA"
      (let* ((local (.o (:: @ StandardProfile.) identity: "example/standard"
                       edition: "1" source-url: "https://example.org/standard"))
             (selected (sdlc-with-standards SdlcProfile (list Nasa7150_2D local))))
        (check-equal? (length (.ref selected 'standards)) 2)))
    (test-case "ambiguous and malformed selections fail"
      (check-exception (sdlc-with-standards SdlcProfile (list Nasa7150_2D Nasa7150_2D)) Error?)
      (check-exception (sdlc-with-standards SdlcProfile (list (.o))) Error?)
      (check-exception (sdlc-with-standards SdlcProfile (list (.o (:: @ Nasa7150_2D) assessment: 'passed))) Error?))
    (test-case "source admission never claims runtime execution"
      (check-equal? (.ref (admit-contributions (list project-sdlc-module) '()) 'runtime-executed?) #f))))
