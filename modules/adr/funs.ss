(import :lambda-episteme/governance/objects
        :lambda-episteme/modules/adr/types
        :lambda-episteme/modules/adr/objects)
(export adr-contribution adr-module)
(def (adr-contribution profile)
  (unless (adr-profile? profile) (error "invalid adr profile"))
  (governance-module profile))
(def adr-module (adr-contribution AdrProfile))
