;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export PrivacyProfile)

(.def (PrivacyProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/privacy")
  (name 'privacy)
  (.import (.o evidence: EvidenceProfile))
  (.add-concept
   (.o classification: (ontology-concept 'Classification '(BaseEntity) '())
       authorization: (ontology-concept 'Authorization '(Evidence) '())
       redaction:
       (ontology-concept 'Redaction '(Action) '(source-preserving))))
  (.add-relation
   (.o classified-as:
       (ontology-relation 'CLASSIFIED_AS 'BaseEntity 'Classification '())
       authorized-by:
       (ontology-relation 'AUTHORIZED_BY 'Action 'Authorization '(required))
       redacted-by:
       (ontology-relation
        'REDACTED_BY 'Evidence 'Redaction '(source-preserving))))
  (policies (.o disclosure: 'explicit-authorization
                redaction: 'source-preserving))
  (.add-query (.o)))
