;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/ai-assisted-antibiotic-prescription/objects
                 AIAssistedAntibioticPrescriptionCasePrototype)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/ai-clinical-decision-support
                 AIClinicalDecisionSupportProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
                 MedicationSafetyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/pharmacology-safety
                 PharmacologySafetyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
                 HealthcareScenario))

(export AIAssistedAntibioticPrescriptionCase)

;; The ordinary Case selects maintained values and records observations.
;; The inherited prototype owns clinical events, trajectory, Cedar declaration,
;; and relation graph; native slots remain available for deliberate overrides.
(.def (AIAssistedAntibioticPrescriptionCase
       @ AIAssistedAntibioticPrescriptionCasePrototype)
  (case-id 'ai-assisted-antibiotic-prescription)
  (scenario HealthcareScenario)
  (profile-selection =>.+
   (.o common:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile)
       healthcare:
       (.o base: HealthcareBaseProfile)
       medication:
       (.o medication-safety: MedicationSafetyProfile
           pharmacology-safety: PharmacologySafetyProfile)
       ai-assistance:
       (.o clinical-decision-support: AIClinicalDecisionSupportProfile)))
  (ai-advisory-only? #t)
  (ai-basis-reviewable? #t)
  (independent-clinician-review? #t)
  (medication-reconciliation-observed? #t)
  (interaction-review-observed? #t)
  (monitoring-plan-observed? #t))
