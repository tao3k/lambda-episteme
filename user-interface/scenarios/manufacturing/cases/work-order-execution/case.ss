;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :yuanxu/graph/types
                  graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-node)
         (graph Graph))
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/manufacturing/profiles/base
                 ManufacturingBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/manufacturing/scenario
                 ManufacturingScenario))

(export WorkOrderExecutionCase)

(.def (WorkOrderExecutionCase @ OntologyCase)
  (case-id 'work-order-execution)
  (scenario ManufacturingScenario)
  (profile-selection =>.+
   (.o manufacturing:
       (.o evidence: EvidenceProfile
           base: ManufacturingBaseProfile)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'work-order-execution
       node-declarations:
       (.o machine-1: (agentic-ai-lab-graph-node 'machine-1 'Machine)
           work-order-1: (agentic-ai-lab-graph-node 'work-order-1 'WorkOrder)
           part-1: (agentic-ai-lab-graph-node 'part-1 'Part))
       edge-declarations:
       (.o machine-executes-work-order:
           (agentic-ai-lab-graph-edge
            'machine-1 'work-order-1 'executesWorkOrder)
           work-order-consumes-part:
           (agentic-ai-lab-graph-edge 'work-order-1 'part-1 'consumesPart)))))
