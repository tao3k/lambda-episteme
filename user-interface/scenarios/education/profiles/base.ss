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
  (.import (.o evidence: EvidenceProfile privacy: PrivacyProfile))
  (.add-concept
   (.o learner: (ontology-concept 'Learner '(Actor) '(purpose-limited))
       instructor: (ontology-concept 'Instructor '(Actor) '())
       course: (ontology-concept 'Course '(BaseEntity) '())
       department: (ontology-concept 'Department '(BaseEntity) '())
       enrollment: (ontology-concept 'Enrollment '(Action) '(context-required))))
  (.add-relation
   (.o enrolls-in: (ontology-relation 'enrollsIn 'Learner 'Enrollment '())
       for-course:
       (ontology-relation 'forCourse 'Enrollment 'Course '(required))
       teaches: (ontology-relation 'teaches 'Instructor 'Course '())
       offered-by: (ontology-relation 'offeredBy 'Course 'Department '())))
  (policies (.o enrollment-context: 'required
                learner-data: 'purpose-limited))
  (.add-rule
   (.o enrollment-learner:
       (ontology-required-relation-rule
        'enrollment-must-link-learner 'Enrollment 'enrollsIn 'target)
       enrollment-course:
       (ontology-required-relation-rule
        'enrollment-must-link-course 'Enrollment 'forCourse 'source)))
  (.add-query
   (.o enrollments-missing-context: 'enrollments-missing-context)))
