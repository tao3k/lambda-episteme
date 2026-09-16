(import :poo-flow/src/module-system/contribution/interface
        (only-in :poo-flow/src/modules/governance/objects
                 PooFlowGovernanceProfile.
                 poo-flow-governance-source))
(export AdrProfile)
(def AdrProfile
  (.o (:: @ PooFlowGovernanceProfile.) identity: "lambda-episteme/adr"
      revision: "1" owner: "lambda-episteme"
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
      (list (poo-flow-governance-source
             "adr/expired-reference-witnesses"
             "modules/adr/expired-references.gql" 'gql))))
