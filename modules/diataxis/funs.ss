(import (only-in :poo-flow/src/modules/governance/funs
                 poo-flow-governance-contribution)
        :poo-flow/lambda-episteme/modules/diataxis/types
        :poo-flow/lambda-episteme/modules/diataxis/objects)
(export diataxis-contribution diataxis-module)
(def (diataxis-contribution profile)
  (unless (diataxis-profile? profile) (error "invalid diataxis profile"))
  (poo-flow-governance-contribution
   profile '(knowledge-governance) '()))
(def diataxis-module (diataxis-contribution DiataxisProfile))
