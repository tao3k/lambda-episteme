;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Cedar and Healthcare Profiles are independently extensible axes.  Their
;;; crossing belongs to CLOS, while each Profile's own assessment remains the
;;; ordinary `.assess-governance` slot generic.
(import (only-in :clan/poo/object .o .ref .slot?)
        :std/list/list
        :core/poo-clos/interface
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/ai-clinical-decision-support
                 AIClinicalDecisionSupportProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/pharmacology-safety
                 PharmacologySafetyProfile))

(export HealthcareAuthorizationProjectionExecutor
        HealthcareCedarAuthorizationProjectionExecutor
        HealthcareCedarAuthorizationProjector
        HealthcareAuthorizationProjectionProtocol
        HealthcareAuthorizationProjectionGeneric
        HealthcareAuthorizationProjectionMethods
        healthcare-authorization-profile-project
        healthcare-cedar-governance-projection
        healthcare-cedar-governance-projection-canonical)

(def HealthcareAuthorizationProjectionExecutor
  (poo-clos-class 'healthcare/authorization-projection-executor))

(def HealthcareCedarAuthorizationProjectionExecutor
  (poo-clos-class
   'healthcare/cedar-authorization-projection-executor
   direct-superclasses: (list HealthcareAuthorizationProjectionExecutor)))

(def HealthcareCedarAuthorizationProjector
  (poo-clos-make-instance
   HealthcareCedarAuthorizationProjectionExecutor))

(def HealthcareAuthorizationProjectionProtocol
  (poo-clos-generic-protocol 'healthcare/authorization-profile-project))

(def HealthcareAuthorizationProjectionGeneric
  (poo-clos-generic-function
   'healthcare-authorization-profile-project 3
   protocol: HealthcareAuthorizationProjectionProtocol))

(def (healthcare-authorization-profile-project executor profile case-value)
  (poo-clos-call
   HealthcareAuthorizationProjectionGeneric executor profile case-value))

(def (case-evidence case-value slot)
  (and (.slot? case-value slot) (.ref case-value slot)))

(def HealthcareDefaultAuthorizationProjectionMethod
  (poo-clos-method
   'healthcare/default-authorization-projection
   (list
    (poo-clos-class-specializer
     HealthcareAuthorizationProjectionExecutor)
    (poo-clos-any-specializer)
    (poo-clos-any-specializer))
   (lambda (_frame _executor profile _case-value)
     ;; Profiles without Governance threats are outside the Cedar projection
     ;; axis. A threatened Profile must never disappear through the catch-all.
     (if (and (.slot? profile 'threat-model)
              (pair? (.ref (.ref profile 'threat-model) 'threats)))
       (error "Healthcare threatened Profile lacks a Cedar projection method"
              (.ref profile 'identity))
       #f))))

(def HealthcareCedarMedicationProjectionMethod
  (poo-clos-method
   'healthcare/cedar-medication-safety-projection
   (list
    (poo-clos-class-specializer
     HealthcareCedarAuthorizationProjectionExecutor)
    (poo-clos-eql-specializer MedicationSafetyProfile)
    (poo-clos-any-specializer))
   (lambda (_frame _executor profile case-value)
     (.o profile-identity: (.ref profile 'identity)
         medication-reconciliation-observed?:
         (case-evidence case-value 'medication-reconciliation-observed?)))))

(def HealthcareCedarPharmacologyProjectionMethod
  (poo-clos-method
   'healthcare/cedar-pharmacology-projection
   (list
    (poo-clos-class-specializer
     HealthcareCedarAuthorizationProjectionExecutor)
    (poo-clos-eql-specializer PharmacologySafetyProfile)
    (poo-clos-any-specializer))
   (lambda (_frame _executor profile case-value)
     (.o profile-identity: (.ref profile 'identity)
         medication-reconciliation-observed?:
         (case-evidence case-value 'medication-reconciliation-observed?)
         interaction-review-observed?:
         (case-evidence case-value 'interaction-review-observed?)
         monitoring-plan-observed?:
         (case-evidence case-value 'monitoring-plan-observed?)))))

(def HealthcareCedarAIProjectionMethod
  (poo-clos-method
   'healthcare/cedar-ai-clinical-decision-support-projection
   (list
    (poo-clos-class-specializer
     HealthcareCedarAuthorizationProjectionExecutor)
    (poo-clos-eql-specializer AIClinicalDecisionSupportProfile)
    (poo-clos-any-specializer))
   (lambda (_frame _executor profile case-value)
     (.o profile-identity: (.ref profile 'identity)
         ai-advisory-only?:
         (case-evidence case-value 'ai-advisory-only?)
         ai-basis-reviewable?:
         (case-evidence case-value 'ai-basis-reviewable?)
         independent-clinician-review?:
         (case-evidence case-value 'independent-clinician-review?)))))

(.defmethod-bundle HealthcareAuthorizationProjectionMethods
  HealthcareAuthorizationProjectionProtocol
  HealthcareDefaultAuthorizationProjectionMethod
  HealthcareCedarMedicationProjectionMethod
  HealthcareCedarPharmacologyProjectionMethod
  HealthcareCedarAIProjectionMethod)

(poo-clos-compose-method-bundle
 HealthcareAuthorizationProjectionGeneric
 HealthcareAuthorizationProjectionMethods)

(def (healthcare-cedar-governance-projection receipt)
  (let (case-value (.ref receipt 'case))
    (filter
     values
     (map
      (lambda (profile)
        (healthcare-authorization-profile-project
         HealthcareCedarAuthorizationProjector profile case-value))
      (.ref receipt 'profiles)))))

;;; The proof digest needs one stable functional value, not a serialization of
;;; CLOS or POO runtime internals.
(def (healthcare-cedar-governance-projection-canonical receipt)
  (map
   (lambda (projection)
     (let (identity (.ref projection 'profile-identity))
       (cond
        ((equal?
          identity
          "lambda-episteme/ontology/healthcare/medication-safety")
         (list identity
               (.ref projection 'medication-reconciliation-observed?)))
        ((equal?
          identity
          "lambda-episteme/ontology/healthcare/pharmacology-safety")
         (list identity
               (.ref projection 'medication-reconciliation-observed?)
               (.ref projection 'interaction-review-observed?)
               (.ref projection 'monitoring-plan-observed?)))
        ((equal?
          identity
          "lambda-episteme/ontology/healthcare/ai-clinical-decision-support")
         (list identity
               (.ref projection 'ai-advisory-only?)
               (.ref projection 'ai-basis-reviewable?)
               (.ref projection 'independent-clinician-review?)))
        (else
         (error "unknown Healthcare Cedar Governance projection" identity)))))
   (healthcare-cedar-governance-projection receipt)))
