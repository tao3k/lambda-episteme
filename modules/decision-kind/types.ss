(import :poo-flow/src/module-system/contribution/interface
        (only-in :poo-flow/src/modules/governance/types
                 poo-flow-governance-profile?))
(export decision-kind-profile?)
(def (decision-kind-profile? value)
  (and (poo-flow-governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'decision-kind)))
