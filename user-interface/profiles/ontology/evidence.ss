;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation))

(export EvidenceProfile)

(.def (EvidenceProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/evidence")
  (name 'evidence)
  (.add-concept
   (.o base-entity: (ontology-concept 'BaseEntity '() '())
       actor: (ontology-concept 'Actor '(BaseEntity) '())
       action: (ontology-concept 'Action '(BaseEntity) '())
       evidence:
       (ontology-concept 'Evidence '(BaseEntity) '(provenance-required))
       lifespan: (ontology-concept 'Lifespan '(BaseEntity) '(ordered-time))))
  (.add-relation
   (.o depends-on:
       (ontology-relation 'dependsOn 'BaseEntity 'BaseEntity '(acyclic))
       part-of: (ontology-relation 'partOf 'BaseEntity 'BaseEntity '())
       performs: (ontology-relation 'performs 'Actor 'Action '())
       modifies: (ontology-relation 'modifies 'Action 'BaseEntity '())
       creates: (ontology-relation 'creates 'Action 'BaseEntity '())
       based-on:
       (ontology-relation 'basedOn 'Action 'Evidence '(evidence-required))
       has-lifespan:
       (ontology-relation 'hasLifespan 'BaseEntity 'Lifespan '())
       supersedes:
       (ontology-relation
        'supersedes 'BaseEntity 'BaseEntity '(irreflexive))))
  (policies (.o source-binding: 'digest-required
                missing-evidence: 'unknown))
  (.add-query
   (.o evidence-by-subject: 'evidence-by-subject
       provenance-chain: 'provenance-chain)))
