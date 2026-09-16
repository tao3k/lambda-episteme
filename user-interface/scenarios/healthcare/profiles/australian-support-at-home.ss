;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/src/modules/authorization/objects
                 poo-flow-authorization-capability)
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
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/australian-primary-care
                 AustralianPrimaryCareProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export AustralianSupportAtHomeProfile)

(.def (AustralianSupportAtHomeProfile self AustralianPrimaryCareProfile)
  (identity "lambda-episteme/ontology/healthcare/australia/support-at-home")
  (name 'australian-support-at-home)
  (.import
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile
       primary-care: AustralianPrimaryCareProfile))
  (.add-concept
   (.o aged-care-assessment:
       (ontology-concept
        'AgedCareAssessment '(Action) '(decision-reviewable))
       notice-of-decision:
       (ontology-concept 'NoticeOfDecision '(Evidence) '(reason-bound))
       support-plan:
       (ontology-concept 'SupportPlan '(Evidence) '(person-centred))
       support-at-home-provider:
       (ontology-concept 'SupportAtHomeProvider '(Provider) '(consumer-selected))
       home-care-service:
       (ontology-concept 'HomeCareService '(Action) '(plan-authorized))
       referral-code:
       (ontology-concept 'AgedCareReferralCode '(Evidence) '(revocable))))
  (.add-relation
   (.o referral-requests-assessment:
       (ontology-relation
        'REQUESTS_ASSESSMENT 'ClinicalReferral 'AgedCareAssessment '(required))
       assessment-for:
       (ontology-relation
        'ASSESSMENT_FOR 'AgedCareAssessment 'Patient '(required))
       assessment-decision:
       (ontology-relation
        'PRODUCES_DECISION 'AgedCareAssessment 'NoticeOfDecision '(required))
       decision-support-plan:
       (ontology-relation
        'ISSUES_SUPPORT_PLAN 'NoticeOfDecision 'SupportPlan '(required))
       plan-authorizes-service:
       (ontology-relation
        'AUTHORIZES_SERVICE 'SupportPlan 'HomeCareService '(required))
       service-delivered-by:
       (ontology-relation
        'DELIVERED_BY 'HomeCareService 'SupportAtHomeProvider '(required))
       referral-code-for:
       (ontology-relation
        'REFERRAL_CODE_FOR 'AgedCareReferralCode 'SupportPlan '(required))))
  (.add-source
   (.o australian-support-at-home-authority:
       (ontology-source
        "healthcare/australia/support-at-home/authority-evidence"
        "user-interface/scenarios/healthcare/sources/australian-support-at-home-authority.json"
        'json 'scenario 'healthcare #f)))
  (.add-rule (.o))
  (.add-threat
   (.o service-before-assessment:
       (poo-flow-governance-threat
        "healthcare/australia/support-at-home/threat/assessment-bypass"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/australia/support-at-home/precondition/approved-assessment"
          #t "evidence:notice-of-decision"))
        mitigations: '("service eligibility follows an approved assessment"))
       service-outside-support-plan:
       (poo-flow-governance-threat
        "healthcare/australia/support-at-home/threat/unbound-support-plan"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/australia/support-at-home/precondition/support-plan"
          #t "evidence:person-centred-support-plan"))
        mitigations: '("service type is present in the support plan"))
       stale-or-misdirected-referral:
       (poo-flow-governance-threat
        "healthcare/australia/support-at-home/threat/invalid-referral-code"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/australia/support-at-home/precondition/referral-code"
          #t "evidence:active-referral-code"))
        mitigations: '("only the active consumer-selected provider accepts the code"))
       provider-choice-overridden:
       (poo-flow-governance-threat
        "healthcare/australia/support-at-home/threat/provider-choice-overridden"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/australia/support-at-home/precondition/provider-choice"
          #t "evidence:consumer-provider-selection"))
        mitigations: '("provider selection remains under consumer control"))))
  (policies
   (.o assessment: 'required-before-service
       support-plan: 'service-authority
       referral-code: 'provider-scoped
       provider-choice: 'consumer-controlled))
  (.add-capability
   (.o accept-support-at-home-referral:
       (poo-flow-authorization-capability
        "healthcare/australia/support-at-home/capability/accept-referral"
        "HealthcareAU::Action::\"acceptSupportAtHomeReferral\""
        4302 'elevated)))
  (.add-query (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((aged-care-assessment-approved?
         . "healthcare/australia/support-at-home/threat/assessment-bypass")
        (support-plan-bound?
         . "healthcare/australia/support-at-home/threat/unbound-support-plan")
        (referral-code-active?
         . "healthcare/australia/support-at-home/threat/invalid-referral-code")
        (consumer-provider-choice-observed?
         . "healthcare/australia/support-at-home/threat/provider-choice-overridden"))))))
