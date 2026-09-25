;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export HealthcareBaseProfilePrototype)

(.def (HealthcareBaseProfilePrototype @ OntologyProfile)
  (profile-scope 'scenario)
  (scenario 'healthcare)
  (profile-imports =>.+ (.o evidence: EvidenceProfile))
  (concept-declarations =>.+
   (.o patient: (ontology-concept 'Patient '(Actor) '(purpose-limited))
       provider: (ontology-concept 'Provider '(Actor) '())
       encounter:
       (ontology-concept 'Encounter '(Action) '(clinical-context-required))
       condition: (ontology-concept 'Condition '(BaseEntity) '())))
  (relation-declarations =>.+
   (.o has-patient:
       (ontology-relation 'HAS_PATIENT 'Encounter 'Patient '(required))
       has-provider:
       (ontology-relation 'HAS_PROVIDER 'Encounter 'Provider '(required))
       has-condition:
       (ontology-relation 'HAS_CONDITION 'Encounter 'Condition '())))
  (source-declarations =>.+
   (.o care-delivery-mapping:
       (ontology-source
        "ontology/healthcare/synthetic-care-delivery-mapping"
        "user-interface/scenarios/healthcare/sources/synthetic-care-delivery.toml"
        'toml 'scenario 'healthcare #f)))
  (rule-declarations =>.+
   (.o encounter-patient:
       (ontology-required-relation-rule
        'encounter-must-link-patient 'Encounter 'HAS_PATIENT 'source)
       encounter-provider:
       (ontology-required-relation-rule
        'encounter-must-link-provider 'Encounter 'HAS_PROVIDER 'source)))
  (query-declarations =>.+ (.o)))
