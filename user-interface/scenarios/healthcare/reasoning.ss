;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda declares content-bound queries. Gerbil Parser owns syntax; an MRR
;;; Rust Runtime may later consume the parser's native FFI and these sources.
;;; This Scheme package neither links MRR nor invents a subprocess transport.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/ports read-all-as-string)
        :std/list/list
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph? poo-flow-graph-id
                 poo-flow-graph-nodes poo-flow-graph-edges
                 poo-flow-graph-node-id poo-flow-graph-node-metadata
                 poo-flow-graph-edge-from poo-flow-graph-edge-to
                 poo-flow-graph-edge-kind)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-query ontology-source
                 ontology-reasoning-query-property))

(export CaseProfileRelationsSource ProfileImpactSource
        PrescriptionCausalTrajectorySource
        HealthcareCaseProfileRelationsQuery
        HealthcareProfileImpactQuery
        HealthcarePrescriptionCausalTrajectoryQuery
        healthcare-query-source-path
        healthcare-case-profile-property-source)

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

;;; Project the accepted POO reasoning graph into source-owned property rows.
;;; This is not an MRR catalog or a physical snapshot: MRR owns type identity
;;; and admission; MRR Data owns Arrow/CID materialization of these values.
(def (healthcare-case-profile-property-source graph)
  (unless (and (poo-flow-graph? graph)
               (equal? (poo-flow-graph-id graph)
                       '(ontology-reasoning healthcare)))
    (error "expected the Healthcare ontology reasoning graph" graph))
  (def (node-kind node)
    (let (entry (assq 'entity-kind (poo-flow-graph-node-metadata node)))
      (and entry (cdr entry))))
  (def (nodes-of entity-kind)
    (filter (lambda (node) (eq? (node-kind node) entity-kind))
            (poo-flow-graph-nodes graph)))
  (def (edges-of relation-kind)
    (filter (lambda (edge)
              (eq? (poo-flow-graph-edge-kind edge) relation-kind))
            (poo-flow-graph-edges graph)))
  (def (row node)
    (.o entity-id: (poo-flow-graph-node-id node)
        value: (ontology-reasoning-query-property
                node (if (eq? (node-kind node) 'case) 'id 'identity))))
  (def (relation edge)
    (.o source: (poo-flow-graph-edge-from edge)
        target: (poo-flow-graph-edge-to edge)))
  (let* ((scenario-nodes (nodes-of 'scenario))
         (case-nodes (nodes-of 'case))
         (profile-nodes (nodes-of 'profile))
         (has-case-edges (edges-of 'HAS_CASE))
         (has-profile-edges (edges-of 'HAS_EFFECTIVE_PROFILE))
         (scenario-ids (map poo-flow-graph-node-id scenario-nodes))
         (case-ids (map poo-flow-graph-node-id case-nodes))
         (profile-ids (map poo-flow-graph-node-id profile-nodes)))
    (unless (and (= (length scenario-nodes) 1)
                 (equal? (ontology-reasoning-query-property
                          (car scenario-nodes) 'identity)
                         "healthcare")
                 (every (lambda (edge)
                          (and (member (poo-flow-graph-edge-from edge)
                                       scenario-ids)
                               (member (poo-flow-graph-edge-to edge) case-ids)))
                        has-case-edges)
                 (every (lambda (edge)
                          (and (member (poo-flow-graph-edge-from edge) case-ids)
                               (member (poo-flow-graph-edge-to edge)
                                       profile-ids)))
                        has-profile-edges))
      (error "Healthcare property source is not a closed Case/Profile graph"
             graph))
    (.o kind: 'lambda-episteme.healthcare-case-profile-property-source
        query: HealthcareCaseProfileRelationsQuery
        scenarios: (map row scenario-nodes)
        cases: (map row case-nodes)
        profiles: (map row profile-nodes)
        has-cases: (map relation has-case-edges)
        has-effective-profiles: (map relation has-profile-edges))))
