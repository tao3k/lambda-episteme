;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref .slot?)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/chain
                 ExchangeSigningReportedChain.
                 exchange-signing-plan-chain)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/hypotheses
                 ExchangeSigningFamilyCase.))

(export exchange-signing-chain-test)

(def exchange-signing-chain-test
  (test-suite "Exchange signing GQL ASCENT TLA Cedar handoff"
    (poo-flow-test-case "reported observations retain every mapped threat path"
      (let (result (exchange-signing-plan-chain
                    ExchangeSigningReportedChain.))
        (check-equal? (.ref result 'model-compatible-families)
                      '(backend-signed-transfer))
        (check-equal? (.ref result 'tla-configs)
                      '("DirectAttack.cfg" "AdminAttack.cfg"
                        "InterfaceAttack.cfg"))
        (check-equal? (.ref result 'cedar-roots)
                      '("Integrated" "Integrated" "Integrated"))
        (check-equal? (length (.ref result 'family-handoffs)) 3)
        (check-equal? (.slot? result 'preferred-family) #f)
        (check-equal? (.ref result 'handoff-resolved?) #t)
        (check-equal? (.ref result 'gql-executed?) #f)
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "admin evidence changes compatibility without removing paths"
      (let* ((case-value
              (.o (:: @ ExchangeSigningReportedChain.)
                  hypothesis:
                  (.o (:: @ ExchangeSigningFamilyCase.)
                      reported-signals:
                      '((backend-compromise independent-backend-receipt)
                        (spoofed-transaction-data independent-ingress-receipt)
                        (observed-admin-effect independent-chain-receipt)))))
             (result (exchange-signing-plan-chain case-value)))
        (check-equal? (.ref result 'model-compatible-families)
                      '(backend-admin-change))
        (check-equal? (length (.ref result 'family-handoffs)) 3)))
    (poo-flow-test-case "GQL selection cannot silently drop a new signal"
      (let (case-value
            (.o (:: @ ExchangeSigningReportedChain.)
                hypothesis:
                (.o (:: @ ExchangeSigningFamilyCase.)
                    reported-signals: '((unselected-signal outside-source)))))
        (check-exception
         (exchange-signing-plan-chain case-value) true)))))
