(import :poo-flow/src/module-system/declaration/interface
        :lambda-episteme/modules/decision-kind/funs)
(export decision-kind-config)
(def (decision-kind-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection) '(custom . decision-kind))
               (null? (poo-flow-user-module-selection-flags selection)))
    (error "invalid decision-kind module selection"))
  decision-kind-module)
