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
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/healing
                 HealingProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization
                 healthcare-medication-administration))

(export PostOperativeHealingCase)

(.def (PostOperativeHealingCase @ OntologyCase)
  (case-id 'post-operative-healing)
  (scenario HealthcareScenario)
  (.use-composition
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile
           healing: HealingProfile)
       medication:
       (.o medication-safety: MedicationSafetyProfile)))
  (.add-authorization
   (.o medication-administration:
       (healthcare-medication-administration
        "provider-1" "patient-1" "encounter-1" "medication-order-1"
        #t #f)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'post-operative-healing
       .add-node:
       (.o patient-1: (poo-flow-graph-node 'patient-1 'Patient)
           provider-1: (poo-flow-graph-node 'provider-1 'Provider)
           encounter-1: (poo-flow-graph-node 'encounter-1 'Encounter)
           condition-1: (poo-flow-graph-node 'condition-1 'Condition)
           healing-episode-1:
           (poo-flow-graph-node 'healing-episode-1 'HealingEpisode)
           recovery-milestone-1:
           (poo-flow-graph-node 'recovery-milestone-1 'RecoveryMilestone)
           medication-order-1:
           (poo-flow-graph-node 'medication-order-1 'MedicationOrder))
       .add-edge:
       (.o encounter-patient:
           (poo-flow-graph-edge 'encounter-1 'patient-1 'HAS_PATIENT)
           encounter-provider:
           (poo-flow-graph-edge 'encounter-1 'provider-1 'HAS_PROVIDER)
           encounter-condition:
           (poo-flow-graph-edge 'encounter-1 'condition-1 'HAS_CONDITION)
           episode-recovers-from:
           (poo-flow-graph-edge
            'healing-episode-1 'condition-1 'RECOVERS_FROM)
           episode-reaches-milestone:
           (poo-flow-graph-edge
            'healing-episode-1 'recovery-milestone-1
            'REACHES_MILESTONE)
           order-patient:
           (poo-flow-graph-edge
            'medication-order-1 'patient-1 'ORDER_FOR_PATIENT)
           order-provider:
           (poo-flow-graph-edge
            'medication-order-1 'provider-1 'ASSIGNED_PROVIDER)))))
