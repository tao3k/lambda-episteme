(import (only-in :poo-flow/src/modules/governance/funs
                 poo-flow-governance-contribution)
        :poo-flow/lambda-episteme/modules/decision-kind/types
        :poo-flow/lambda-episteme/modules/decision-kind/objects)
(export decision-kind-contribution decision-kind-module)
(def (decision-kind-contribution profile)
  (unless (decision-kind-profile? profile) (error "invalid decision-kind profile"))
  (poo-flow-governance-contribution
   profile '(knowledge-governance) '()))
(def decision-kind-module (decision-kind-contribution DecisionKindProfile))
