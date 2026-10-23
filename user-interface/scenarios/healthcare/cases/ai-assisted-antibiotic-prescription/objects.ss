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
        (only-in :agentic-ai-lab/modules/temporal-causality/interface
                 agentic-ai-lab-causal-trajectory-contract)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/authorization
                 healthcare-medication-administration)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/temporal-causality
                 healthcare-clinical-event))

(export AIAssistedAntibioticPrescriptionCasePrototype)

(.def (AIAssistedAntibioticPrescriptionCasePrototype @ OntologyCase)
  ;; Maintained clinical evidence and graph projections stay out of the
  ;; ordinary Case declaration.  A Case can still override native slots.
  (authorization-declarations =>.+
   (.o alternative-order-administration:
       (healthcare-medication-administration
        "clinician-1" "patient-1" "encounter-1" "alternative-order-1"
        #t #f)))

  (event-declarations =>.+
   (.o care-request:
       (healthcare-clinical-event
        "patient-1" "care-request-1" 'care-request 1
        "encounter-1/symptom-request" '() 'observed #t)
       active-warfarin-context:
       (healthcare-clinical-event
        "patient-1" "active-warfarin-context-1" 'medication-context 2
        "active-therapy/warfarin-1" '("care-request-1") 'observed #t)
       ai-candidate:
       (healthcare-clinical-event
        "patient-1" "ai-tmp-smx-recommendation-1" 'ai-recommendation 3
        "proposed-order/tmp-smx-1"
        '("active-warfarin-context-1") 'observed #t)
       interaction-evidence:
       (healthcare-clinical-event
        "patient-1" "warfarin-tmp-smx-interaction-evidence-1"
        'drug-interaction-evidence 4
        "healthcare/pharmacology/warfarin-tmp-smx-label-evidence/v1"
        '("ai-tmp-smx-recommendation-1") 'observed #t)
       governance-hold:
       (healthcare-clinical-event
        "patient-1" "prescription-governance-hold-1" 'governance-hold 5
        "hold/proposed-order-tmp-smx-1"
        '("warfarin-tmp-smx-interaction-evidence-1") 'observed #t)
       clinician-review:
       (healthcare-clinical-event
        "patient-1" "independent-clinician-review-1" 'clinical-review 6
        "review/reject-tmp-smx-and-select-alternative"
        '("prescription-governance-hold-1") 'observed #t)
       alternative-prescription:
       (healthcare-clinical-event
        "patient-1" "alternative-prescription-1/rev1" 'prescription 7
        "alternative-order-1"
        '("independent-clinician-review-1") 'observed #t)
       pharmacy-verification:
       (healthcare-clinical-event
        "patient-1" "pharmacy-verification-1" 'pharmacy-verification 8
        "verification/alternative-order-1"
        '("alternative-prescription-1/rev1") 'observed #t)
       administration-ready:
       (healthcare-clinical-event
        "patient-1" "alternative-administration-ready-1"
        'administration-ready 9 "alternative-order-1"
        '("pharmacy-verification-1") 'declared #f)
       wrong-auto-approval:
       (healthcare-clinical-event
        "patient-1" "wrong-ai-auto-approval-1" 'prescription 5
        "proposed-order/tmp-smx-1"
        '("warfarin-tmp-smx-interaction-evidence-1") 'counterfactual #f)
       wrong-administration:
       (healthcare-clinical-event
        "patient-1" "wrong-tmp-smx-administration-1"
        'medication-administration 6 "dose/tmp-smx-1"
        '("wrong-ai-auto-approval-1") 'counterfactual #f)
       anticoagulation-risk:
       (healthcare-clinical-event
        "patient-1" "elevated-anticoagulation-risk-1"
        'pharmacology-risk 7 "risk/prolonged-prothrombin-time"
        '("wrong-tmp-smx-administration-1") 'hypothesized #f)))

  (trajectory-declarations =>.+
   (.o prescription-safety:
       (agentic-ai-lab-causal-trajectory-contract
        "healthcare/prescription/ai-assisted-safety-trajectory"
        "ai-tmp-smx-recommendation-1"
        '("warfarin-tmp-smx-interaction-evidence-1"
          "prescription-governance-hold-1"
          "independent-clinician-review-1"
          "alternative-prescription-1/rev1"
          "pharmacy-verification-1"
          "alternative-administration-ready-1")
        '(("wrong-ai-auto-approval-1"
           "wrong-tmp-smx-administration-1"))
        '()
        '("elevated-anticoagulation-risk-1"))))

  (graph
   (.o (:: @ Graph)
       graph-id: 'ai-assisted-antibiotic-prescription
       node-declarations:
       (.o patient-1: (agentic-ai-lab-graph-node 'patient-1 'Patient)
           clinician-1: (agentic-ai-lab-graph-node 'clinician-1 'Provider)
           encounter-1: (agentic-ai-lab-graph-node 'encounter-1 'Encounter)
           suspected-infection-1:
           (agentic-ai-lab-graph-node 'suspected-infection-1 'Condition)
           warfarin-1: (agentic-ai-lab-graph-node 'warfarin-1 'Medication)
           tmp-smx-1: (agentic-ai-lab-graph-node 'tmp-smx-1 'Medication)
           alternative-medication-1:
           (agentic-ai-lab-graph-node 'alternative-medication-1 'Medication)
           warfarin-therapy-1:
           (agentic-ai-lab-graph-node 'warfarin-therapy-1 'ActiveTherapy)
           proposed-order-1:
           (agentic-ai-lab-graph-node 'proposed-order-1 'MedicationOrder)
           alternative-order-1:
           (agentic-ai-lab-graph-node 'alternative-order-1 'MedicationOrder)
           interaction-evidence-1:
           (agentic-ai-lab-graph-node
            'interaction-evidence-1 'DrugInteractionEvidence)
           monitoring-plan-1:
           (agentic-ai-lab-graph-node 'monitoring-plan-1 'MonitoringPlan)
           ai-cds-1:
           (agentic-ai-lab-graph-node
            'ai-cds-1 'ClinicalDecisionSupportSystem)
           ai-recommendation-1:
           (agentic-ai-lab-graph-node 'ai-recommendation-1 'AIRecommendation)
           clinical-review-1:
           (agentic-ai-lab-graph-node 'clinical-review-1 'ClinicalReview))
       edge-declarations:
       (.o encounter-patient:
           (agentic-ai-lab-graph-edge 'encounter-1 'patient-1 'HAS_PATIENT)
           encounter-provider:
           (agentic-ai-lab-graph-edge 'encounter-1 'clinician-1 'HAS_PROVIDER)
           encounter-condition:
           (agentic-ai-lab-graph-edge
            'encounter-1 'suspected-infection-1 'HAS_CONDITION)
           patient-active-therapy:
           (agentic-ai-lab-graph-edge
            'patient-1 'warfarin-therapy-1 'HAS_ACTIVE_THERAPY)
           therapy-medication:
           (agentic-ai-lab-graph-edge
            'warfarin-therapy-1 'warfarin-1 'THERAPY_USES_MEDICATION)
           interaction:
           (agentic-ai-lab-graph-edge 'tmp-smx-1 'warfarin-1 'INTERACTS_WITH)
           interaction-evidence:
           (agentic-ai-lab-graph-edge
            'interaction-evidence-1 'tmp-smx-1 'INTERACTION_EVIDENCE_FOR)
           proposed-order-patient:
           (agentic-ai-lab-graph-edge
            'proposed-order-1 'patient-1 'ORDER_FOR_PATIENT)
           proposed-order-provider:
           (agentic-ai-lab-graph-edge
            'proposed-order-1 'clinician-1 'ASSIGNED_PROVIDER)
           proposed-order-medication:
           (agentic-ai-lab-graph-edge
            'proposed-order-1 'tmp-smx-1 'ORDERS_MEDICATION)
           proposed-order-monitoring:
           (agentic-ai-lab-graph-edge
            'proposed-order-1 'monitoring-plan-1 'REQUIRES_MONITORING)
           alternative-order-patient:
           (agentic-ai-lab-graph-edge
            'alternative-order-1 'patient-1 'ORDER_FOR_PATIENT)
           alternative-order-provider:
           (agentic-ai-lab-graph-edge
            'alternative-order-1 'clinician-1 'ASSIGNED_PROVIDER)
           alternative-order-medication:
           (agentic-ai-lab-graph-edge
            'alternative-order-1 'alternative-medication-1 'ORDERS_MEDICATION)
           ai-generates-recommendation:
           (agentic-ai-lab-graph-edge
            'ai-cds-1 'ai-recommendation-1 'GENERATES_RECOMMENDATION)
           recommendation-order:
           (agentic-ai-lab-graph-edge
            'ai-recommendation-1 'proposed-order-1 'RECOMMENDS_ORDER)
           recommendation-basis:
           (agentic-ai-lab-graph-edge
            'ai-recommendation-1 'interaction-evidence-1 'HAS_DECISION_BASIS)
           recommendation-reviewer:
           (agentic-ai-lab-graph-edge
            'ai-recommendation-1 'clinician-1 'INDEPENDENTLY_REVIEWED_BY)
           clinician-review-record:
           (agentic-ai-lab-graph-edge
            'clinician-1 'clinical-review-1 'RECORDS_CLINICAL_REVIEW)))))
