(import :poo-flow/src/module-system/declaration/interface
        :lambda-episteme/modules/adr/funs)
(export adr-config)
(def (adr-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection) '(custom . adr))
               (null? (poo-flow-user-module-selection-flags selection)))
    (error "invalid adr module selection"))
  adr-module)
