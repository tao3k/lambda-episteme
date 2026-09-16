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
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/australian-primary-care
                 AustralianPrimaryCareProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/australian-support-at-home
                 AustralianSupportAtHomeProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/temporal-causality
                 healthcare-clinical-event))

(export AustralianPersonalCareCoordinationCase)

(.def (AustralianPersonalCareCoordinationCase @ OntologyCase)
  (case-id 'australian-personal-care-coordination)
  (scenario HealthcareScenario)

  ;; Profile methods consume these Case-owned observations.  A false value is
  ;; a typed Governance rejection, not a fallback to an ungoverned booking.
  (mymedicare-dual-consent-observed? #t)
  (primary-care-provider-eligibility-verified? #t)
  (clinical-triage-complete? #t)
  (health-information-sharing-consented? #t)
  (aged-care-assessment-approved? #t)
  (support-plan-bound? #t)
  (referral-code-active? #t)
  (consumer-provider-choice-observed? #t)

  (.use-composition
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile)
       australian-care:
       (.o primary-care: AustralianPrimaryCareProfile
           support-at-home: AustralianSupportAtHomeProfile)))

  (.add-event
   (.o care-request:
       (healthcare-clinical-event
        "person-1" "personal-care-request-1" 'care-request 1
        "request/home-support-and-primary-care" '() 'observed #t)
       triage:
       (healthcare-clinical-event
        "person-1" "primary-care-triage-1" 'clinical-triage 2
        "triage/routine-primary-care" '("personal-care-request-1")
        'observed #t)
       registration:
       (healthcare-clinical-event
        "person-1" "mymedicare-registration-confirmed-1"
        'mymedicare-registration 3 "registration/person-1/practice-1"
        '("primary-care-triage-1") 'observed #t)
       consultation:
       (healthcare-clinical-event
        "person-1" "preferred-gp-consultation-1" 'gp-consultation 4
        "appointment-1" '("mymedicare-registration-confirmed-1")
        'observed #t)
       referral:
       (healthcare-clinical-event
        "person-1" "support-at-home-referral-1" 'aged-care-referral 5
        "referral-1" '("preferred-gp-consultation-1") 'observed #t)
       assessment:
       (healthcare-clinical-event
        "person-1" "aged-care-assessment-approved-1"
        'aged-care-assessment 6 "assessment-1"
        '("support-at-home-referral-1") 'observed #t)
       support-plan:
       (healthcare-clinical-event
        "person-1" "support-plan-issued-1" 'support-plan 7
        "support-plan-1" '("aged-care-assessment-approved-1")
        'observed #t)
       provider-acceptance:
       (healthcare-clinical-event
        "person-1" "home-care-provider-accepted-1" 'provider-acceptance 8
        "provider-1/referral-code-1" '("support-plan-issued-1")
        'observed #t)
       first-home-visit:
       (healthcare-clinical-event
        "person-1" "first-home-care-visit-1" 'home-care-visit 9
        "service-1" '("home-care-provider-accepted-1") 'declared #f)
       routine-booking-without-triage:
       (healthcare-clinical-event
        "person-1" "routine-booking-without-triage-1"
        'unsafe-routine-booking 2 "appointment-1/untriaged"
        '("personal-care-request-1") 'counterfactual #f)
       unconsented-disclosure:
       (healthcare-clinical-event
        "person-1" "unconsented-health-information-disclosure-1"
        'privacy-breach 5 "disclosure/provider-1"
        '("preferred-gp-consultation-1") 'counterfactual #f)
       sustained-independence:
       (healthcare-clinical-event
        "person-1" "sustained-independent-living-1"
        'care-outcome 10 "outcome/independent-living"
        '("first-home-care-visit-1") 'hypothesized #f)))

  (graph
   (.o (:: @ Graph)
       graph-id: 'australian-personal-care-coordination
       .add-node:
       (.o person-1: (poo-flow-graph-node 'person-1 'Patient)
           practice-1: (poo-flow-graph-node 'practice-1 'GeneralPractice)
           gp-1: (poo-flow-graph-node 'gp-1 'GeneralPractitioner)
           appointment-1:
           (poo-flow-graph-node 'appointment-1 'PrimaryCareAppointment)
           registration-1:
           (poo-flow-graph-node 'registration-1 'MyMedicareRegistration)
           consent-1:
           (poo-flow-graph-node 'consent-1 'HealthInformationConsent)
           referral-1: (poo-flow-graph-node 'referral-1 'ClinicalReferral)
           assessment-1:
           (poo-flow-graph-node 'assessment-1 'AgedCareAssessment)
           decision-1:
           (poo-flow-graph-node 'decision-1 'NoticeOfDecision)
           support-plan-1:
           (poo-flow-graph-node 'support-plan-1 'SupportPlan)
           referral-code-1:
           (poo-flow-graph-node 'referral-code-1 'AgedCareReferralCode)
           provider-1:
           (poo-flow-graph-node 'provider-1 'SupportAtHomeProvider)
           service-1: (poo-flow-graph-node 'service-1 'HomeCareService))
       .add-edge:
       (.o patient-registration:
           (poo-flow-graph-edge 'person-1 'practice-1 'REGISTERED_WITH)
           patient-preferred-gp:
           (poo-flow-graph-edge 'person-1 'gp-1 'PREFERRED_GP)
           practice-hosts-gp:
           (poo-flow-graph-edge 'practice-1 'gp-1 'HOSTS_GP)
           appointment-patient:
           (poo-flow-graph-edge 'appointment-1 'person-1 'APPOINTMENT_FOR)
           appointment-practice:
           (poo-flow-graph-edge 'appointment-1 'practice-1 'APPOINTMENT_AT)
           appointment-gp:
           (poo-flow-graph-edge 'appointment-1 'gp-1 'ATTENDED_BY_GP)
           registration-evidence:
           (poo-flow-graph-edge
            'registration-1 'person-1 'REGISTRATION_EVIDENCE)
           information-consent:
           (poo-flow-graph-edge 'consent-1 'person-1 'CONSENT_FOR)
           referral-assessment:
           (poo-flow-graph-edge 'referral-1 'assessment-1 'REQUESTS_ASSESSMENT)
           assessment-person:
           (poo-flow-graph-edge 'assessment-1 'person-1 'ASSESSMENT_FOR)
           assessment-decision:
           (poo-flow-graph-edge 'assessment-1 'decision-1 'PRODUCES_DECISION)
           decision-plan:
           (poo-flow-graph-edge 'decision-1 'support-plan-1 'ISSUES_SUPPORT_PLAN)
           plan-service:
           (poo-flow-graph-edge 'support-plan-1 'service-1 'AUTHORIZES_SERVICE)
           service-provider:
           (poo-flow-graph-edge 'service-1 'provider-1 'DELIVERED_BY)
           referral-code-plan:
           (poo-flow-graph-edge
            'referral-code-1 'support-plan-1 'REFERRAL_CODE_FOR)))))
