;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; POO-authored GQL selection contract. MRR owns execution and result
;;; admission; the projected source is parser-checked by the Case test.
(import (only-in :clan/poo/object .o)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/query/objects
                 PooFlowQuery. PooFlowGqlQueryLanguage.
                 PooFlowGqlQueryProgram.
                 GqlQueryNode. GqlQueryStep. GqlQueryPath.
                 GqlQueryProperty. GqlQueryProjection.
                 poo-flow-query-result-contract)
        (only-in :poo-flow/modules/query/gql
                 poo-flow-query-program->gql))

(export ExchangeSigningEdgeProgram
        ExchangeSigningEdgeQuery
        ExchangeSigningEdgeSource)

(def ExchangeSigningEdgeProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'exchange-signing-edges
      match:
      (.o (:: @ GqlQueryPath.)
          start: (.o (:: @ GqlQueryNode.) binding: 'source label: 'SigningEvent)
          next:
          (.o (:: @ GqlQueryStep.) relation: 'CANDIDATE_NEXT
              target: (.o (:: @ GqlQueryNode.) binding: 'target label: 'SigningEvent)))
      project:
      (.o (:: @ GqlQueryProjection.)
          expression:
          (.o (:: @ GqlQueryProperty.) binding: 'source property: 'identity)
          next:
          (.o (:: @ GqlQueryProjection.)
              expression:
              (.o (:: @ GqlQueryProperty.) binding: 'target property: 'identity)
              next:
              (.o (:: @ GqlQueryProjection.)
                  expression:
                  (.o (:: @ GqlQueryProperty.)
                      binding: 'target property: 'evidenceSource)
                  next:
                  (.o (:: @ GqlQueryProjection.)
                      expression:
                      (.o (:: @ GqlQueryProperty.)
                          binding: 'target property: 'status)))))))

(def ExchangeSigningEdgeSource
  (poo-flow-query-program->gql ExchangeSigningEdgeProgram))

(def ExchangeSigningEdgeSourceId
  (string-append "sha256:"
                 (hex-encode (sha256 (string->utf8 ExchangeSigningEdgeSource)))))

(def ExchangeSigningEdgeQuery
  (.o (:: @ PooFlowQuery.)
      identity: 'exchange-signing-edges
      version: "1"
      semantic-revision: ExchangeSigningEdgeSourceId
      element-space-identity: 'exchange/signing-chain
      selected-element-identities: '(backend payload signer transfer outflow)
      language: PooFlowGqlQueryLanguage.
      program: ExchangeSigningEdgeProgram
      result-bound: 64
      completeness-requirement: 'complete
      evidence-requirements:
      '(source-content-identity provenance-root result-digest)
      result-contract:
      (poo-flow-query-result-contract
       'exchange/signing-edge-rows 'relation-row
       '(source target evidenceSource status) 64)))
