(import :poo-flow/src/module-system/declaration/interface
        :lambda-episteme/modules/diataxis/funs)
(export diataxis-config)
(def (diataxis-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection) '(custom . diataxis))
               (null? (poo-flow-user-module-selection-flags selection)))
    (error "invalid diataxis module selection"))
  diataxis-module)
