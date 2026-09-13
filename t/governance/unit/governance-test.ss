(import :poo-flow/src/module-system/contribution/testing)
(import :std/test
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/governance/interface
        :lambda-episteme/modules/diataxis/interface
        :lambda-episteme/modules/adr/interface
        :lambda-episteme/modules/decision-kind/interface)
(def ProjectDiataxisProfile
  (.o (:: @ DiataxisProfile)
      identity: "example/diataxis" owner: "example-project"
      policies: (.o document-kind:
                    (.o (:: @ (.ref (.ref DiataxisProfile 'policies) 'document-kind))
                        severity: 'error))))
(def project-diaclass (governance-module ProjectDiataxisProfile))
(def project-composition
  (use-composition project-composition
    (use-module governance as policy
      (profile project-diaclass) (profile adr-module))
    (compose (profiles policy project-diaclass adr-module))))

(export governance-test)
(def governance-test
  (test-suite "contributed POO source modules without execution backends"
    (test-case "native modules declare their source and policy ownership"
      (for-each (lambda (module)
                  (check-equal? (contribution? module) #t)
                  (check-equal? (governance-profile? (.ref module 'profile)) #t))
                (list diataxis-module adr-module decision-kind-module)))
    (test-case "local derivation changes only the selected policy"
      (check-equal? (.ref (.ref (.ref ProjectDiataxisProfile 'policies) 'document-kind) 'severity) 'error)
      (check-equal? (.ref (.ref (.ref DiataxisProfile 'policies) 'document-kind) 'severity) 'warning)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'ontology) (.ref DiataxisProfile 'ontology)) #t)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'source-assets) (.ref DiataxisProfile 'source-assets)) #t))
    (test-case "composition imports source values without backend capabilities"
      (let ((receipt (admit-contributions (poo-flow-composition-profiles project-composition) '())))
        (check-equal? (.ref receipt 'accepted?) #t)
        (check-equal? (.ref receipt 'runtime-executed?) #f)
        (check-equal? (length (.ref receipt 'selected)) 2)))
    (test-case "incomplete graphs never imply a missing-relation violation"
      (check-equal? (.ref (.ref (.ref AdrProfile 'policies) 'lifecycle) 'incomplete-scope) 'unknown))
    (test-case "duplicate exports are not resolved by filesystem order"
      (check-equal? (.ref (admit-contributions (list adr-module adr-module) '()) 'accepted?) #f))
    (test-case "query language is an optional source facet"
      (let ((plain (.o (:: @ GovernanceProfile.) identity: "example/plain")))
        (check-equal? (governance-profile? plain) #t)
        (check-equal? (.ref (governance-module plain) 'requires) '())
        (check-equal? (.ref plain 'source-assets) '())))))
