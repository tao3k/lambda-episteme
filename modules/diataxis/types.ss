(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/governance/objects)
(export diataxis-profile?)
(def (diataxis-profile? value)
  (and (governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'diataxis)))
