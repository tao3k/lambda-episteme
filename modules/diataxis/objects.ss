(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/governance/objects)
(export DiataxisProfile)
(def diataxis-ontology
  (.o document-label: 'Document kind-property: 'kind identity-property: 'id))
(def diataxis-source-assets
  (list (source-asset "diataxis/document-kinds"
                      "modules/diataxis/document-kinds.gql" 'gql)))
(def DiataxisProfile
  (.o (:: @ GovernanceProfile.) identity: "lambda-episteme/diataxis"
      module-family: 'diataxis
      ontology: diataxis-ontology
      policies: (.o document-kind:
                    (.o allowed: '("tutorial" "how-to" "explanation" "reference")
                        severity: 'warning
                        missing-fact: 'unknown
                        repair: 'proposal-only))
      source-assets: diataxis-source-assets))
