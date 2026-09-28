;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/chain
                 ExchangeSigningReportedChain.
                 exchange-signing-plan-chain)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/hypotheses
                 ExchangeSigningFamilyCase.))

(export exchange-signing-chain-test)

(def exchange-signing-chain-test
  (test-suite "Exchange signing GQL ASCENT TLA Cedar handoff"
    (poo-flow-test-case "reported observations select the direct-transfer threat path"
      (let (result (exchange-signing-plan-chain
                    ExchangeSigningReportedChain.))
        (check-equal? (.ref result 'preferred-family)
                      'backend-signed-transfer)
        (check-equal? (.ref result 'tla-config) "DirectAttack.cfg")
        (check-equal? (.ref result 'cedar-root) "Integrated")
        (check-equal? (.ref result 'host-cut)
                      'independent-byte-and-operation-binding)
        (check-equal? (.ref result 'handoff-resolved?) #t)
        (check-equal? (.ref result 'gql-executed?) #f)
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "admin effect selects a distinct temporal path"
      (let* ((case-value
              (.o (:: @ ExchangeSigningReportedChain.)
                  hypothesis:
                  (.o (:: @ ExchangeSigningFamilyCase.)
                      reported-signals:
                      '((backend-compromise independent-backend-receipt)
                        (spoofed-transaction-data independent-ingress-receipt)
                        (observed-admin-effect independent-chain-receipt)))))
             (result (exchange-signing-plan-chain case-value)))
        (check-equal? (.ref result 'tla-config) "AdminAttack.cfg")
        (check-equal? (.ref result 'cedar-root) "Integrated")))
    (poo-flow-test-case "GQL selection cannot silently drop a new signal"
      (let (case-value
            (.o (:: @ ExchangeSigningReportedChain.)
                hypothesis:
                (.o (:: @ ExchangeSigningFamilyCase.)
                    reported-signals: '((unselected-signal outside-source)))))
        (check-exception
         (exchange-signing-plan-chain case-value) true)))))
