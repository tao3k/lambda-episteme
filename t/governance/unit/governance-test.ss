(import :std/test
        (only-in :clan/poo/object .o .ref)
        :core/contribution/objects
        (only-in :core/profile-composition/profile-bundle compose profiles)
        (only-in :agentic-ai-lab/modules/workflow/scenario/accessors
                 agentic-ai-lab-scenario-case-profiles)
        (only-in :core/module-system/selection/objects
                 agentic-ai-lab-user-module-selection)
        (only-in :agentic-ai-lab/modules/workflow/scenario/composition-syntax user-composition)
        :agentic-ai-lab/modules/governance/interface
        :agentic-ai-lab/lambda-episteme/modules/diataxis/interface
        :agentic-ai-lab/lambda-episteme/modules/decision-kind/interface)
(def ProjectDiataxisProfile
  (.o (:: @ DiataxisProfile)
      identity: "example/diataxis" owner: "example-project"
      policies: (.o document-kind:
                    (.o (:: @ (.ref (.ref DiataxisProfile 'policies) 'document-kind))
                        severity: 'error))))
(def project-diaclass (diataxis-contribution ProjectDiataxisProfile))
(user-composition project-composition
  (compose profiles project-diaclass decision-kind-module))

(export governance-test)
(def governance-test
  (test-suite "contributed POO source modules without execution backends"
    (test-case "native modules declare their source and policy ownership"
      (for-each (lambda (module)
                  (check-equal? (contribution? module) #t)
                  (check-equal?
                   (agentic-ai-lab-governance-profile? (.ref module 'profile)) #t))
                (list diataxis-module decision-kind-module)))
    (test-case "local derivation changes only the selected policy"
      (check-equal? (.ref (.ref (.ref ProjectDiataxisProfile 'policies) 'document-kind) 'severity) 'error)
      (check-equal? (.ref (.ref (.ref DiataxisProfile 'policies) 'document-kind) 'severity) 'warning)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'ontology) (.ref DiataxisProfile 'ontology)) #t)
      (check-equal? (eq? (.ref ProjectDiataxisProfile 'source-assets) (.ref DiataxisProfile 'source-assets)) #t))
    (test-case "composition imports source values without backend capabilities"
      (let ((receipt (admit-contributions
                      (agentic-ai-lab-scenario-case-profiles project-composition)
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
    (test-case "module config delegates exact family admission to Agentic AI Lab"
      (check-equal?
       (eq? (diataxis-config
             (agentic-ai-lab-user-module-selection 'custom 'diataxis '()))
            diataxis-module)
       #t)
      (check-equal?
       (eq? (decision-kind-config
             (agentic-ai-lab-user-module-selection 'custom 'decision-kind '()))
            decision-kind-module)
       #t)
      (check-exception
       (decision-kind-config
        (agentic-ai-lab-user-module-selection 'custom 'diataxis '()))
       true))
    (test-case "query language is an optional source facet"
      (let ((plain
             (.o (:: @ AgenticAILabGovernanceProfile.)
                 identity: "example/plain"
                 revision: "1"
                 owner: "example-project")))
        (check-equal? (agentic-ai-lab-governance-profile? plain) #t)
        (check-equal?
         (.ref
          (agentic-ai-lab-governance-contribution
           plain '(knowledge-governance) '())
          'requires)
         '())
        (check-equal? (.ref plain 'source-assets) '())))))
