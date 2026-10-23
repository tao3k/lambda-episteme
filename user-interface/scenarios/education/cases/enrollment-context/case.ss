;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :core/graph/types
                  graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-node)
         (graph Graph))
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/education/profiles/base
                 EducationBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/education/scenario
                 EducationScenario))

(export EnrollmentContextCase)

(.def (EnrollmentContextCase @ OntologyCase)
  (case-id 'enrollment-context)
  (scenario EducationScenario)
  (profile-selection =>.+
   (.o education:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile
           base: EducationBaseProfile)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'enrollment-context
       node-declarations:
       (.o learner-1: (agentic-ai-lab-graph-node 'learner-1 'Learner)
           course-1: (agentic-ai-lab-graph-node 'course-1 'Course)
           enrollment-1:
           (agentic-ai-lab-graph-node 'enrollment-1 'Enrollment))
       edge-declarations:
       (.o learner-enrollment:
           (agentic-ai-lab-graph-edge 'learner-1 'enrollment-1 'enrollsIn)
           enrollment-course:
           (agentic-ai-lab-graph-edge 'enrollment-1 'course-1 'forCourse)))))
