;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile))

(export EducationBaseProfile)

(.def (EducationBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/education/base")
  (name 'education-base)
  (profile-scope 'scenario)
  (scenario 'education)
  (profile-imports =>.+ (.o evidence: EvidenceProfile privacy: PrivacyProfile))
  (concept-declarations =>.+
   (.o learner: (ontology-concept 'Learner '(Actor) '(purpose-limited))
       instructor: (ontology-concept 'Instructor '(Actor) '())
       course: (ontology-concept 'Course '(BaseEntity) '())
       department: (ontology-concept 'Department '(BaseEntity) '())
       enrollment: (ontology-concept 'Enrollment '(Action) '(context-required))))
  (relation-declarations =>.+
   (.o enrolls-in: (ontology-relation 'enrollsIn 'Learner 'Enrollment '())
       for-course:
       (ontology-relation 'forCourse 'Enrollment 'Course '(required))
       teaches: (ontology-relation 'teaches 'Instructor 'Course '())
       offered-by: (ontology-relation 'offeredBy 'Course 'Department '())))
  (policies (.o enrollment-context: 'required
                learner-data: 'purpose-limited))
  (rule-declarations =>.+
   (.o enrollment-learner:
       (ontology-required-relation-rule
        'enrollment-must-link-learner 'Enrollment 'enrollsIn 'target)
       enrollment-course:
       (ontology-required-relation-rule
        'enrollment-must-link-course 'Enrollment 'forCourse 'source)))
  (query-declarations =>.+ (.o)))
