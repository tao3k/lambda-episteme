;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/src/module-system/profile-composition/scenario-case
                 poo-flow-scenario-case?)
        (only-in :poo-flow/src/module-system/profile-composition/accessors
                 poo-flow-scenario-case-profiles)
        (only-in :poo-flow/modules/funflow/runtime-load-projection
                 poo-flow-runtime-load-projection)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/reasoning
                 exchange-signing-route-candidates)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/flow-profiles
                 ExchangeSigningRecordMutationProfile.
                 ExchangeSigningInterfaceProfile.
                 ExchangeSigningBackendAdminProfile.)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/flow
                 exchange-signing-record-mutation
                 exchange-signing-api-replay
                 exchange-signing-queue-injection
                 exchange-signing-address-map-substitution
                 exchange-signing-interface-substitution
                 exchange-signing-backend-admin-change))

(export exchange-signing-flow-test)

(def exchange-signing-flow-test
  (test-suite "Exchange signing named user compositions"
    (poo-flow-test-case "six attack names select maintained Funflow Profile"
      (let (compositions
            (list exchange-signing-record-mutation
                  exchange-signing-api-replay
                  exchange-signing-queue-injection
                  exchange-signing-address-map-substitution
                  exchange-signing-interface-substitution
                  exchange-signing-backend-admin-change))
        (check-equal? (map poo-flow-scenario-case? compositions)
                      '(#t #t #t #t #t #t))
        (check-equal?
         (map (lambda (composition) (.ref composition 'name)) compositions)
         '(exchange-signing-record-mutation
           exchange-signing-api-replay
           exchange-signing-queue-injection
           exchange-signing-address-map-substitution
           exchange-signing-interface-substitution
           exchange-signing-backend-admin-change))))
    (poo-flow-test-case "direct and admin attacks select distinct TLC models"
      (check-equal? (.ref ExchangeSigningRecordMutationProfile. 'tla-config)
                    "DirectAttack.cfg")
      (check-equal? (.ref ExchangeSigningInterfaceProfile. 'tla-config)
                    "InterfaceAttack.cfg")
      (check-equal? (.ref ExchangeSigningBackendAdminProfile. 'tla-config)
                    "AdminAttack.cfg"))
    (poo-flow-test-case "each composition selects its own proposed route"
      (let (cases
            (list (list exchange-signing-record-mutation
                        'record-mutation '(backend outflow))
                  (list exchange-signing-api-replay
                        'api-replay '(internal-api outflow))
                  (list exchange-signing-queue-injection
                        'queue-injection '(queue-producer outflow))
                  (list exchange-signing-address-map-substitution
                        'address-map-substitution '(address-map outflow))
                  (list exchange-signing-interface-substitution
                        'interface-substitution '(interface bybit-outflow))
                  (list exchange-signing-backend-admin-change
                        'backend-admin-change '(backend outflow))))
        (for-each
         (lambda (entry)
           (let* ((profile (cadr (poo-flow-scenario-case-profiles (car entry))))
                  (candidates
                   (exchange-signing-route-candidates
                    (.ref profile 'route-case))))
             (check-equal? (.ref profile 'identity) (cadr entry))
             (check-equal? (.ref candidates 'possible-candidates)
                           (list (caddr entry)))
             (check-equal? (.ref candidates 'observed-candidates) '())
             (check-equal? (.ref candidates 'action-authority?) #f)))
         cases)))
    (poo-flow-test-case "composition projects five linked Funflow nodes"
      (let* ((projection
              (poo-flow-runtime-load-projection
               exchange-signing-record-mutation))
             (plan (cdr (assq 'plan projection))))
        (check-equal? (cdr (assq 'kind projection))
                      'poo-flow.funflow.plan-projection)
        (check-equal? (cdr (assq 'origin plan))
                      'user-composition-funflow)
        (check-equal? (vector-length (cdr (assq 'node-table plan))) 5)
        (check-equal? (vector-length (cdr (assq 'edge-table plan))) 4)
        (check-equal? (cdr (assq 'runtime-executed projection)) #f)))))
