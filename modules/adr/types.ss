(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/governance/objects)
(export adr-profile?)
(def (adr-profile? value)
  (and (governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'adr)))
