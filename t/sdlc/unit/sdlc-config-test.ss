(import :poo-flow/src/module-system/contribution/testing)
(import :std/test :std/error
        :poo-flow/src/module-system/load
        :poo-flow/src/module-system/declaration/interface
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/sdlc/config)
(def (selected . flags)
  (sdlc-config (poo-flow-user-module-selection 'custom 'sdlc flags)))
(export sdlc-config-test)
(def sdlc-config-test
  (test-suite "SDLC init selection projection"
    (test-case "existing custom module syntax selects the standard"
      (let* ((bundles (poo-flow-modules!
                       :custom (sdlc @ "../lambda-episteme/modules/sdlc" +nasa-7150-2d)))
             (selection (caar bundles))
             (contribution (sdlc-config selection))
             (standards (.ref (.ref contribution 'profile) 'standards)))
        (check-equal? (poo-flow-user-module-selection-entrypoint selection)
                      "../lambda-episteme/modules/sdlc/interface.ss")
        (check-equal? (map (lambda (s) (.ref s 'identity)) standards) '("nasa/npr-7150.2d"))
        (check-equal? (.ref (admit-contributions (list contribution) '()) 'accepted?) #t)))
    (test-case "no feature means no NASA selection"
      (check-equal? (.ref (.ref (selected) 'profile) 'standards) '()))
    (test-case "unsupported features and unrelated modules are rejected"
      (check-exception (selected '+nasa-7150-2c) Error?)
      (check-exception (selected '+nasa-7150-2d '+nasa-7150-2d) Error?)
      (check-exception (sdlc-config (poo-flow-user-module-selection 'custom 'other '())) Error?))))
