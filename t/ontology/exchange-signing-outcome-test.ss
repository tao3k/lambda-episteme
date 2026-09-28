;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/outcome
                 ExchangeSigningOutcomeCase.
                 ExchangeSigningDirectFixture.
                 ExchangeSigningDirectNoSignature.
                 ExchangeSigningDirectDuplicateObserver.
                 ExchangeSigningDirectConflictingObserver.
                 ExchangeSigningAdminFixture.
                 ExchangeSigningAdminNoEffect.
                 exchange-signing-outcome))

(export exchange-signing-outcome-test)

(def exchange-signing-outcome-test
  (test-suite "Exchange signing consequence reasoning"
    (poo-flow-test-case "two diverted fixture transfers total USD 75000"
      (let (result (exchange-signing-outcome ExchangeSigningDirectFixture.))
        (check-equal? (length (.ref result 'direct-loss-rows)) 2)
        (check-equal? (.ref result 'direct-loss-usd) 75000)
        (check-equal? (.ref result 'indirect-loss-usd) 0)
        (check-equal? (.ref result 'fixture-only?) #t)
        (check-equal? (.ref result 'incident-attribution?) #f)))
    (poo-flow-test-case "no signature means no linked direct loss"
      (let (result (exchange-signing-outcome
                    ExchangeSigningDirectNoSignature.))
        (check-equal? (.ref result 'direct-loss-rows) '())
        (check-equal? (.ref result 'direct-loss-usd) 0)))
    (poo-flow-test-case "independent observers do not double-count a transaction"
      (let (result (exchange-signing-outcome
                    ExchangeSigningDirectDuplicateObserver.))
        (check-equal? (length (.ref result 'direct-loss-rows)) 3)
        (check-equal? (.ref result 'direct-loss-usd) 75000)))
    (poo-flow-test-case "conflicting chain amounts fail closed"
      (check-exception
       (exchange-signing-outcome ExchangeSigningDirectConflictingObserver.)
       true))
    (poo-flow-test-case "an admin signature needs a later linked drain"
      (let (result (exchange-signing-outcome ExchangeSigningAdminFixture.))
        (check-equal? (length (.ref result 'indirect-loss-rows)) 1)
        (check-equal? (.ref result 'indirect-loss-usd) 120000)
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "without an observed admin effect the drain is unexplained"
      (let (result (exchange-signing-outcome
                    ExchangeSigningAdminNoEffect.))
        (check-equal? (.ref result 'indirect-loss-rows) '())
        (check-equal? (.ref result 'indirect-loss-usd) 0)))
    (poo-flow-test-case "a public aggregate alone proves no internal chain"
      (let (result (exchange-signing-outcome ExchangeSigningOutcomeCase.))
        (check-equal? (.ref result 'direct-loss-usd) 0)
        (check-equal? (.ref result 'indirect-loss-usd) 0)))))
