;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :gerbil-parser/languages/gql/iso-39075-2024/query-syntax
                 gql-query-program?)
        (only-in :poo-flow/modules/query/gql poo-flow-query->gql)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-source-content-identity)
        (only-in :poo-flow/modules/query/objects
                 poo-flow-query-element-space)
        (only-in :poo-flow/modules/query/funs poo-flow-query-admit)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/signal-result
                 exchange-signing-signal-nodes
                 exchange-signing-run-signal-query)
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

    (poo-flow-test-case "Scheme GQL selects source-labelled POO nodes"
      (let* ((rows '((duplicate-request-id signer-ledger admitted)))
             (result
              (exchange-signing-run-signal-query
               (exchange-signing-signal-nodes rows))))
        (check-equal? (.ref result 'rows) rows)
        (check-equal? (.ref result 'scheme-executed?) #t)
        (check-equal? (.ref result 'provenance-verified?) #f)
        (check-equal?
         (.ref result 'query-source-identity)
         (.ref ExchangeSigningSignalQuery 'semantic-revision))
        (check-exception
         (exchange-signing-signal-nodes
          '((duplicate-request-id signer-ledger admitted)
            (duplicate-request-id other-ledger admitted)))
         true)
        (check-exception
         (exchange-signing-signal-nodes
          '((invented-signal signer-ledger admitted)))
         true)))))
