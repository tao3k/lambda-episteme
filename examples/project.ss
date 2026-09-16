(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/diataxis/interface
        :poo-flow/lambda-episteme/modules/adr/interface
        :poo-flow/lambda-episteme/modules/decision-kind/interface)
(export project-composition ProjectDiataxisProfile)
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
      (profile project-diaclass) (profile adr-module))
    (compose (profiles policy project-diaclass adr-module))))
