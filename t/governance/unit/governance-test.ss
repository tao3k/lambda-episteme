(import :std/test
        :poo-flow/src/module-system/contribution/interface
        (only-in :poo-flow/src/module-system/profile-composition/interface
                 poo-flow-scenario-case-profiles)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-user-module-selection)
        :poo-flow/src/modules/governance/interface
        :poo-flow/lambda-episteme/modules/diataxis/interface
        :poo-flow/lambda-episteme/modules/decision-kind/interface)
(def ProjectDiataxisProfile
  (.o (:: @ DiataxisProfile)
      identity: "example/diataxis" owner: "example-project"
      policies: (.o document-kind:
                    (.o (:: @ (.ref (.ref DiataxisProfile 'policies) 'document-kind))
                        severity: 'error))))
(def project-diaclass (diataxis-contribution ProjectDiataxisProfile))
(def project-composition
  (use-composition project-composition
    (use-module governance as policy
      (profile project-diaclass) (profile decision-kind-module))
    (compose (profiles policy project-diaclass decision-kind-module))))

(export governance-test)
(def governance-test
  (test-suite "contributed POO source modules without execution backends"
    (test-case "native modules declare their source and policy ownership"
      (for-each (lambda (module)
                  (check-equal? (contribution? module) #t)
                  (check-equal?
                   (poo-flow-governance-profile? (.ref module 'profile)) #t))
                (list diataxis-module decision-kind-module)))
    (test-case "local derivation changes only the selected policy"
      (check-equal? (.ref (.ref (.ref ProjectDiataxisProfile 'policies) 'document-kind) 'severity) 'error)
      (check-equal? (.ref (.ref (.ref DiataxisProfile 'policies) 'document-kind) 'severity) 'warning)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'ontology) (.ref DiataxisProfile 'ontology)) #t)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'source-assets) (.ref DiataxisProfile 'source-assets)) #t))
    (test-case "composition imports source values without backend capabilities"
      (let ((receipt (admit-contributions
                      (poo-flow-scenario-case-profiles project-composition)
                      '())))
        (check-equal? (.ref receipt 'accepted?) #t)
        (check-equal? (.ref receipt 'runtime-executed?) #f)
        (check-equal? (length (.ref receipt 'selected)) 2)))
    (test-case "duplicate exports are not resolved by filesystem order"
      (check-equal?
       (.ref (admit-contributions
              (list decision-kind-module decision-kind-module) '())
             'accepted?)
       #f))
    (test-case "module config delegates exact family admission to POO Flow"
      (check-equal?
       (eq? (diataxis-config
             (poo-flow-user-module-selection 'custom 'diataxis '()))
            diataxis-module)
       #t)
      (check-equal?
       (eq? (decision-kind-config
             (poo-flow-user-module-selection 'custom 'decision-kind '()))
            decision-kind-module)
       #t)
      (check-exception
       (decision-kind-config
        (poo-flow-user-module-selection 'custom 'diataxis '()))
       true))
    (test-case "query language is an optional source facet"
      (let ((plain
             (.o (:: @ PooFlowGovernanceProfile.)
                 identity: "example/plain"
                 revision: "1"
                 owner: "example-project")))
        (check-equal? (poo-flow-governance-profile? plain) #t)
        (check-equal?
         (.ref
          (poo-flow-governance-contribution
           plain '(knowledge-governance) '())
          'requires)
         '())
        (check-equal? (.ref plain 'source-assets) '())))))
