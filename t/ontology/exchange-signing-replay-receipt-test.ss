;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Runs after the Case TLA+ gate. The input file is produced only after
;;; parser qualification and all required TLC checks have succeeded.
(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/replay-observability
                 exchange-signing-replay-observability)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/flow
                 exchange-signing-record-mutation
                 exchange-signing-interface-substitution
                 exchange-signing-backend-admin-change))

(export exchange-signing-replay-receipt-test)

(def qualification-file
  "user-interface/scenarios/exchange/cases/signing-trust-chain/proof/tla/qualification-receipts.sexp")

(def exchange-signing-replay-receipt-test
  (test-suite "Exchange signing actual TLA+ replay observations"
    (poo-flow-test-case "TLC counterexample transitions join named routes"
      (let* ((qualified
              (call-with-input-file qualification-file read))
             (direct
              (exchange-signing-replay-observability
               exchange-signing-record-mutation '() qualified))
             (admin
              (exchange-signing-replay-observability
               exchange-signing-backend-admin-change '() qualified))
             (interface
              (exchange-signing-replay-observability
               exchange-signing-interface-substitution '() qualified)))
        (check-equal? (length qualified) 10)
        (check-equal? (.ref direct 'tla-qualification-status)
                      'counterexample)
        (check-equal? (.ref direct 'tla-counterexample-transitions)
                      '("entry = \"backend-record\""
                        "missingWitness = \"record-intent\""
                        "WeakSign" "ApplyTransfer"))
        (check-equal? (.ref direct 'causally-and-temporally-qualified-routes)
                      '(record-mutation api-replay queue-injection
                        address-map-substitution))
        (check-equal? (length (.ref direct 'causal-tla-bindings)) 4)
        (check-equal? (.ref direct 'ingress-leading-routes)
                      '(api-replay queue-injection))
        (check-equal? (.ref direct 'ingress-relative-support-shares)
                      '((api-replay 2 6) (queue-injection 2 6)
                        (record-mutation 1 6)
                        (address-map-substitution 1 6)))
        (let (ledger-evidence
              (exchange-signing-replay-observability
               exchange-signing-record-mutation
               '((duplicate-request-id signer-ledger admitted)) qualified))
          (check-equal?
           (.ref ledger-evidence 'ingress-relative-support-shares)
           '((api-replay 8 12) (queue-injection 2 12)
             (record-mutation 1 12) (address-map-substitution 1 12)))
          (check-equal? (.ref ledger-evidence 'input-provenance-verified?) #f))
        (let (ledger-challenge
              (exchange-signing-replay-observability
               exchange-signing-record-mutation
               '((one-use-request-record signer-ledger admitted)) qualified))
          (check-equal?
           (.ref ledger-challenge 'ingress-relative-support-shares)
           '((queue-injection 2 4) (record-mutation 1 4)
             (address-map-substitution 1 4) (api-replay 0 4))))
        (let (without-api
              (exchange-signing-replay-observability
               exchange-signing-record-mutation '()
               (filter (lambda (row)
                         (not (equal? (car row) "ApiAttack.cfg")))
                       qualified)))
          (check-equal?
           (.ref without-api 'causally-and-temporally-qualified-routes)
           '(record-mutation queue-injection address-map-substitution))
          (check-equal? (.ref without-api 'ingress-ranking-status)
                        'partial-route-qualification)
          (check-equal? (.ref without-api 'ingress-relative-support-shares)
                        '((queue-injection 2 4) (record-mutation 1 4)
                          (address-map-substitution 1 4))))
        (let* ((api-row (assoc "ApiAttack.cfg" qualified))
               (missing-witness
                (cons (list (car api-row) (cadr api-row) (caddr api-row)
                            '("entry = \"internal-api\"" "WeakSign"
                              "ApplyTransfer"))
                      (filter (lambda (row)
                                (not (equal? (car row) "ApiAttack.cfg")))
                              qualified)))
               (replay (exchange-signing-replay-observability
                        exchange-signing-record-mutation '() missing-witness)))
          (check-equal? (.ref replay 'causally-and-temporally-qualified-routes)
                        '(record-mutation queue-injection
                          address-map-substitution)))
        (check-equal? (.ref admin 'tla-counterexample-transitions)
                      '("WeakSign" "ApplyAdminChange"
                        "DrainControlledWallet"))
        (check-equal? (.ref interface 'tla-counterexample-transitions)
                      '("PrepareInterfaceAdmin" "WeakSign"
                        "ApplyAdminChange" "DrainControlledWallet"))
        (check-equal? (.ref direct 'route-attributed?) #f)
        (check-equal? (.ref direct 'action-authority?) #f)))))
