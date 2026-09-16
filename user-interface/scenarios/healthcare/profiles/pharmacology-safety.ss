;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/src/modules/governance/objects
                 poo-flow-governance-precondition
                 poo-flow-governance-threat)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-concept ontology-relation ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/pharmacology-evidence
                 HealthcarePharmacologyEvidence)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile))

(export PharmacologySafetyProfile)

(.def (PharmacologySafetyProfile @ MedicationSafetyProfile)
  (identity "lambda-episteme/ontology/healthcare/pharmacology-safety")
  (name 'pharmacology-safety)
  (.import
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile
       medication: MedicationSafetyProfile))
  (.add-concept
   (.o active-therapy:
       (ontology-concept 'ActiveTherapy '(BaseEntity) '(patient-bound))
       interaction-evidence:
       (ontology-concept
        'DrugInteractionEvidence '(Evidence) '(source-bound))
       monitoring-plan:
       (ontology-concept 'MonitoringPlan '(Action) '(review-required))
       patient-risk-factor:
       (ontology-concept 'PatientRiskFactor '(Evidence) '(patient-bound))))
  (.add-relation
   (.o has-active-therapy:
       (ontology-relation
        'HAS_ACTIVE_THERAPY 'Patient 'ActiveTherapy '(required))
       therapy-uses-medication:
       (ontology-relation
        'THERAPY_USES_MEDICATION 'ActiveTherapy 'Medication '(required))
       interacts-with:
       (ontology-relation
        'INTERACTS_WITH 'Medication 'Medication '(source-bound))
       interaction-evidence-for:
       (ontology-relation
        'INTERACTION_EVIDENCE_FOR
        'DrugInteractionEvidence 'Medication '(source-bound))
       orders-medication:
       (ontology-relation
        'ORDERS_MEDICATION 'MedicationOrder 'Medication '(required))
       requires-monitoring:
       (ontology-relation
        'REQUIRES_MONITORING 'MedicationOrder 'MonitoringPlan '())))
  (.add-source
   (.o warfarin-antibiotic-label-evidence:
       (ontology-source
        "healthcare/pharmacology/warfarin-tmp-smx-label-evidence"
        "user-interface/scenarios/healthcare/sources/warfarin-tmp-smx-label-evidence.json"
        'json 'scenario 'healthcare #f)))
  (.add-rule (.o))
  (.add-threat
   (.o incomplete-medication-context:
       (poo-flow-governance-threat
        "healthcare/pharmacology/threat/incomplete-medication-context"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/pharmacology/precondition/medication-reconciliation"
          #t "evidence:active-warfarin-therapy"))
        mitigations:
        '("active medication reconciliation bound to Patient and Encounter"))
       unreviewed-warfarin-antibiotic-interaction:
       (poo-flow-governance-threat
        "healthcare/pharmacology/threat/unreviewed-warfarin-antibiotic-interaction"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/pharmacology/precondition/label-interaction-reviewed"
          #t "evidence:dailymed-warfarin-tmp-smx-interaction"))
        mitigations:
        '("interaction evidence shown before prescription commitment"
          "independent clinician review required"))
       monitoring-plan-missing:
       (poo-flow-governance-threat
        "healthcare/pharmacology/threat/monitoring-plan-missing"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/pharmacology/precondition/monitoring-plan"
          #t "evidence:prescription-monitoring-plan"))
        mitigations:
        '("review records avoidance or INR reassessment plan"))))
  (policies
   (.o medication-context: 'required
       interaction-review: 'required-before-commit
       pharmacology-uncertainty: 'explicit
       evidence-type: HealthcarePharmacologyEvidence))
  (.add-capability (.o))
  (.add-query (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      PharmacologySafetyProfile context
      '((medication-reconciliation-observed?
         . "healthcare/pharmacology/threat/incomplete-medication-context")
        (interaction-review-observed?
         . "healthcare/pharmacology/threat/unreviewed-warfarin-antibiotic-interaction")
        (monitoring-plan-observed?
         . "healthcare/pharmacology/threat/monitoring-plan-missing"))))))
