;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :core/graph/types
                  graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-node)
         (graph Graph))
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/software-engineering/profiles/base
                 SoftwareEngineeringBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/software-engineering/scenario
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
           (agentic-ai-lab-graph-node 'component-api 'SoftwareComponent)
           component-domain:
           (agentic-ai-lab-graph-node 'component-domain 'SoftwareComponent)
           decision-1:
           (agentic-ai-lab-graph-node 'decision-1 'DecisionRecord)
           implementation-1:
           (agentic-ai-lab-graph-node
            'implementation-1 'ImplementationArtifact))
       edge-declarations:
       (.o api-depends-on-domain:
           (agentic-ai-lab-graph-edge 'component-api 'component-domain 'dependsOn)
           implementation-links-decision:
           (agentic-ai-lab-graph-edge
            'implementation-1 'decision-1 'implementsDecision)))))
