;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal? check-exception)
        (only-in :clan/poo/object .o .ref .slot?)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/modules/reverse-inference/interface
                 poo-flow-inference-claim
                 poo-flow-inference-branch
                 poo-flow-inference-hypothesis-result)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/bybit-inference
                 ExchangeSigningBybitEvidence.
                 exchange-signing-reverse-infer-bybit)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/investigation
                 exchange-signing-bybit-investigation-brief
                 exchange-signing-bybit-explore))

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
         'needs-evidence)))
    (poo-flow-test-case "agent brief preserves the open inquiry space"
      (let* ((brief (exchange-signing-bybit-investigation-brief))
             (bindings (.ref brief 'source-binding-tasks))
             (tasks (.ref brief 'collection-options))
             (task (car tasks)))
        (check-equal? (length bindings) 2)
        (check-equal? (.ref (cadr bindings) 'independence-group)
                      'ncc-group)
        (check-equal?
         (.ref (cadr bindings) 'source-uri)
         "https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/")
        (check-equal? (length (.ref brief 'evidence-without-content-digest))
                      8)
        (check-equal? (length tasks) 1)
        (check-equal? (.ref task 'claim) 'signer-key-compromise)
        (check-equal? (.ref task 'collection) 'key-use-attestation)
        (check-equal? (.ref task 'read-only?) #t)
        (check-equal? (.ref task 'tool-binding) #f)
        (check-equal? (.ref task 'execution-authority?) #f)
        (check-equal? (length (.ref brief 'unresolved-witness-tasks)) 3)
        (check-equal? (length (.ref brief 'interface-witness-path)) 6)
        (check-equal? (.ref brief 'tool-executed?) #f)))
    (poo-flow-test-case "a missing display claim remains a collection option"
      (let* ((brief (exchange-signing-bybit-investigation-brief
                     (without 'javascript-target)))
             (claims
              (map (lambda (task) (.ref task 'claim))
                   (.ref brief 'collection-options))))
        (check-equal? (and (memq 'javascript-target claims) #t) #t)
        (check-equal? (and (memq 'signer-key-compromise claims) #t) #t)
        (check-equal? (.ref brief 'action-authority?) #f)))
    (poo-flow-test-case "agent explores opposing branches without a winner"
      (let* ((exploration
              (exchange-signing-bybit-explore
               (list
                (poo-flow-inference-branch
                 'key-use
                 (list (poo-flow-inference-claim
                        'signer-key-compromise 'present
                        'hypothetical-custodian-report))
                 '() 'test-key-alternative)
                (poo-flow-inference-branch
                 'contradict-display
                 (list (poo-flow-inference-claim
                        'javascript-target 'different-address
                        'hypothetical-display-artifact))
                 '() 'test-address-conflict)
                (poo-flow-inference-branch
                 'without-javascript-source '()
                 '(javascript-target javascript-substituted-signed-fields)
                 'test-source-dependence))))
             (branches (.ref exploration 'branch-results)))
        (check-equal? (length branches) 3)
        (check-equal?
         (.ref (poo-flow-inference-hypothesis-result
                (.ref (car branches) 'receipt)
                'signer-key-compromise) 'status)
         'supported)
        (check-equal?
         (.ref (poo-flow-inference-hypothesis-result
                (.ref (cadr branches) 'receipt)
                'interface-substitution) 'status)
         'conflicted)
        (check-equal?
         (.ref (poo-flow-inference-hypothesis-result
                (.ref (caddr branches) 'receipt)
                'interface-substitution) 'status)
         'needs-evidence)
        (check-equal? (.slot? exploration 'recommended-branch) #f)
        (check-equal? (.ref exploration 'action-authority?) #f)))))
