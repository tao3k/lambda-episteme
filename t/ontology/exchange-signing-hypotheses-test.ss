;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :gerbil-parser/languages/gql/iso-39075-2024/query-syntax
                 gql-query-program?)
        (only-in :poo-flow/modules/query/gql poo-flow-query->gql)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-source-content-identity)
        (only-in :poo-flow/modules/query/objects
                 poo-flow-query-element-space)
        (only-in :poo-flow/modules/query/funs poo-flow-query-admit)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/query
                 ExchangeSigningSignalQuery ExchangeSigningSignalSource)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/hypotheses
                 ExchangeSigningPublicEvidence.
                 exchange-signing-compare-hypotheses))

(export exchange-signing-hypotheses-test)

(def (contains? rows value)
  (not (not (member value rows))))

(def exchange-signing-hypotheses-test
  (test-suite "Exchange signing hypothesis discriminators"
    (poo-flow-test-case "GQL AST selects provenance-bearing signal observations"
      (let* ((source (poo-flow-query->gql ExchangeSigningSignalQuery))
             (space
              (poo-flow-query-element-space
               'exchange/signing-signals
               (.ref ExchangeSigningSignalQuery 'semantic-revision)
               '(unauthorized-outflow withdrawal-without-intent
                 duplicate-request-id orphan-queue-message
                 destination-mismatch display-byte-mismatch
                 observed-admin-effect complete-transfer-only-signing-ledger
                 authenticated-intent-exact one-use-request-record
                 verified-producer-chain independently-matched-destination
                 trusted-rendering-match)
               #t))
             (admission (poo-flow-query-admit ExchangeSigningSignalQuery space)))
        (check-equal? source ExchangeSigningSignalSource)
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
    (poo-flow-test-case "public outflow leaves every ingress hypothesis open"
      (let (result
            (exchange-signing-compare-hypotheses
             ExchangeSigningPublicEvidence.))
        (check-equal? (length (.ref result 'support)) 6)
        (check-equal? (.ref result 'specific-support) '())
        (check-equal? (.ref result 'challenged) '())
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))
    (poo-flow-test-case "a provisional backend log cannot become admitted support"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  provisional-signals:
                  '((orphan-queue-message backend-controlled-log))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal? (.ref result 'specific-support) '())
        (check-equal?
         (contains? (.ref result 'provisional-support)
                    '(queue-injection orphan-queue-message
                      backend-controlled-log)) #t)))
    (poo-flow-test-case "independent queue evidence narrows but does not prove ingress"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (orphan-queue-message independent-signer-log))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (.ref result 'specific-support)
         '((queue-injection orphan-queue-message independent-signer-log)))
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "an observed admin effect narrows operation, not ingress"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (observed-admin-effect independent-chain-receipt))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (contains? (.ref result 'specific-support)
                    '(admin-change-path observed-admin-effect
                      independent-chain-receipt)) #t)
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))
    (poo-flow-test-case "contradictory independent observations remain visible"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (orphan-queue-message independent-signer-log)
                    (verified-producer-chain independent-queue-audit))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (contains? (.ref result 'specific-support)
                    '(queue-injection orphan-queue-message
                      independent-signer-log)) #t)
        (check-equal?
         (contains? (.ref result 'challenged)
                    '(queue-injection verified-producer-chain
                      independent-queue-audit)) #t)
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))))
