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
  (profile-imports =>.+ (.o evidence: EvidenceProfile))
  (concept-declarations =>.+
   (.o software-component:
       (ontology-concept 'SoftwareComponent '(BaseEntity) '())
       decision-record:
       (ontology-concept 'DecisionRecord '(Evidence) '(decision-status))
       implementation-artifact:
       (ontology-concept 'ImplementationArtifact '(BaseEntity) '())))
  (relation-declarations =>.+
   (.o implements-decision:
       (ontology-relation
        'implementsDecision 'ImplementationArtifact 'DecisionRecord
        '(decision-required))
       owns-artifact:
       (ontology-relation 'ownsArtifact 'Actor 'ImplementationArtifact '())))
  (policies (.o dependency-graph: 'acyclic
                implementation-decision-link: 'required))
  (source-declarations =>.+
   (.o architecture-decision-policy:
       (ontology-source
        "ontology/software-engineering/architecture-decision-policy"
        "user-interface/scenarios/software-engineering/sources/architectural-decision-making.md"
        'markdown 'scenario 'software-engineering #f)))
  (rule-declarations =>.+
   (.o architecture-dependency:
       (ontology-acyclic-relation-rule
        'architecture-dependency-dag 'dependsOn)
       implementation-decision:
       (ontology-required-relation-rule
        'implementation-must-link-decision
        'ImplementationArtifact 'implementsDecision 'source)))
  (query-declarations =>.+ (.o)))
