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
                 ontology-concept ontology-relation)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/primary-care
                 PrimaryCareProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export SupportAtHomeProfile)

(.def (SupportAtHomeProfile self PrimaryCareProfile)
  (identity "lambda-episteme/ontology/healthcare/support-at-home")
  (name 'support-at-home)
  (profile-imports =>.+
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile
       primary-care: PrimaryCareProfile))
  (concept-declarations =>.+
   (.o care-needs-assessment:
       (ontology-concept
        'CareNeedsAssessment '(Action) '(decision-reviewable))
       care-eligibility-decision:
       (ontology-concept 'CareEligibilityDecision '(Evidence) '(reason-bound))
       support-plan:
       (ontology-concept 'SupportPlan '(Evidence) '(person-centred))
       home-support-provider:
       (ontology-concept 'HomeSupportProvider '(Provider) '(consumer-selected))
       home-support-service:
       (ontology-concept 'HomeSupportService '(Action) '(plan-authorized))
       referral-credential:
       (ontology-concept 'CareReferralCredential '(Evidence) '(revocable))))
  (relation-declarations =>.+
   (.o referral-requests-assessment:
       (ontology-relation
        'REQUESTS_ASSESSMENT 'ClinicalReferral 'CareNeedsAssessment '(required))
       assessment-for:
       (ontology-relation
        'ASSESSMENT_FOR 'CareNeedsAssessment 'Patient '(required))
       assessment-decision:
       (ontology-relation
        'PRODUCES_DECISION
        'CareNeedsAssessment 'CareEligibilityDecision '(required))
       decision-support-plan:
       (ontology-relation
        'ISSUES_SUPPORT_PLAN 'CareEligibilityDecision 'SupportPlan '(required))
       plan-authorizes-service:
       (ontology-relation
        'AUTHORIZES_SERVICE 'SupportPlan 'HomeSupportService '(required))
       service-delivered-by:
       (ontology-relation
        'DELIVERED_BY 'HomeSupportService 'HomeSupportProvider '(required))
       referral-credential-for:
       (ontology-relation
        'REFERRAL_CREDENTIAL_FOR
        'CareReferralCredential 'SupportPlan '(required))))
  (source-declarations =>.+ (.o))
  (rule-declarations =>.+ (.o))
  (threat-declarations =>.+
   (.o service-before-assessment:
       (poo-flow-governance-threat
        "healthcare/support-at-home/threat/assessment-bypass"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/support-at-home/precondition/approved-assessment"
          #t "evidence:notice-of-decision"))
        mitigations: '("service eligibility follows an approved assessment"))
       service-outside-support-plan:
       (poo-flow-governance-threat
        "healthcare/support-at-home/threat/unbound-support-plan"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/support-at-home/precondition/support-plan"
          #t "evidence:person-centred-support-plan"))
        mitigations: '("service type is present in the support plan"))
       stale-or-misdirected-referral:
       (poo-flow-governance-threat
        "healthcare/support-at-home/threat/invalid-referral-credential"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/support-at-home/precondition/referral-credential"
          #t "evidence:active-referral-credential"))
        mitigations: '("only the active consumer-selected provider accepts the credential"))
       provider-choice-overridden:
       (poo-flow-governance-threat
        "healthcare/support-at-home/threat/provider-choice-overridden"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/support-at-home/precondition/provider-choice"
          #t "evidence:consumer-provider-selection"))
        mitigations: '("provider selection remains under consumer control"))))
  (policies
   (.o assessment: 'required-before-service
       support-plan: 'service-authority
       referral-credential: 'provider-scoped
       provider-choice: 'consumer-controlled))
  (capability-declarations =>.+
   (.o accept-support-at-home-referral:
       (poo-flow-authorization-capability
        "healthcare/support-at-home/capability/accept-referral"
        "Healthcare::Action::\"acceptHomeSupportReferral\""
        4302 'elevated)))
  (query-declarations =>.+ (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((care-needs-assessment-approved?
         . "healthcare/support-at-home/threat/assessment-bypass")
        (support-plan-bound?
         . "healthcare/support-at-home/threat/unbound-support-plan")
        (referral-credential-active?
         . "healthcare/support-at-home/threat/invalid-referral-credential")
        (consumer-provider-choice-observed?
         . "healthcare/support-at-home/threat/provider-choice-overridden"))))))
