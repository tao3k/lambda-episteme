;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/modules/reverse-inference/interface
                 poo-flow-inference-claim)
        (only-in :poo-flow/src/scenario/case
                 poo-flow-scenario-case?)
        (only-in :poo-flow/src/scenario/accessors
                 poo-flow-scenario-case-profiles)
        (only-in :poo-flow/modules/funflow/runtime-load-projection
                 poo-flow-runtime-load-projection)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/reasoning
                 exchange-signing-route-candidates)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/replay-observability
                 exchange-signing-replay-observability)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/bybit-inference
                 ExchangeSigningBybitEvidence.)
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
                    "RecordAttack.cfg")
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
    (poo-flow-test-case "composition projects six linked Funflow nodes"
      (let* ((projection
              (poo-flow-runtime-load-projection
               exchange-signing-record-mutation))
             (plan (cdr (assq 'plan projection))))
        (check-equal? (cdr (assq 'kind projection))
                      'poo-flow.funflow.plan-projection)
        (check-equal? (cdr (assq 'origin plan))
                      'user-composition-funflow)
        (check-equal? (vector-length (cdr (assq 'node-table plan))) 6)
        (check-equal? (vector-length (cdr (assq 'edge-table plan))) 5)
        (check-equal? (cdr (assq 'runtime-executed projection)) #f)))
    (poo-flow-test-case "replay exposes proposed links and missing witnesses"
      (let (receipt
            (exchange-signing-replay-observability
             exchange-signing-queue-injection
             '((queue-producer-attestation backend-log provisional)
               (signer-ingress-receipt signer-audit admitted))))
        (check-equal? (.ref receipt 'attack-profile) 'queue-injection)
        (check-equal? (.ref receipt 'possible-candidates)
                      '((queue-producer outflow)))
        (check-equal? (.ref receipt 'observed-candidates) '())
        (check-equal? (.ref receipt 'bybit-reference-observed-route)
                      '())
        (check-equal? (.ref receipt 'bybit-reference-possible-route)
                      '((interface bybit-outflow)))
        (check-equal?
         (.ref receipt 'bybit-reference-interface-status) 'supported)
        (check-equal?
         (.ref receipt 'bybit-reference-unresolved-witnesses)
         '(initial-developer-machine-entry
           each-signer-trusted-display
           independent-signing-intent-receipt))
        (check-equal? (.ref receipt 'bybit-reference-operation)
                      'delegatecall)
        (check-equal? (.ref receipt 'bybit-display-witness-status)
                      'inferred-in-ncc-analysis)
        (check-equal?
         (.ref receipt 'missing-independent-observations)
         '(queue-producer-attestation signer-decoded-transaction))
        (check-equal? (.ref receipt 'tla-config) "QueueAttack.cfg")
        (check-equal? (.ref receipt 'causal-assessment-status)
                      'causal-trajectory-admitted)
        (check-equal? (.ref receipt 'causal-report-source)
                      "bitget/official-security-incident")
        (check-equal? (length (.ref receipt 'causal-report-cut-event-ids)) 1)
        (check-equal? (.ref receipt 'causal-required-independent-evidence)
                      '(queue-producer-attestation signer-ingress-receipt
                        signer-decoded-transaction))
        (check-equal? (.ref receipt 'historical-ingress-observed?) #f)
        (check-equal? (.ref receipt 'ingress-ranking-status)
                      'awaiting-tla-qualification)
        (check-equal? (.ref receipt 'ingress-leading-routes) #f)
        (check-equal?
         (and (member '(backend-signed-transfer fixed-round-gas-limits
                        bitquery-chain-analysis)
                      (.ref receipt 'public-family-matches))
              #t)
         #t)
        (check-equal? (.ref receipt 'tla-qualification-status)
                      'not-supplied)
        (check-equal? (.ref receipt 'action-authority?) #f)))
    (poo-flow-test-case "different routes request different independent evidence"
      (let ((api (exchange-signing-replay-observability
                  exchange-signing-api-replay))
            (interface (exchange-signing-replay-observability
                        exchange-signing-interface-substitution)))
        (check-equal? (.ref api 'missing-independent-observations)
                      '(one-use-request-ledger signer-request-authentication
                        signer-decoded-transaction))
        (check-equal? (.ref interface 'missing-independent-observations)
                      '(trusted-rendered-bytes signed-admin-operation
                        linked-control-change))
        (check-equal? (.ref interface 'tla-config) "InterfaceAttack.cfg")))
    (poo-flow-test-case "caller evidence changes the replay hypothesis"
      (let* ((evidence
              (.o (:: @ ExchangeSigningBybitEvidence.)
                  claims:
                  (list (poo-flow-inference-claim
                         'funds-outflow 'present
                         'bybit-official-timeline))))
             (receipt
              (exchange-signing-replay-observability
               exchange-signing-interface-substitution
               '() '() #f evidence)))
        (check-equal? (.ref receipt 'bybit-reference-interface-status)
                      'needs-evidence)
        (check-equal? (.ref receipt 'bybit-reference-evidence-consistent?)
                      #t)
        (check-equal? (and (member '(exec-delegatecall)
                                   (.ref receipt 'bybit-reference-missing-claims))
                           #t)
                      #t)))))
