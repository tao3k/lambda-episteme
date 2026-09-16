;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-acyclic-relation-rule
                 ontology-concept ontology-relation
                 ontology-required-relation-rule ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export SoftwareEngineeringBaseProfile)

(.def (SoftwareEngineeringBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/software-engineering/base")
  (name 'software-engineering-base)
  (profile-scope 'scenario)
  (scenario 'software-engineering)
  (.import (.o evidence: EvidenceProfile))
  (.add-concept
   (.o software-component:
       (ontology-concept 'SoftwareComponent '(BaseEntity) '())
       decision-record:
       (ontology-concept 'DecisionRecord '(Evidence) '(decision-status))
       implementation-artifact:
       (ontology-concept 'ImplementationArtifact '(BaseEntity) '())))
  (.add-relation
   (.o implements-decision:
       (ontology-relation
        'implementsDecision 'ImplementationArtifact 'DecisionRecord
        '(decision-required))
       owns-artifact:
       (ontology-relation 'ownsArtifact 'Actor 'ImplementationArtifact '())))
  (policies (.o dependency-graph: 'acyclic
                implementation-decision-link: 'required))
  (.add-source
   (.o architecture-decision-policy:
       (ontology-source
        "ontology/software-engineering/architecture-decision-policy"
        "ontology/10_Software_Engineering/policies/architectural_decision_making.md"
        'markdown 'scenario 'software-engineering #f)))
  (.add-rule
   (.o architecture-dependency:
       (ontology-acyclic-relation-rule
        'architecture-dependency-dag 'dependsOn)
       implementation-decision:
       (ontology-required-relation-rule
        'implementation-must-link-decision
        'ImplementationArtifact 'implementsDecision 'source)))
  (.add-query (.o)))
