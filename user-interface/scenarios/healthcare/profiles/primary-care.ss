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
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export PrimaryCareProfile)

(.def (PrimaryCareProfile self HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/primary-care")
  (name 'primary-care)
  (.import
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile))
  (.add-concept
   (.o general-practice:
       (ontology-concept 'GeneralPractice '(BaseEntity) '(registered))
       general-practitioner:
       (ontology-concept 'GeneralPractitioner '(Provider) '(provider-number))
       primary-care-appointment:
       (ontology-concept
        'PrimaryCareAppointment '(Encounter) '(triage-required))
       primary-care-registration:
       (ontology-concept
        'PrimaryCareRegistration '(Evidence) '(voluntary consent-required))
       clinical-referral:
       (ontology-concept 'ClinicalReferral '(Action) '(source-bound))
       health-information-consent:
       (ontology-concept
        'HealthInformationConsent '(Evidence) '(purpose-limited))))
  (.add-relation
   (.o registered-with:
       (ontology-relation
        'REGISTERED_WITH 'Patient 'GeneralPractice '(voluntary))
       preferred-gp:
       (ontology-relation
        'PREFERRED_GP 'Patient 'GeneralPractitioner '(single-current))
       hosts-gp:
       (ontology-relation
        'HOSTS_GP 'GeneralPractice 'GeneralPractitioner '(eligible))
       appointment-for:
       (ontology-relation
        'APPOINTMENT_FOR 'PrimaryCareAppointment 'Patient '(required))
       appointment-at:
       (ontology-relation
        'APPOINTMENT_AT 'PrimaryCareAppointment 'GeneralPractice '(required))
       attended-by-gp:
       (ontology-relation
        'ATTENDED_BY_GP 'PrimaryCareAppointment 'GeneralPractitioner '(required))
       registration-evidence:
       (ontology-relation
        'REGISTRATION_EVIDENCE
        'PrimaryCareRegistration 'Patient '(consent-required))
       consent-for:
       (ontology-relation
        'CONSENT_FOR
        'HealthInformationConsent 'Patient '(purpose-limited))))
  (.add-source (.o))
  (.add-rule (.o))
  (.add-threat
   (.o registration-without-dual-consent:
       (poo-flow-governance-threat
        "healthcare/primary-care/threat/unconsented-registration"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/primary-care/precondition/registration-consent"
          #t "evidence:primary-care-registration-consent"))
        mitigations: '("patient and practice consent are recorded"))
       ineligible-practice-or-gp:
       (poo-flow-governance-threat
        "healthcare/primary-care/threat/ineligible-practice-or-provider"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/primary-care/precondition/provider-eligibility"
          #t "evidence:practice-registration-and-provider-number"))
        mitigations: '("practice registration and GP provider number are verified"))
       routine-path-without-triage:
       (poo-flow-governance-threat
        "healthcare/primary-care/threat/untriaged-appointment"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/primary-care/precondition/clinical-triage"
          #t "evidence:appointment-triage"))
        mitigations: '("urgent symptoms leave the routine booking path"))
       health-information-over-disclosure:
       (poo-flow-governance-threat
        "healthcare/primary-care/threat/health-information-over-disclosure"
        'high 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/primary-care/precondition/disclosure-consent"
          #t "evidence:purpose-limited-health-information-consent"))
        mitigations: '("disclosure stays within consented care coordination purpose"))))
  (policies
   (.o registration: 'voluntary-and-revocable
       preferred-practice: 'single-current
       preferred-gp: 'eligible-provider
       urgent-care: 'separate-escalation
       disclosure: 'purpose-limited))
  (.add-capability
   (.o schedule-primary-care:
       (poo-flow-authorization-capability
        "healthcare/primary-care/capability/schedule-appointment"
        "Healthcare::Action::\"schedulePrimaryCareAppointment\""
        4301 'ordinary)))
  (.add-query (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((primary-care-registration-consent-observed?
         . "healthcare/primary-care/threat/unconsented-registration")
        (primary-care-provider-eligibility-verified?
         . "healthcare/primary-care/threat/ineligible-practice-or-provider")
        (clinical-triage-complete?
         . "healthcare/primary-care/threat/untriaged-appointment")
        (health-information-sharing-consented?
         . "healthcare/primary-care/threat/health-information-over-disclosure"))))))
