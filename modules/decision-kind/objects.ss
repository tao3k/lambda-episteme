(import :poo-flow/src/module-system/contribution/interface
        (only-in :poo-flow/src/modules/governance/objects
                 PooFlowGovernanceProfile.
                 poo-flow-governance-source))
(export DecisionKindProfile)
(def DecisionKindProfile
  (.o (:: @ PooFlowGovernanceProfile.)
      identity: "lambda-episteme/decision-kind"
      revision: "1" owner: "lambda-episteme"
      module-family: 'decision-kind
      ontology: (.o document-label: 'Document decision-label: 'Decision
                    documents-edge: 'DOCUMENTS)
      policies: (.o conflict:
                    (.o requires-modules: '("lambda-episteme/diataxis" "lambda-episteme/adr")
                        protected-facet: 'decision-contract
                        conflicting-kinds: '("tutorial" "explanation")
                        severity: 'error
                        repair: 'review-kind-preserve-decision))
      source-assets:
      (list (poo-flow-governance-source
             "decision-kind/witnesses"
             "modules/decision-kind/witnesses.gql" 'gql))))
