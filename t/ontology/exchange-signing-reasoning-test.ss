;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite test-case check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/reasoning
                 ExchangeSigningRouteCase.
                 exchange-signing-route-candidates))

(export exchange-signing-reasoning-test)

(def (candidate? rows route)
  (not (not (member route rows))))

(def exchange-signing-reasoning-test
  (test-suite "Exchange signing-chain hypotheses"
    (test-case "proposed backend links yield a possible, not observed route"
      (let* ((case-value
              (.o (:: @ ExchangeSigningRouteCase.)
                  observed-edges:
                  '((transfer outflow bitget-incident-notice))
                  proposed-edges:
                  '((backend payload reported-preliminary-account)
                    (payload signer synthetic-signing-queue)
                    (signer transfer synthetic-signer-effect))
                  surfaces: '((backend))
                  targets: '((outflow))))
             (result (exchange-signing-route-candidates case-value)))
        (check-equal?
         (candidate? (.ref result 'possible-candidates)
                     '(backend outflow)) #t)
        (check-equal? (.ref result 'observed-candidates) '())
        (check-equal? (.ref result 'admitted?) #f)
        (check-equal? (.ref result 'action-authority?) #f)))
    (test-case "missing queue link removes the proposed backend route"
      (let* ((case-value
              (.o (:: @ ExchangeSigningRouteCase.)
                  observed-edges:
                  '((transfer outflow bitget-incident-notice))
                  proposed-edges:
                  '((backend payload reported-preliminary-account)
                    (signer transfer synthetic-signer-effect))
                  surfaces: '((backend))
                  targets: '((outflow))))
             (result (exchange-signing-route-candidates case-value)))
        (check-equal? (.ref result 'possible-candidates) '())
        (check-equal? (.ref result 'observed-candidates) '())))))
