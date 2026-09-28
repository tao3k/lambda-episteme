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
        ExchangeSigningEdgeSource
        ExchangeSigningSignalProgram
        ExchangeSigningSignalQuery
        ExchangeSigningSignalSource)

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
      selected-element-identities:
      '(backend payload queue signer chain-transfer outflow
        interface display admin-change wallet-control bybit-outflow
        internal-api queue-producer address-map)
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

;;; Query syntax for hypothesis discriminators. Execution, provenance checks,
;;; and binding of selected results to admitted Ascent inputs remain external.
(def ExchangeSigningSignalProgram
  (.o (:: @ PooFlowGqlQueryProgram.)
      identity: 'exchange-signing-signals
      match:
      (.o (:: @ GqlQueryPath.)
          start: (.o (:: @ GqlQueryNode.)
                     binding: 'signal label: 'SigningSignal))
      project:
      (.o (:: @ GqlQueryProjection.)
          expression:
          (.o (:: @ GqlQueryProperty.) binding: 'signal property: 'identity)
          next:
          (.o (:: @ GqlQueryProjection.)
              expression:
              (.o (:: @ GqlQueryProperty.)
                  binding: 'signal property: 'evidenceSource)
              next:
              (.o (:: @ GqlQueryProjection.)
                  expression:
                  (.o (:: @ GqlQueryProperty.)
                      binding: 'signal property: 'admissionStatus))))))

(def ExchangeSigningSignalSource
  (poo-flow-query-program->gql ExchangeSigningSignalProgram))

(def ExchangeSigningSignalSourceId
  (string-append "sha256:"
                 (hex-encode (sha256 (string->utf8 ExchangeSigningSignalSource)))))

(def ExchangeSigningSignalQuery
  (.o (:: @ PooFlowQuery.)
      identity: 'exchange-signing-signals
      version: "1"
      semantic-revision: ExchangeSigningSignalSourceId
      element-space-identity: 'exchange/signing-signals
      selected-element-identities:
      '(unauthorized-outflow multi-chain-outflow
        backend-compromise spoofed-transaction-data
        no-private-key-compromise wallet-signed-transfers
        cross-chain-bursts fixed-round-gas-limits
        private-key-compromise
        withdrawal-without-intent duplicate-request-id
        orphan-queue-message destination-mismatch display-byte-mismatch
        observed-admin-effect complete-transfer-only-signing-ledger
        authenticated-intent-exact one-use-request-record
        verified-producer-chain independently-matched-destination
        trusted-rendering-match)
      language: PooFlowGqlQueryLanguage.
      program: ExchangeSigningSignalProgram
      result-bound: 64
      completeness-requirement: 'complete
      evidence-requirements:
      '(source-content-identity provenance-root result-digest)
      result-contract:
      (poo-flow-query-result-contract
       'exchange/signing-signal-rows 'relation-row
       '(signal evidenceSource admissionStatus) 64)))
