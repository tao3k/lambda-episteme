;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda declares content-bound queries. Gerbil Parser owns syntax; an MRR
;;; Rust Runtime may later consume the parser's native FFI and these sources.
;;; This Scheme package neither links MRR nor invents a subprocess transport.
(import (only-in :clan/poo/object .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-query ontology-source))

(export CaseProfileRelationsSource ProfileImpactSource
        PrescriptionCausalTrajectorySource
        HealthcareCaseProfileRelationsQuery
        HealthcareProfileImpactQuery
        HealthcarePrescriptionCausalTrajectoryQuery
        healthcare-query-source-path)

(def (digest text)
  (string-append "sha256:" (hex-encode (sha256 (string->utf8 text)))))

(def CaseProfileRelationsSource
  (ontology-source
   "healthcare/reasoning/case-profile-relations"
   "user-interface/scenarios/healthcare/reasoning/case-profile-relations.gql"
   'gql 'scenario 'healthcare #f))

(def ProfileImpactSource
  (ontology-source
   "healthcare/reasoning/profile-impact"
   "user-interface/scenarios/healthcare/reasoning/profile-impact.gql"
   'gql 'scenario 'healthcare #f))

(def PrescriptionCausalTrajectorySource
  (ontology-source
   "healthcare/reasoning/prescription-causal-trajectory"
   "user-interface/scenarios/healthcare/reasoning/prescription-causal-trajectory.gql"
   'gql 'scenario 'healthcare #f))

(def HealthcareCaseProfileRelationsQuery
  (ontology-query
   'healthcare-case-profile-relations "1"
   CaseProfileRelationsSource
   "sha256:7a3a88a9ebd24cd738d426c0def633247d1a0fc13e9e37cca13bb23e90ba0c63"
   'ontology-reasoning))

(def HealthcareProfileImpactQuery
  (ontology-query
   'healthcare-profile-impact "1"
   ProfileImpactSource
   "sha256:0b9d8aa59e93dc771235284e0b6bf3a11479f55b10877f60cfb4bcfb8566dbc9"
   'ontology-reasoning))

(def HealthcarePrescriptionCausalTrajectoryQuery
  (ontology-query
   'healthcare-prescription-causal-trajectory "1"
   PrescriptionCausalTrajectorySource
   "sha256:0a67578de657faeaf683830eee701b43e67419997ae58b03b49f86732626f8f1"
   'ontology-reasoning))

(def (healthcare-query-source-path query root)
  (let* ((source (.ref query 'source))
         (path (path-expand (.ref source 'path) root))
         (actual (digest (call-with-input-file path read-all-as-string))))
    (unless (equal? actual (.ref query 'expected-source-content-id))
      (error "GQL source changed without MRR query admission"
             (.ref query 'identity) actual))
    path))
