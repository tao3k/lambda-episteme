;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; TLA+/Lean Providers and vertical Profiles are independently extensible
;;; axes. Their crossing is CLOS multi-dispatch; the trajectory itself remains
;;; one POO slot contract owned by the Case.
(import (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/src/modules/temporal-causality/interface
                 poo-flow-causal-trajectory-assessment-digest)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/ai-clinical-decision-support
                 AIClinicalDecisionSupportProfile))

(export HealthcareFormalAssuranceProvider
        HealthcareTLAPlusAssuranceProvider
        HealthcareLeanAssuranceProvider
        HealthcareTLAPlusAssuranceProjector
        HealthcareLeanAssuranceProjector
        HealthcareFormalAssuranceProjectionProtocol
        HealthcareFormalAssuranceProjectionGeneric
        HealthcareFormalAssuranceProjectionMethods
        healthcare-formal-assurance-project)

(def HealthcareFormalAssuranceProvider
  (poo-clos-class 'healthcare/formal-assurance-provider))

(def HealthcareTLAPlusAssuranceProvider
  (poo-clos-class
   'healthcare/tla-plus-assurance-provider
   direct-superclasses: (list HealthcareFormalAssuranceProvider)))

(def HealthcareLeanAssuranceProvider
  (poo-clos-class
   'healthcare/lean-assurance-provider
   direct-superclasses: (list HealthcareFormalAssuranceProvider)))

(def HealthcareTLAPlusAssuranceProjector
  (poo-clos-make-instance HealthcareTLAPlusAssuranceProvider))

(def HealthcareLeanAssuranceProjector
  (poo-clos-make-instance HealthcareLeanAssuranceProvider))

(def HealthcareFormalAssuranceProjectionProtocol
  (poo-clos-generic-protocol 'healthcare/formal-assurance-project))

(def HealthcareFormalAssuranceProjectionGeneric
  (poo-clos-generic-function
   'healthcare-formal-assurance-project 4
   protocol: HealthcareFormalAssuranceProjectionProtocol))

(def (healthcare-formal-assurance-project
      provider profile trajectory-assessment evidence-receipt)
  (poo-clos-call
   HealthcareFormalAssuranceProjectionGeneric
   provider profile trajectory-assessment evidence-receipt))

(def HealthcareUnsupportedFormalAssuranceProjectionMethod
  (poo-clos-method
   'healthcare/unsupported-formal-assurance-projection
   (list (poo-clos-class-specializer HealthcareFormalAssuranceProvider)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _provider profile _trajectory _evidence)
     (error "Healthcare Profile lacks a formal assurance Provider method"
            (.ref profile 'identity)))))

(def HealthcareTLAPlusTrajectoryProjectionMethod
  (poo-clos-method
   'healthcare/tla-plus-trajectory-projection
   (list (poo-clos-class-specializer HealthcareTLAPlusAssuranceProvider)
         (poo-clos-eql-specializer AIClinicalDecisionSupportProfile)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _provider profile trajectory evidence)
     (.o kind: 'lambda-episteme.healthcare-formal-assurance-binding
         engine: 'tla-plus
         profile-identity: (.ref profile 'identity)
         trajectory-contract-identity: (.ref trajectory 'contract-identity)
         trajectory-assessment-digest:
         (poo-flow-causal-trajectory-assessment-digest trajectory)
         evidence-source-content-id: (.ref evidence 'source-content-id)
         evidence-admitted?: (.ref evidence 'admitted?)))))

(def HealthcareLeanTrajectoryProjectionMethod
  (poo-clos-method
   'healthcare/lean-trajectory-projection
   (list (poo-clos-class-specializer HealthcareLeanAssuranceProvider)
         (poo-clos-eql-specializer AIClinicalDecisionSupportProfile)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _provider profile trajectory evidence)
     (.o kind: 'lambda-episteme.healthcare-formal-assurance-binding
         engine: 'lean
         profile-identity: (.ref profile 'identity)
         trajectory-contract-identity: (.ref trajectory 'contract-identity)
         trajectory-assessment-digest:
         (poo-flow-causal-trajectory-assessment-digest trajectory)
         evidence-source-content-id: (.ref evidence 'source-content-id)
         evidence-certifications: (.ref evidence 'certifications)
         evidence-admitted?: (.ref evidence 'admitted?)))))

(.defmethod-bundle HealthcareFormalAssuranceProjectionMethods
  HealthcareFormalAssuranceProjectionProtocol
  HealthcareUnsupportedFormalAssuranceProjectionMethod
  HealthcareTLAPlusTrajectoryProjectionMethod
  HealthcareLeanTrajectoryProjectionMethod)

(poo-clos-compose-method-bundle
 HealthcareFormalAssuranceProjectionGeneric
 HealthcareFormalAssuranceProjectionMethods)
