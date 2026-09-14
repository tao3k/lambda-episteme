(import :poo-flow/lambda-episteme/governance/objects
        :poo-flow/lambda-episteme/modules/adr/types
        :poo-flow/lambda-episteme/modules/adr/objects)
(export adr-contribution adr-module)
(def (adr-contribution profile)
  (unless (adr-profile? profile) (error "invalid adr profile"))
  (governance-module profile))
(def adr-module (adr-contribution AdrProfile))
