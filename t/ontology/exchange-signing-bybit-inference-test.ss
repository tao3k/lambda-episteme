;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/modules/reverse-inference/interface
                 poo-flow-inference-claim
                 poo-flow-inference-hypothesis-result)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/bybit-inference
                 ExchangeSigningBybitEvidence.
                 exchange-signing-reverse-infer-bybit))

(export exchange-signing-bybit-inference-test)

(def (without claim)
  (.o (:: @ ExchangeSigningBybitEvidence.)
      claims: (filter (lambda (row)
                        (not (eq? (.ref row 'identity) claim)))
                      (.ref ExchangeSigningBybitEvidence. 'claims))))

(def (hypothesis-status receipt hypothesis-id)
  (.ref (poo-flow-inference-hypothesis-result receipt hypothesis-id)
        'status))

(def exchange-signing-bybit-inference-test
  (test-suite "Bybit source-bounded reverse mechanism reconstruction"
    (poo-flow-test-case "public evidence supports the reverse explanation"
      (let (receipt (exchange-signing-reverse-infer-bybit
                     ExchangeSigningBybitEvidence.))
        (check-equal? (hypothesis-status receipt 'interface-substitution)
                      'supported)
        (check-equal? (hypothesis-status receipt 'signer-key-compromise)
                      'needs-evidence)
        (check-equal?
         (.ref (poo-flow-inference-hypothesis-result
                receipt 'signer-key-compromise) 'missing-claims)
         '(signer-key-compromise))
        (check-equal? (.ref receipt 'evidence-consistent?) #t)
        (check-equal? (.ref receipt 'query-executed-in-scheme?) #t)
        (check-equal? (length (.ref receipt 'query-selected-claims)) 8)
        (check-equal? (.ref receipt 'missing-claims)
                      '((signer-key-compromise)))
        (check-equal?
         (hypothesis-status receipt 'reported-developer-compromise)
         'supported)
        (check-equal? (length (.ref receipt 'supported-inference-steps)) 7)
        (check-equal? (.ref receipt 'historical-attribution-verified?) #f)
        (check-equal? (.ref receipt 'source-authenticity-verified?) #f)
        (check-equal? (.ref receipt 'unresolved-witnesses)
                      '(initial-developer-machine-entry
                        each-signer-trusted-display
                        independent-signing-intent-receipt))))
    (poo-flow-test-case "outflow alone does not discover an attack path"
      (let (receipt
            (exchange-signing-reverse-infer-bybit
             (.o (:: @ ExchangeSigningBybitEvidence.)
                 claims:
                 (list (poo-flow-inference-claim
                        'funds-outflow 'present
                        'bybit-official-timeline)))))
        (check-equal? (.ref receipt 'supported-inference-steps) '())
        (check-equal? (and (member '(safe-implementation-rewritten)
                                   (.ref receipt 'missing-claims)) #t)
                      #t)
        (check-equal? (hypothesis-status receipt 'interface-substitution)
                      'needs-evidence)))
    (poo-flow-test-case "negative observations cannot count as evidence"
      (check-exception
       (exchange-signing-reverse-infer-bybit
        (.o (:: @ ExchangeSigningBybitEvidence.)
            claims:
            (list (poo-flow-inference-claim
                   'funds-outflow 'absent
                   'bybit-official-timeline))))
       true))
    (poo-flow-test-case "key evidence ablations break the full explanation"
      (for-each
       (lambda (claim)
         (let (receipt (exchange-signing-reverse-infer-bybit
                        (without claim)))
           (check-equal? (hypothesis-status receipt 'interface-substitution)
                         'needs-evidence)))
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
                         (if (eq? (.ref row 'identity)
                                  'javascript-target)
                           (.o (:: @ row) value: 'different-address)
                           row))
                       (.ref ExchangeSigningBybitEvidence. 'claims))))
             (receipt (exchange-signing-reverse-infer-bybit case-value)))
        (check-equal? (hypothesis-status receipt 'interface-substitution)
                      'conflicted)
        (check-equal? (.ref receipt 'evidence-consistent?) #f)
        (check-equal? (length (.ref receipt 'equality-mismatches)) 1)))
    (poo-flow-test-case "one matching pair cannot hide a conflicting target"
      (let* ((case-value
              (.o (:: @ ExchangeSigningBybitEvidence.)
                  claims:
                  (cons (poo-flow-inference-claim
                         'javascript-target 'different-address
                         'second-javascript-analysis)
                        (.ref ExchangeSigningBybitEvidence. 'claims))))
             (receipt (exchange-signing-reverse-infer-bybit case-value)))
        (check-equal?
         (and (member '(outflow compromised-interface)
                      (.ref receipt 'reachable-candidates)) #t)
         #t)
        (check-equal? (.ref receipt 'evidence-consistent?) #f)
        (check-equal? (hypothesis-status receipt 'interface-substitution)
                      'conflicted)))
    (poo-flow-test-case "initial compromise is separate from mechanism"
      (let (receipt
            (exchange-signing-reverse-infer-bybit
             (without 'safe-developer-machine-compromised)))
        (check-equal? (hypothesis-status receipt 'interface-substitution)
                      'supported)
        (check-equal?
         (hypothesis-status receipt 'reported-developer-compromise)
         'needs-evidence)))))
