;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/vehicle/profiles/base
                 VehicleBaseProfile))

(export VehicleTaraTreatmentProfile)

;; A selected external assessment is evidence, not an approval decision.
;; The profile requires each treatment goal to name both its origin and its
;; executable policy candidate; publication remains a separate authority.
(.def (VehicleTaraTreatmentProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/vehicle/tara-treatment")
  (name 'vehicle-tara-treatment)
  (profile-scope 'scenario)
  (scenario 'vehicle)
  (profile-imports =>.+ (.o vehicle: VehicleBaseProfile))
  (concept-declarations =>.+
   (.o external-assessment:
       (ontology-concept 'ExternalTaraAssessment '(Evidence) '())
       treatment-goal:
       (ontology-concept 'VehicleTreatmentGoal '(BaseEntity) '())
       policy-candidate:
       (ontology-concept 'VehiclePolicyCandidate '(BaseEntity) '())))
  (relation-declarations =>.+
   (.o sourced-from:
       (ontology-relation 'sourcedFromAssessment
                          'VehicleTreatmentGoal 'ExternalTaraAssessment '())
       realized-by:
       (ontology-relation 'realizedByPolicy
                          'VehicleTreatmentGoal 'VehiclePolicyCandidate '())
       governs-release:
       (ontology-relation 'governsRelease
                          'VehiclePolicyCandidate 'VehicleSoftwareRelease '())))
  (rule-declarations =>.+
   (.o source-required:
       (ontology-required-relation-rule
        'treatment-goal-requires-assessment
        'VehicleTreatmentGoal 'sourcedFromAssessment 'source)
       policy-required:
       (ontology-required-relation-rule
        'treatment-goal-requires-policy
        'VehicleTreatmentGoal 'realizedByPolicy 'source)
       release-required:
       (ontology-required-relation-rule
        'vehicle-policy-requires-release
        'VehiclePolicyCandidate 'governsRelease 'source)))
  (query-declarations =>.+ (.o)))
