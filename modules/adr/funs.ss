(import (only-in :poo-flow/src/modules/governance/funs
                 poo-flow-governance-contribution)
        :poo-flow/lambda-episteme/modules/adr/types
        :poo-flow/lambda-episteme/modules/adr/objects)
(export adr-contribution adr-module)
(def (adr-contribution profile)
  (unless (adr-profile? profile) (error "invalid adr profile"))
  (poo-flow-governance-contribution
   profile '(knowledge-governance) '()))
(def adr-module (adr-contribution AdrProfile))
