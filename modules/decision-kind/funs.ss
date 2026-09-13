(import :lambda-episteme/governance/objects
        :lambda-episteme/modules/decision-kind/types
        :lambda-episteme/modules/decision-kind/objects)
(export decision-kind-contribution decision-kind-module)
(def (decision-kind-contribution profile)
  (unless (decision-kind-profile? profile) (error "invalid decision-kind profile"))
  (governance-module profile))
(def decision-kind-module (decision-kind-contribution DecisionKindProfile))
