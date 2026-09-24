;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda declares content-bound queries. Gerbil Parser owns syntax; an MRR
;;; Rust Runtime may later consume the parser's native FFI and these sources.
;;; This Scheme package neither links MRR nor invents a subprocess transport.
(import (only-in :clan/poo/object .o .ref)
        (only-in :gerbil/core hash-get hash-put!)
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
        (only-in :poo-flow/src/modules/query/objects
                 PooFlowGqlQueryLanguage.
                 PooFlowGqlQueryProgram.
                 PooFlowQueryNode. PooFlowQueryStep. PooFlowQueryPath.
                 PooFlowQueryProperty. PooFlowQueryLiteral.
                 PooFlowQueryEquals. PooFlowQueryProjection.
                 poo-flow-query-result-contract)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyQuery. ontology-source
                 ontology-reasoning-query-property))

(export CaseProfileRelationsSource ProfileImpactSource
        PrescriptionCausalTrajectorySource
        CaseProfileRelationsProgram ProfileImpactProgram
        PrescriptionCausalTrajectoryProgram
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

;;; These are GQL semantic programs authored as inheritable POO objects.
;;; POO Flow projects them deterministically; gerbil-parser independently
;;; validates the resulting standard GQL source at the qualification boundary.
(def CaseProfileRelationsProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'healthcare-case-profile-relations-program
      match:
      (.o (:: @ PooFlowQueryPath.)
          start: (.o (:: @ PooFlowQueryNode.) binding: 's label: 'Scenario)
          next:
          (.o (:: @ PooFlowQueryStep.) relation: 'HAS_CASE
              target: (.o (:: @ PooFlowQueryNode.) binding: 'c label: 'Case)
              next:
              (.o (:: @ PooFlowQueryStep.) relation: 'HAS_EFFECTIVE_PROFILE
                  target:
                  (.o (:: @ PooFlowQueryNode.) binding: 'p label: 'Profile))))
      where:
      (.o (:: @ PooFlowQueryEquals.)
          left: (.o (:: @ PooFlowQueryProperty.) binding: 's property: 'identity)
          right:
          (.o (:: @ PooFlowQueryLiteral.)
              literal-kind: 'string value: "healthcare"))
      project:
      (.o (:: @ PooFlowQueryProjection.)
          expression:
          (.o (:: @ PooFlowQueryProperty.) binding: 's property: 'identity)
          next:
          (.o (:: @ PooFlowQueryProjection.)
              expression:
              (.o (:: @ PooFlowQueryProperty.) binding: 'c property: 'id)
              next:
              (.o (:: @ PooFlowQueryProjection.)
                  expression:
                  (.o (:: @ PooFlowQueryProperty.)
                      binding: 'p property: 'identity))))))

(def ProfileImpactProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'healthcare-profile-impact-program
      match:
      (.o (:: @ PooFlowQueryPath.)
          start: (.o (:: @ PooFlowQueryNode.) binding: 'c label: 'Case)
          next:
          (.o (:: @ PooFlowQueryStep.) relation: 'HAS_EFFECTIVE_PROFILE
              target: (.o (:: @ PooFlowQueryNode.) binding: 'p label: 'Profile)
              next:
              (.o (:: @ PooFlowQueryStep.) relation: 'DECLARES_SOURCE
                  target:
                  (.o (:: @ PooFlowQueryNode.) binding: 'src label: 'Source))))
      where:
      (.o (:: @ PooFlowQueryEquals.)
          left:
          (.o (:: @ PooFlowQueryProperty.) binding: 'src property: 'identity)
          right:
          (.o (:: @ PooFlowQueryLiteral.) literal-kind: 'string
              value: "healthcare/medication/authorization/policy"))
      project:
      (.o (:: @ PooFlowQueryProjection.)
          expression: (.o (:: @ PooFlowQueryProperty.) binding: 'c property: 'id)
          next:
          (.o (:: @ PooFlowQueryProjection.)
              expression:
              (.o (:: @ PooFlowQueryProperty.) binding: 'p property: 'identity)
              next:
              (.o (:: @ PooFlowQueryProjection.)
                  expression:
                  (.o (:: @ PooFlowQueryProperty.)
                      binding: 'src property: 'identity))))))

(def PrescriptionCausalTrajectoryProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'healthcare-prescription-causal-trajectory-program
      match:
      (.o (:: @ PooFlowQueryPath.)
          start:
          (.o (:: @ PooFlowQueryNode.) binding: 'prescription label: 'CausalEvent)
          next:
          (.o (:: @ PooFlowQueryStep.) relation: 'CAUSAL_PARENT
              target:
              (.o (:: @ PooFlowQueryNode.) binding: 'event label: 'CausalEvent)))
      where:
      (.o (:: @ PooFlowQueryEquals.)
          left:
          (.o (:: @ PooFlowQueryProperty.)
              binding: 'prescription property: 'identity)
          right:
          (.o (:: @ PooFlowQueryLiteral.) literal-kind: 'string
              value: "ai-tmp-smx-recommendation-1"))
      project:
      (.o (:: @ PooFlowQueryProjection.)
          expression:
          (.o (:: @ PooFlowQueryProperty.)
              binding: 'prescription property: 'identity)
          next:
          (.o (:: @ PooFlowQueryProjection.)
              expression:
              (.o (:: @ PooFlowQueryProperty.) binding: 'event property: 'identity)
              next:
              (.o (:: @ PooFlowQueryProjection.)
                  expression:
                  (.o (:: @ PooFlowQueryProperty.)
                      binding: 'event property: 'modality))))))

(def HealthcareCaseProfileRelationsQuery
  (.o (:: @ OntologyQuery.)
      identity: 'healthcare-case-profile-relations
      version: "1"
      semantic-revision:
      "sha256:7a3a88a9ebd24cd738d426c0def633247d1a0fc13e9e37cca13bb23e90ba0c63"
      element-space-identity: 'healthcare/ontology-reasoning
      language: PooFlowGqlQueryLanguage.
      program: CaseProfileRelationsProgram
      result-bound: 4096
      completeness-requirement: 'complete
      evidence-requirements: '(source-content-id provenance-root result-digest)
      visibility-request: 'organization
      result-contract:
      (poo-flow-query-result-contract
       'healthcare/case-profile-relations-result 'relation-row
       '(source target relation) 4096)
      source: CaseProfileRelationsSource
      expected-source-content-id:
      "sha256:7a3a88a9ebd24cd738d426c0def633247d1a0fc13e9e37cca13bb23e90ba0c63"
      graph-kind: 'ontology-reasoning))

(def HealthcareProfileImpactQuery
  (.o (:: @ OntologyQuery.)
      identity: 'healthcare-profile-impact
      version: "1"
      semantic-revision:
      "sha256:0b9d8aa59e93dc771235284e0b6bf3a11479f55b10877f60cfb4bcfb8566dbc9"
      element-space-identity: 'healthcare/ontology-reasoning
      language: PooFlowGqlQueryLanguage.
      program: ProfileImpactProgram
      result-bound: 4096
      completeness-requirement: 'complete
      evidence-requirements: '(source-content-id provenance-root result-digest)
      visibility-request: 'organization
      result-contract:
      (poo-flow-query-result-contract
       'healthcare/profile-impact-result 'impact-row
       '(profile affected-case trajectory) 4096)
      source: ProfileImpactSource
      expected-source-content-id:
      "sha256:0b9d8aa59e93dc771235284e0b6bf3a11479f55b10877f60cfb4bcfb8566dbc9"
      graph-kind: 'ontology-reasoning))

(def HealthcarePrescriptionCausalTrajectoryQuery
  (.o (:: @ OntologyQuery.)
      identity: 'healthcare-prescription-causal-trajectory
      version: "1"
      semantic-revision:
      "sha256:0a67578de657faeaf683830eee701b43e67419997ae58b03b49f86732626f8f1"
      element-space-identity: 'healthcare/ontology-reasoning
      language: PooFlowGqlQueryLanguage.
      program: PrescriptionCausalTrajectoryProgram
      result-bound: 4096
      completeness-requirement: 'complete
      evidence-requirements: '(source-content-id provenance-root result-digest)
      visibility-request: 'organization
      result-contract:
      (poo-flow-query-result-contract
       'healthcare/prescription-causal-trajectory-result 'trajectory-row
       '(event modality predecessor impact) 4096)
      source: PrescriptionCausalTrajectorySource
      expected-source-content-id:
      "sha256:0a67578de657faeaf683830eee701b43e67419997ae58b03b49f86732626f8f1"
      graph-kind: 'ontology-reasoning))

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
  (def (index values)
    (let (table (make-hash-table))
      (for-each (lambda (value) (hash-put! table value #t)) values)
      table))
  (def (unique-values? values)
    (let (seen (make-hash-table))
      (every (lambda (value)
               (if (hash-get seen value)
                 #f
                 (begin (hash-put! seen value #t) #t)))
             values)))
  (def (covered? ids edges endpoint)
    (let (covered-ids (index (map endpoint edges)))
      (every (lambda (id) (hash-get covered-ids id)) ids)))
  (let* ((scenario-nodes (nodes-of 'scenario))
         (case-nodes (nodes-of 'case))
         (profile-nodes (nodes-of 'profile))
         (has-case-edges (edges-of 'HAS_CASE))
         (has-profile-edges (edges-of 'HAS_EFFECTIVE_PROFILE))
         (scenario-ids (map poo-flow-graph-node-id scenario-nodes))
         (case-ids (map poo-flow-graph-node-id case-nodes))
         (profile-ids (map poo-flow-graph-node-id profile-nodes))
         (scenario-index (index scenario-ids))
         (case-index (index case-ids))
         (profile-index (index profile-ids))
         (selected-edges (append has-case-edges has-profile-edges)))
    (unless (and (= (length scenario-nodes) 1)
                 (pair? case-nodes)
                 (pair? profile-nodes)
                 (unique-values? (append scenario-ids case-ids profile-ids))
                 (unique-values?
                  (map (lambda (edge)
                         (list (poo-flow-graph-edge-kind edge)
                               (poo-flow-graph-edge-from edge)
                               (poo-flow-graph-edge-to edge)))
                       selected-edges))
                 (equal? (ontology-reasoning-query-property
                          (car scenario-nodes) 'identity)
                         "healthcare")
                 (every (lambda (edge)
                          (and (hash-get scenario-index
                                         (poo-flow-graph-edge-from edge))
                               (hash-get case-index
                                         (poo-flow-graph-edge-to edge))))
                        has-case-edges)
                 (every (lambda (edge)
                          (and (hash-get case-index
                                         (poo-flow-graph-edge-from edge))
                               (hash-get profile-index
                                         (poo-flow-graph-edge-to edge))))
                        has-profile-edges)
                 (covered? case-ids has-case-edges poo-flow-graph-edge-to)
                 (covered? profile-ids has-profile-edges
                           poo-flow-graph-edge-to))
      (error "Healthcare property source is not a closed Case/Profile graph"
             graph))
    (.o kind: 'lambda-episteme.healthcare-case-profile-property-source
        query: HealthcareCaseProfileRelationsQuery
        scenarios: (map row scenario-nodes)
        cases: (map row case-nodes)
        profiles: (map row profile-nodes)
        has-cases: (map relation has-case-edges)
        has-effective-profiles: (map relation has-profile-edges))))
