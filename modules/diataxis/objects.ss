(import :poo-flow/src/module-system/contribution/interface
        (only-in :poo-flow/src/modules/governance/objects
                 PooFlowGovernanceProfile.
                 poo-flow-governance-source))
(export DiataxisProfile)
(def diataxis-ontology
  (.o document-label: 'Document kind-property: 'kind identity-property: 'id))
(def diataxis-source-assets
  (list (poo-flow-governance-source
         "diataxis/document-kinds"
         "modules/diataxis/document-kinds.gql" 'gql)))
(def DiataxisProfile
  (.o (:: @ PooFlowGovernanceProfile.) identity: "lambda-episteme/diataxis"
      revision: "1" owner: "lambda-episteme"
      module-family: 'diataxis
      ontology: diataxis-ontology
      policies: (.o document-kind:
                    (.o allowed: '("tutorial" "how-to" "explanation" "reference")
                        severity: 'warning
                        missing-fact: 'unknown
                        repair: 'proposal-only))
      source-assets: diataxis-source-assets))
