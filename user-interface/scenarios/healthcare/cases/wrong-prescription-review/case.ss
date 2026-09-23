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
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/temporal-causality
                 healthcare-clinical-event)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization
                 healthcare-medication-administration))

(export WrongPrescriptionReviewCase)

(.def (WrongPrescriptionReviewCase @ OntologyCase)
  (case-id 'wrong-prescription-review)
  (scenario HealthcareScenario)
  (medication-reconciliation-observed? #t)
  (profile-selection =>.+
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile)
       medication:
       (.o medication-safety: MedicationSafetyProfile)))
  (authorization-declarations =>.+
   (.o revoked-medication-administration:
       (healthcare-medication-administration
        "provider-1" "patient-1" "encounter-1" "medication-order-1"
        #t #t)))
  (event-declarations =>.+
   (.o prescription:
       (healthcare-clinical-event
        "patient-1" "prescription-1/rev1" 'prescription 1
        "medication-order-1/rev1" '() 'observed #t)
       administration:
       (healthcare-clinical-event
        "patient-1" "administration-1" 'medication-administration 2
        "dose-1/committed" '("prescription-1/rev1") 'observed #t)
       contraindication-observation:
       (healthcare-clinical-event
        "patient-1" "contraindication-observation-1" 'clinical-observation 3
        "evidence/contraindication-1" '("administration-1") 'observed #t)
       error-discovery:
       (healthcare-clinical-event
        "patient-1" "prescription-error-discovered-1"
        'prescription-error-discovered 4
        "review/wrong-prescription-1"
        '("contraindication-observation-1") 'observed #t)
       scheduled-administration:
       (healthcare-clinical-event
        "patient-1" "scheduled-administration-2" 'scheduled-administration 5
        "dose-2/planned" '("prescription-1/rev1") 'declared #f)
       corrected-prescription:
       (healthcare-clinical-event
        "patient-1" "corrected-prescription-1" 'corrected-prescription 5
        "prescription-1/rev2"
        '("prescription-error-discovered-1") 'counterfactual #f)
       reassessment:
       (healthcare-clinical-event
        "patient-1" "care-reassessment-1" 'care-reassessment 6
        "care-obligation/reassess-1"
        '("prescription-error-discovered-1") 'declared #f)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'wrong-prescription-review
       node-declarations:
       (.o patient-1: (poo-flow-graph-node 'patient-1 'Patient)
           provider-1: (poo-flow-graph-node 'provider-1 'Provider)
           encounter-1: (poo-flow-graph-node 'encounter-1 'Encounter)
           condition-1: (poo-flow-graph-node 'condition-1 'Condition)
           medication-order-1:
           (poo-flow-graph-node 'medication-order-1 'MedicationOrder))
       edge-declarations:
       (.o encounter-patient:
           (poo-flow-graph-edge 'encounter-1 'patient-1 'HAS_PATIENT)
           encounter-provider:
           (poo-flow-graph-edge 'encounter-1 'provider-1 'HAS_PROVIDER)
           encounter-condition:
           (poo-flow-graph-edge 'encounter-1 'condition-1 'HAS_CONDITION)
           order-patient:
           (poo-flow-graph-edge
            'medication-order-1 'patient-1 'ORDER_FOR_PATIENT)
           order-provider:
           (poo-flow-graph-edge
            'medication-order-1 'provider-1 'ASSIGNED_PROVIDER)))))
