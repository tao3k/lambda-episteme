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
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/profiles/healing
                 HealingProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/authorization
                 healthcare-medication-administration))

(export PostOperativeHealingCase)

(.def (PostOperativeHealingCase @ OntologyCase)
  (case-id 'post-operative-healing)
  (scenario HealthcareScenario)
  (medication-reconciliation-observed? #t)
  (profile-selection =>.+
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile
           healing: HealingProfile)
       medication:
       (.o medication-safety: MedicationSafetyProfile)))
  (authorization-declarations =>.+
   (.o medication-administration:
       (healthcare-medication-administration
        "provider-1" "patient-1" "encounter-1" "medication-order-1"
        #t #f)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'post-operative-healing
       node-declarations:
       (.o patient-1: (agentic-ai-lab-graph-node 'patient-1 'Patient)
           provider-1: (agentic-ai-lab-graph-node 'provider-1 'Provider)
           encounter-1: (agentic-ai-lab-graph-node 'encounter-1 'Encounter)
           condition-1: (agentic-ai-lab-graph-node 'condition-1 'Condition)
           healing-episode-1:
           (agentic-ai-lab-graph-node 'healing-episode-1 'HealingEpisode)
           recovery-milestone-1:
           (agentic-ai-lab-graph-node 'recovery-milestone-1 'RecoveryMilestone)
           medication-order-1:
           (agentic-ai-lab-graph-node 'medication-order-1 'MedicationOrder))
       edge-declarations:
       (.o encounter-patient:
           (agentic-ai-lab-graph-edge 'encounter-1 'patient-1 'HAS_PATIENT)
           encounter-provider:
           (agentic-ai-lab-graph-edge 'encounter-1 'provider-1 'HAS_PROVIDER)
           encounter-condition:
           (agentic-ai-lab-graph-edge 'encounter-1 'condition-1 'HAS_CONDITION)
           episode-recovers-from:
           (agentic-ai-lab-graph-edge
            'healing-episode-1 'condition-1 'RECOVERS_FROM)
           episode-reaches-milestone:
           (agentic-ai-lab-graph-edge
            'healing-episode-1 'recovery-milestone-1
            'REACHES_MILESTONE)
           order-patient:
           (agentic-ai-lab-graph-edge
            'medication-order-1 'patient-1 'ORDER_FOR_PATIENT)
           order-provider:
           (agentic-ai-lab-graph-edge
            'medication-order-1 'provider-1 'ASSIGNED_PROVIDER)))))
