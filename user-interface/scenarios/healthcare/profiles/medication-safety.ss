;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/modules/governance/objects
                 poo-flow-governance-precondition
                 poo-flow-governance-threat)
        (only-in :poo-flow/modules/authorization/objects
                 poo-flow-authorization-capability)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-concept ontology-relation ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export MedicationSafetyProfile)

(.def (MedicationSafetyProfile self HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/medication-safety")
  (name 'medication-safety)
  (profile-imports =>.+
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile))
  (concept-declarations =>.+
   (.o medication: (ontology-concept 'Medication '(BaseEntity) '())
       administration:
       (ontology-concept 'Administration '(Action) '(review-required))
       medication-order:
       (ontology-concept 'MedicationOrder '(Action) '(review-required))
       contraindication:
       (ontology-concept 'Contraindication '(Evidence) '())))
  (relation-declarations =>.+
   (.o administered-to:
       (ontology-relation
        'ADMINISTERED_TO 'Administration 'Patient '(review-required))
       contraindicated-by:
       (ontology-relation
        'CONTRAINDICATED_BY 'Medication 'Contraindication '())
       order-for-patient:
       (ontology-relation 'ORDER_FOR_PATIENT 'MedicationOrder 'Patient '(required))
       assigned-provider:
       (ontology-relation 'ASSIGNED_PROVIDER 'MedicationOrder 'Provider '(required))))
  (source-declarations =>.+
   (.o cedar-medication-policy:
       (ontology-source
        "healthcare/medication/authorization/policy"
        "user-interface/scenarios/healthcare/authorization/medication-safety.cedar"
        'cedar 'scenario 'healthcare #f)
       cedar-medication-revocation:
       (ontology-source
        "healthcare/medication/authorization/revocation"
        "user-interface/scenarios/healthcare/authorization/medication-revocation.cedar"
        'cedar 'scenario 'healthcare #f)
       cedar-healthcare-schema:
       (ontology-source
        "healthcare/medication/authorization/schema"
        "user-interface/scenarios/healthcare/authorization/schema.json"
        'json 'scenario 'healthcare #f)))
  (rule-declarations =>.+ (.o))
  (threat-declarations =>.+
   (.o contraindication-evidence-drift:
       (poo-flow-governance-threat
        "healthcare/medication/threat/contraindication-evidence-drift"
        'critical
        'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/medication/precondition/reconciliation-observed"
          #t
          "evidence:post-operative-medication-reconciliation"))
        mitigations:
        '("medication reconciliation bound to encounter evidence"))))
  (policies (.o medication-change: 'review-required
                disclosure: 'minimum-necessary))
  (capability-declarations =>.+
   (.o administer-medication:
       (poo-flow-authorization-capability
        "healthcare/medication/capability/administer"
        "Healthcare::Action::\"administerMedication\""
        4101
        'elevated)))
  (query-declarations =>.+ (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((medication-reconciliation-observed?
         . "healthcare/medication/threat/contraindication-evidence-drift"))))))
