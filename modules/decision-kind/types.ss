(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/governance/objects)
(export decision-kind-profile?)
(def (decision-kind-profile? value)
  (and (governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'decision-kind)))
