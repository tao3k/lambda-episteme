(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/governance/objects)
(export AdrProfile)
(def AdrProfile
  (.o (:: @ GovernanceProfile.) identity: "lambda-episteme/adr"
      module-family: 'adr
      ontology: (.o decision-label: 'Decision reference-edge: 'REFERENCES
                    supersession-edge: 'SUPERSEDED_BY identity-property: 'id)
      policies: (.o lifecycle:
                    (.o allowed: '("proposed" "rejected" "accepted" "active" "deprecated" "superseded")
                        missing-replacement: 'requires-complete-scope
                        incomplete-scope: 'unknown
                        expired-reference: 'review-required
                        repair: 'proposal-only))
      source-assets:
      (list (source-asset "adr/expired-reference-witnesses"
                          "modules/adr/expired-references.gql" 'gql))))
