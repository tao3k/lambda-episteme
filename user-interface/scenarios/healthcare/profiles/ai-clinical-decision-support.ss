;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/src/modules/governance/objects
                 poo-flow-governance-precondition
                 poo-flow-governance-threat)
        (only-in :poo-flow/src/modules/authorization/objects
                 poo-flow-authorization-capability)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-concept ontology-relation ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/reasoning
                 CaseProfileRelationsSource ProfileImpactSource
                 PrescriptionCausalTrajectorySource
                 HealthcareCaseProfileRelationsQuery
                 HealthcareProfileImpactQuery
                 HealthcarePrescriptionCausalTrajectoryQuery)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export AIClinicalDecisionSupportProfile)

(.def (AIClinicalDecisionSupportProfile self HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/ai-clinical-decision-support")
  (name 'ai-clinical-decision-support)
  (.import
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile))
  (.add-concept
   (.o clinical-decision-support-system:
       (ontology-concept
        'ClinicalDecisionSupportSystem '(Actor) '(advisory-only))
       ai-recommendation:
       (ontology-concept
        'AIRecommendation '(Evidence) '(human-review-required))
       clinical-review:
       (ontology-concept
        'ClinicalReview '(Action) '(independent-review))
       decision-basis:
       (ontology-concept 'DecisionBasis '(Evidence) '(reviewable))))
  (.add-relation
   (.o generates-recommendation:
       (ontology-relation
        'GENERATES_RECOMMENDATION
        'ClinicalDecisionSupportSystem 'AIRecommendation '())
       recommends-order:
       (ontology-relation
        'RECOMMENDS_ORDER 'AIRecommendation 'MedicationOrder '())
       has-decision-basis:
       (ontology-relation
        'HAS_DECISION_BASIS
        'AIRecommendation 'DrugInteractionEvidence '(required))
       independently-reviewed-by:
       (ontology-relation
        'INDEPENDENTLY_REVIEWED_BY 'AIRecommendation 'Provider '(required))
       records-clinical-review:
       (ontology-relation
        'RECORDS_CLINICAL_REVIEW 'Provider 'ClinicalReview '())))
  (.add-source
   (.o ai-clinical-governance-evidence:
       (ontology-source
        "healthcare/ai-cds/governance-evidence"
        "user-interface/scenarios/healthcare/sources/ai-clinical-governance-evidence.json"
        'json 'scenario 'healthcare #f)
       case-profile-relations: CaseProfileRelationsSource
       profile-impact: ProfileImpactSource
       prescription-causal-trajectory: PrescriptionCausalTrajectorySource))
  (.add-rule (.o))
  (.add-threat
   (.o autonomous-prescription:
       (poo-flow-governance-threat
        "healthcare/ai-cds/threat/autonomous-prescription"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/ai-cds/precondition/advisory-role"
          #t "evidence:ai-role-advisory-only"))
        mitigations:
        '("AI may recommend but cannot prescribe or administer"))
       unreviewable-recommendation:
       (poo-flow-governance-threat
        "healthcare/ai-cds/threat/unreviewable-recommendation"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/ai-cds/precondition/reviewable-basis"
          #t "evidence:patient-specific-decision-basis"))
        mitigations:
        '("recommendation binds inputs, label evidence and known unknowns"))
       automation-bias:
       (poo-flow-governance-threat
        "healthcare/ai-cds/threat/automation-bias"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/ai-cds/precondition/independent-clinician-review"
          #t "evidence:independent-clinician-review"))
        mitigations:
        '("clinician records an independent accept, modify or reject decision"))))
  (policies
   (.o ai-role: 'advisory-only
       independent-review: 'required
       explanation: 'patient-specific
       authority: 'none))
  (.add-capability
   (.o recommend-medication:
       (poo-flow-authorization-capability
        "healthcare/ai-cds/capability/recommend-medication"
        "Healthcare::Action::\"recommendMedication\""
        4201
        'ordinary)))
  (.add-query
   (.o case-profile-relations: HealthcareCaseProfileRelationsQuery
       profile-impact: HealthcareProfileImpactQuery
       prescription-causal-trajectory:
       HealthcarePrescriptionCausalTrajectoryQuery))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((ai-advisory-only?
         . "healthcare/ai-cds/threat/autonomous-prescription")
        (ai-basis-reviewable?
         . "healthcare/ai-cds/threat/unreviewable-recommendation")
        (independent-clinician-review?
         . "healthcare/ai-cds/threat/automation-bias"))))))
