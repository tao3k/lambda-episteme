;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/bybit-reconstruction
                 ExchangeSigningBybitEvidence.
                 exchange-signing-reconstruct-bybit))

(export exchange-signing-bybit-reconstruction-test)

(def (without claim)
  (.o (:: @ ExchangeSigningBybitEvidence.)
      claims: (filter (lambda (row) (not (eq? (car row) claim)))
                      (.ref ExchangeSigningBybitEvidence. 'claims))))

(def exchange-signing-bybit-reconstruction-test
  (test-suite "Bybit source-bounded reverse mechanism reconstruction"
    (poo-flow-test-case "public evidence supports the reverse explanation"
      (let (receipt (exchange-signing-reconstruct-bybit
                     ExchangeSigningBybitEvidence.))
        (check-equal? (.ref receipt 'mechanism-chain-supported?) #t)
        (check-equal? (.ref receipt 'reported-compromise-linked?) #t)
        (check-equal? (length (.ref receipt 'supported-reverse-steps)) 7)
        (check-equal? (.ref receipt 'historical-attribution-verified?) #f)
        (check-equal? (.ref receipt 'source-authenticity-verified?) #f)
        (check-equal? (.ref receipt 'unresolved-witnesses)
                      '(initial-developer-machine-entry
                        each-signer-trusted-display
                        independent-signing-intent-receipt))))
    (poo-flow-test-case "outflow alone does not discover an attack path"
      (let (receipt
            (exchange-signing-reconstruct-bybit
             (.o (:: @ ExchangeSigningBybitEvidence.)
                 claims: '((funds-outflow present bybit-official-timeline)))))
        (check-equal? (.ref receipt 'supported-reverse-steps) '())
        (check-equal? (.ref receipt 'mechanism-chain-supported?) #f)))
    (poo-flow-test-case "negative observations cannot count as evidence"
      (check-exception
       (exchange-signing-reconstruct-bybit
        (.o (:: @ ExchangeSigningBybitEvidence.)
            claims: '((funds-outflow absent bybit-official-timeline))))
       true))
    (poo-flow-test-case "key evidence ablations break the full explanation"
      (for-each
       (lambda (claim)
         (let (receipt (exchange-signing-reconstruct-bybit
                        (without claim)))
           (check-equal? (.ref receipt 'mechanism-chain-supported?) #f)))
       '(safe-implementation-rewritten
         exec-delegatecall
         valid-safe-signatures
         javascript-target
         javascript-substituted-signed-fields)))
    (poo-flow-test-case "target equality is derived, not asserted"
      (let* ((case-value
              (.o (:: @ ExchangeSigningBybitEvidence.)
                  claims:
                  (map (lambda (row)
                         (if (eq? (car row) 'javascript-target)
                           '(javascript-target different-address
                             ncc-javascript-analysis)
                           row))
                       (.ref ExchangeSigningBybitEvidence. 'claims))))
             (receipt (exchange-signing-reconstruct-bybit case-value)))
        (check-equal? (.ref receipt 'mechanism-chain-supported?) #f)))
    (poo-flow-test-case "initial compromise is separate from mechanism"
      (let (receipt
            (exchange-signing-reconstruct-bybit
             (without 'safe-developer-machine-compromised)))
        (check-equal? (.ref receipt 'mechanism-chain-supported?) #t)
        (check-equal? (.ref receipt 'reported-compromise-linked?) #f)))))
