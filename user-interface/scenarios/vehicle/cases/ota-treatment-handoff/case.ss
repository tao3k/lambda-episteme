;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :yuanxu/graph/types
                  graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-node)
         (graph Graph))
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyCase ontology-source)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/vehicle/profiles/base
                 VehicleBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/vehicle/profiles/tara-treatment
                 VehicleTaraTreatmentProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/vehicle/scenario
                 VehicleScenario))

(export VehicleOtaTreatmentHandoffCase)

(.def (VehicleOtaTreatmentHandoffCase @ OntologyCase)
  (case-id 'vehicle-ota-treatment-handoff)
  (scenario VehicleScenario)
  (assessment-reference
   (.o source: "example-tara"
       exchange-model: "ASRG/openXSAM"
       work-product-id: "EXAMPLE-TARA-OTA-001"
       revision: "example-1"
       approval-reference: #f))
  (treatment-goal-id "EXAMPLE-OTA-MANIFEST-INTAKE-GOAL")
  (profile-selection =>.+
   (.o vehicle:
       (.o evidence: EvidenceProfile
           base: VehicleBaseProfile
           tara-treatment: VehicleTaraTreatmentProfile)))
  (source-declarations =>.+
   (.o example-handoff:
       (ontology-source
        "vehicle/ota-treatment-handoff/example"
        "user-interface/scenarios/vehicle/cases/ota-treatment-handoff/source.org"
        'org 'case 'vehicle 'vehicle-ota-treatment-handoff)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'vehicle-ota-treatment-handoff
       node-declarations:
       (.o assessment:
           (agentic-ai-lab-graph-node 'assessment 'ExternalTaraAssessment)
           treatment-goal:
           (agentic-ai-lab-graph-node 'treatment-goal 'VehicleTreatmentGoal)
           policy-candidate:
           (agentic-ai-lab-graph-node 'policy-candidate 'VehiclePolicyCandidate)
           software-release:
           (agentic-ai-lab-graph-node 'software-release 'VehicleSoftwareRelease)
           vehicle-fleet:
           (agentic-ai-lab-graph-node 'vehicle-fleet 'VehicleFleet))
       edge-declarations:
       (.o assessment-origin:
           (agentic-ai-lab-graph-edge
            'treatment-goal 'assessment 'sourcedFromAssessment)
           executable-treatment:
           (agentic-ai-lab-graph-edge
            'treatment-goal 'policy-candidate 'realizedByPolicy)
           release-target:
           (agentic-ai-lab-graph-edge
            'policy-candidate 'software-release 'governsRelease)))))
