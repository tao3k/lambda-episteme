;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :poo-flow/src/graph/types
                  graph poo-flow-graph-edge poo-flow-graph-node)
         (graph Graph))
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/education/profiles/base
                 EducationBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/education/scenario
                 EducationScenario))

(export EnrollmentContextCase)

(.def (EnrollmentContextCase @ OntologyCase)
  (case-id 'enrollment-context)
  (scenario EducationScenario)
  (.use-composition
   (.o education:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile
           base: EducationBaseProfile)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'enrollment-context
       .add-node:
       (.o learner-1: (poo-flow-graph-node 'learner-1 'Learner)
           course-1: (poo-flow-graph-node 'course-1 'Course)
           enrollment-1:
           (poo-flow-graph-node 'enrollment-1 'Enrollment))
       .add-edge:
       (.o learner-enrollment:
           (poo-flow-graph-edge 'learner-1 'enrollment-1 'enrollsIn)
           enrollment-course:
           (poo-flow-graph-edge 'enrollment-1 'course-1 'forCourse)))))
