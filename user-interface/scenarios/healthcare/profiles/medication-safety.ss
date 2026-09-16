;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-concept ontology-relation)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export MedicationSafetyProfile)

(.def (MedicationSafetyProfile @ HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/medication-safety")
  (name 'medication-safety)
  (.import
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile))
  (.add-concept
   (.o medication: (ontology-concept 'Medication '(BaseEntity) '())
       administration:
       (ontology-concept 'Administration '(Action) '(review-required))
       contraindication:
       (ontology-concept 'Contraindication '(Evidence) '())))
  (.add-relation
   (.o administered-to:
       (ontology-relation
        'ADMINISTERED_TO 'Administration 'Patient '(review-required))
       contraindicated-by:
       (ontology-relation
        'CONTRAINDICATED_BY 'Medication 'Contraindication '())))
  (.add-source (.o))
  (.add-rule (.o))
  (policies (.o medication-change: 'review-required
                disclosure: 'minimum-necessary))
  (.add-query (.o medication-safety-review: 'medication-safety-review)))
