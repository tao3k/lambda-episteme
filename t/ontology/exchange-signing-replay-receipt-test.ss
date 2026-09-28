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
        (check-equal? (length qualified) 6)
        (check-equal? (.ref direct 'tla-qualification-status)
                      'counterexample)
        (check-equal? (.ref direct 'tla-counterexample-transitions)
                      '("WeakSign" "ApplyTransfer"))
        (check-equal? (.ref admin 'tla-counterexample-transitions)
                      '("WeakSign" "ApplyAdminChange"
                        "DrainControlledWallet"))
        (check-equal? (.ref interface 'tla-counterexample-transitions)
                      '("PrepareInterfaceAdmin" "WeakSign"
                        "ApplyAdminChange" "DrainControlledWallet"))
        (check-equal? (.ref direct 'route-attributed?) #f)
        (check-equal? (.ref direct 'action-authority?) #f)))))
