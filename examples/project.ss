(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/governance/interface
        :lambda-episteme/modules/diataxis/interface
        :lambda-episteme/modules/adr/interface
        :lambda-episteme/modules/decision-kind/interface)
(export project-composition ProjectDiataxisProfile)
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
