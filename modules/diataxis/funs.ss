(import :poo-flow/lambda-episteme/governance/objects
        :poo-flow/lambda-episteme/modules/diataxis/types
        :poo-flow/lambda-episteme/modules/diataxis/objects)
(export diataxis-contribution diataxis-module)
(def (diataxis-contribution profile)
  (unless (diataxis-profile? profile) (error "invalid diataxis profile"))
  (governance-module profile))
(def diataxis-module (diataxis-contribution DiataxisProfile))
