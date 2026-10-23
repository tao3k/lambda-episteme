;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/ingress-inference
                 ExchangeSigningPublicIngress.
                 exchange-signing-compare-ingress)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/query
                 ExchangeSigningSignalQuery))

(export exchange-signing-ingress-inference-test)

(def exchange-signing-ingress-inference-test
  (test-suite "Exchange signing conditional ingress comparison"
    (poo-flow-test-case "every model discriminator is selectable by GQL"
      (let (selected (.ref ExchangeSigningSignalQuery
                            'selected-element-identities))
        (check-equal?
         (and (andmap (lambda (row) (memq (cadr row) selected))
                      (.ref ExchangeSigningPublicIngress. 'model-factors))
              (andmap (lambda (row) (memq (cadr row) selected))
                      (.ref ExchangeSigningPublicIngress. 'hard-challenges))
              (andmap (lambda (row) (memq (cadr row) selected))
                      (.ref ExchangeSigningPublicIngress. 'evidence-questions))
              #t)
         #t)))
    (poo-flow-test-case "reported gas shape yields conditional 2:2:1:1"
      (let (result (exchange-signing-compare-ingress
                    ExchangeSigningPublicIngress.))
        (check-equal? (.ref result 'leading-routes)
                      '(api-replay queue-injection))
        (check-equal? (.ref result 'relative-support-shares)
                      '((api-replay 2 6) (queue-injection 2 6)
                        (record-mutation 1 6)
                        (address-map-substitution 1 6)))
        (check-equal? (.ref result 'reference-use)
                      'threat-class-validation-only)
        (check-equal? (.ref result 'calibrated-probabilities?) #f)))
    (poo-flow-test-case "remove architecture assumption and routes tie"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicIngress.)
                  model-factors:
                  (filter (lambda (row)
                            (not (eq? (cadr row)
                                      'fixed-round-gas-limits)))
                          (.ref ExchangeSigningPublicIngress.
                                'model-factors))))
             (result (exchange-signing-compare-ingress case-value)))
        (check-equal? (.ref result 'leading-routes)
                      '(record-mutation api-replay queue-injection
                        address-map-substitution))
        (check-equal? (map cadr (.ref result 'ranked-support))
                      '(1 1 1 1))))
    (poo-flow-test-case "independent API witness reorders; duplicate source does not"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicIngress.)
                  independent-signals:
                  '((duplicate-request-id signer-ledger-a)
                    (duplicate-request-id signer-ledger-b))))
             (result (exchange-signing-compare-ingress case-value)))
        (check-equal? (.ref result 'leading-routes) '(api-replay))
        (check-equal? (.ref result 'relative-support-shares)
                      '((api-replay 8 12) (queue-injection 2 12)
                        (record-mutation 1 12)
                        (address-map-substitution 1 12)))))
    (poo-flow-test-case "an exact independent challenge removes API support"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicIngress.)
                  independent-signals:
                  '((one-use-request-record signer-ledger))))
             (result (exchange-signing-compare-ingress case-value)))
        (check-equal? (.ref result 'leading-routes) '(queue-injection))
        (check-equal? (assoc 'api-replay (.ref result 'ranked-support))
                      '(api-replay 0))))))
