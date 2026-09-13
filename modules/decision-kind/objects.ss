(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/governance/objects)
(export DecisionKindProfile)
(def DecisionKindProfile
  (.o (:: @ GovernanceProfile.) identity: "lambda-episteme/decision-kind"
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
      (list (source-asset "decision-kind/witnesses"
                          "modules/decision-kind/witnesses.gql" 'gql))))
