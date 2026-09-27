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
                 ExchangeSigningEdgeQuery ExchangeSigningEdgeSource)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/reasoning
                 ExchangeSigningRouteCase.
                 exchange-signing-route-candidates)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/simulation
                 exchange-signing-attack-stages
                 exchange-signing-evaluate-stage))

(export exchange-signing-reasoning-test)

(def (candidate? rows route)
  (not (not (member route rows))))

(def exchange-signing-reasoning-test
  (test-suite "Exchange signing-chain hypotheses"
    (poo-flow-test-case "language-owned GQL AST projects and admits the selected element space"
      (let* ((source (poo-flow-query->gql ExchangeSigningEdgeQuery))
             (space
              (poo-flow-query-element-space
               'exchange/signing-chain
               (.ref ExchangeSigningEdgeQuery 'semantic-revision)
               '(backend payload signer chain-transfer admin-change wallet-control outflow)
               #t))
             (admission (poo-flow-query-admit ExchangeSigningEdgeQuery space)))
        (check-equal? source ExchangeSigningEdgeSource)
        (check-equal?
         source
         "MATCH (source:SigningEvent)-[:CANDIDATE_NEXT]->(target:SigningEvent)\nRETURN source.identity, target.identity, target.evidenceSource, target.status\n")
        (check-equal?
         (poo-flow-query-source-content-identity ExchangeSigningEdgeQuery)
         (.ref ExchangeSigningEdgeQuery 'semantic-revision))
        (check-equal?
         (gql-query-program? (.ref ExchangeSigningEdgeQuery 'program)) #t)
        (check-equal? (.ref admission 'accepted?) #t)
        (check-equal? (.ref admission 'runtime-executed?) #f)))
    (poo-flow-test-case "proposed backend links yield a possible, not observed route"
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
    (poo-flow-test-case "missing queue link removes the proposed backend route"
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
        (check-equal? (.ref result 'observed-candidates) '())))
    (poo-flow-test-case "attack stages stay declarative before inference"
      (check-equal?
       (map (lambda (stage) (.ref stage 'identity))
            (exchange-signing-attack-stages))
       '(public-notice record-substitution queue-injection signer-ingress
         candidate-transfer queue-interrupted interface-substitution
         api-replay queue-producer-injection address-map-substitution
         backend-admin-change)))
    (poo-flow-test-case "public notice alone does not establish a backend route"
      (let (result
            (exchange-signing-evaluate-stage
             (car (exchange-signing-attack-stages))))
        (check-equal? (.ref result 'possible-candidates) '())
        (check-equal? (.ref result 'observed-candidates) '())))
    (poo-flow-test-case "synthetic backend chain remains a candidate only"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 4)))
        (check-equal? (.ref result 'possible-candidates)
                      '((backend outflow)))
        (check-equal? (.ref result 'observed-candidates) '())
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "cutting the synthetic queue link removes backend reachability"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 5)))
        (check-equal? (.ref result 'possible-candidates) '())
        (check-equal? (.ref result 'observed-candidates) '())))
    (poo-flow-test-case "interface substitution is a distinct candidate entry"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 6)))
        (check-equal? (.ref result 'possible-candidates)
                      '((interface bybit-outflow)))
        (check-equal? (.ref result 'observed-candidates) '())
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "API replay is a distinct candidate entry"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 7)))
        (check-equal? (.ref result 'possible-candidates)
                      '((internal-api outflow)))
        (check-equal? (.ref result 'observed-candidates) '())))
    (poo-flow-test-case "queue injection is a distinct candidate entry"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 8)))
        (check-equal? (.ref result 'possible-candidates)
                      '((queue-producer outflow)))
        (check-equal? (.ref result 'observed-candidates) '())))
    (poo-flow-test-case "an admin-change hypothesis also reaches Bitget's public outflow"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 10)))
        (check-equal? (.ref result 'possible-candidates)
                      '((backend outflow)))
        (check-equal? (.ref result 'observed-candidates) '())
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "destination mapping is a distinct candidate entry"
      (let (result
            (exchange-signing-evaluate-stage
             (list-ref (exchange-signing-attack-stages) 9)))
        (check-equal? (.ref result 'possible-candidates)
                      '((address-map outflow)))
        (check-equal? (.ref result 'observed-candidates) '())))))
