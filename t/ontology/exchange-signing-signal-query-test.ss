;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :gerbil-parser/languages/gql/iso-39075-2024/query-syntax
                 gql-query-program?)
        (only-in :poo-flow/modules/query/gql poo-flow-query->gql)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-source-content-identity)
        (only-in :poo-flow/modules/query/objects
                 poo-flow-query-element-space
                 poo-flow-query-execution-candidate)
        (only-in :poo-flow/modules/query/funs poo-flow-query-admit)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/signal-result
                 exchange-signing-signal-result-digest
                 exchange-signing-bind-signal-result)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/query
                 ExchangeSigningSignalQuery ExchangeSigningSignalSource))

(export exchange-signing-signal-query-test)

(def exchange-signing-signal-query-test
  (test-suite "Exchange signing GQL signal selection"
    (poo-flow-test-case "AST selects source-bearing signal observations"
      (let* ((source (poo-flow-query->gql ExchangeSigningSignalQuery))
             (selected (.ref ExchangeSigningSignalQuery
                             'selected-element-identities))
             (space
              (poo-flow-query-element-space
               'exchange/signing-signals
               (.ref ExchangeSigningSignalQuery 'semantic-revision)
               selected #t))
             (admission (poo-flow-query-admit ExchangeSigningSignalQuery space)))
        (check-equal? source ExchangeSigningSignalSource)
        (check-equal? (not (not (member 'backend-compromise selected))) #t)
        (check-equal? (not (not (member 'fixed-round-gas-limits selected))) #t)
        (check-equal? (not (not (member 'observed-admin-effect selected))) #t)
        (check-equal?
         source
         "MATCH (signal:SigningSignal)\nRETURN signal.identity, signal.evidenceSource, signal.admissionStatus\n")
        (check-equal?
         (poo-flow-query-source-content-identity ExchangeSigningSignalQuery)
         (.ref ExchangeSigningSignalQuery 'semantic-revision))
        (check-equal?
         (gql-query-program? (.ref ExchangeSigningSignalQuery 'program)) #t)
        (check-equal? (.ref admission 'accepted?) #t)
        (check-equal? (.ref admission 'runtime-executed?) #f)))

    (poo-flow-test-case "binds actual rows to the exact candidate digest"
      (let* ((rows '((duplicate-request-id signer-ledger admitted)))
             (candidate
              (poo-flow-query-execution-candidate
               'mrr 'exchange-signing-signals "1"
               (.ref ExchangeSigningSignalQuery 'semantic-revision)
               (poo-flow-query-source-content-identity ExchangeSigningSignalQuery)
               'gerbil-parser "sha256:unverified-provider-root"
               (exchange-signing-signal-result-digest rows) 1 #t))
             (bound (exchange-signing-bind-signal-result candidate rows))
             (changed
              (exchange-signing-bind-signal-result
               candidate '((one-use-request-record signer-ledger admitted))))
             (unknown
              (exchange-signing-bind-signal-result
               candidate '((invented-signal signer-ledger admitted))))
             (wrong-query
              (exchange-signing-bind-signal-result
               (poo-flow-query-execution-candidate
                'mrr 'different-query "1"
                (.ref ExchangeSigningSignalQuery 'semantic-revision)
                (poo-flow-query-source-content-identity
                 ExchangeSigningSignalQuery)
                'gerbil-parser "sha256:unverified-provider-root"
                (exchange-signing-signal-result-digest rows) 1 #t)
               rows))
             (incomplete
              (exchange-signing-bind-signal-result
               (poo-flow-query-execution-candidate
                'mrr 'exchange-signing-signals "1"
                (.ref ExchangeSigningSignalQuery 'semantic-revision)
                (poo-flow-query-source-content-identity
                 ExchangeSigningSignalQuery)
                'gerbil-parser "sha256:unverified-provider-root"
                (exchange-signing-signal-result-digest rows) 1 #f)
               rows)))
        (check-equal? (.ref bound 'integrity-bound?) #t)
        (check-equal? (.ref bound 'rows) rows)
        (check-equal? (.ref bound 'provenance-verified?) #f)
        (check-equal? (.ref bound 'gql-executed-by-case?) #f)
        (check-equal? (.ref changed 'integrity-bound?) #f)
        (check-equal? (.ref changed 'rows) '())
        (check-equal? (.ref unknown 'integrity-bound?) #f)
        (check-equal? (.ref unknown 'rows) '())
        (check-equal? (.ref wrong-query 'integrity-bound?) #f)
        (check-equal? (.ref incomplete 'integrity-bound?) #f)))))
