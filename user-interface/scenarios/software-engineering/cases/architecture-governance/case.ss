;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :poo-flow/src/graph/types
                  graph poo-flow-graph-edge poo-flow-graph-node)
         (graph Graph))
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/software-engineering/profiles/base
                 SoftwareEngineeringBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/software-engineering/scenario
                 SoftwareEngineeringScenario))

(export ArchitectureGovernanceCase)

(.def (ArchitectureGovernanceCase @ OntologyCase)
  (case-id 'architecture-governance)
  (scenario SoftwareEngineeringScenario)
  (profile-selection =>.+
   (.o software-engineering:
       (.o evidence: EvidenceProfile
           base: SoftwareEngineeringBaseProfile)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'architecture-governance
       node-declarations:
       (.o component-api:
           (poo-flow-graph-node 'component-api 'SoftwareComponent)
           component-domain:
           (poo-flow-graph-node 'component-domain 'SoftwareComponent)
           decision-1:
           (poo-flow-graph-node 'decision-1 'DecisionRecord)
           implementation-1:
           (poo-flow-graph-node
            'implementation-1 'ImplementationArtifact))
       edge-declarations:
       (.o api-depends-on-domain:
           (poo-flow-graph-edge 'component-api 'component-domain 'dependsOn)
           implementation-links-decision:
           (poo-flow-graph-edge
            'implementation-1 'decision-1 'implementsDecision)))))
