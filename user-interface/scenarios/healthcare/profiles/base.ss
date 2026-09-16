;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export HealthcareBaseProfile)

(.def (HealthcareBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/healthcare/base")
  (name 'healthcare-base)
  (profile-scope 'scenario)
  (scenario 'healthcare)
  (.import (.o evidence: EvidenceProfile))
  (.add-concept
   (.o patient: (ontology-concept 'Patient '(Actor) '(purpose-limited))
       provider: (ontology-concept 'Provider '(Actor) '())
       encounter:
       (ontology-concept 'Encounter '(Action) '(clinical-context-required))
       condition: (ontology-concept 'Condition '(BaseEntity) '())))
  (.add-relation
   (.o has-patient:
       (ontology-relation 'HAS_PATIENT 'Encounter 'Patient '(required))
       has-provider:
       (ontology-relation 'HAS_PROVIDER 'Encounter 'Provider '(required))
       has-condition:
       (ontology-relation 'HAS_CONDITION 'Encounter 'Condition '())))
  (policies (.o clinical-status: 'source-bound
                incomplete-scope: 'unknown))
  (.add-source
   (.o care-delivery-mapping:
       (ontology-source
        "ontology/healthcare/synthetic-care-delivery-mapping"
        "ontology/30_Healthcare/mappings/healthcare_synthetic_care_delivery.toml"
        'toml 'scenario 'healthcare #f)))
  (.add-rule
   (.o encounter-patient:
       (ontology-required-relation-rule
        'encounter-must-link-patient 'Encounter 'HAS_PATIENT 'source)
       encounter-provider:
       (ontology-required-relation-rule
        'encounter-must-link-provider 'Encounter 'HAS_PROVIDER 'source)))
  (.add-query (.o)))
