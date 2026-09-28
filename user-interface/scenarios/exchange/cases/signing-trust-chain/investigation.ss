;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Agent-facing investigation proposals for the Bybit reference Case.
;;; A proposal does not collect evidence, grant tool access, or establish
;;; historical attribution. The Host binds a tool and admits its output.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/modules/reverse-inference/interface
                 poo-flow-inference-hypothesis-result
                 poo-flow-reverse-inference-explore)
        (only-in "bybit-inference.ss"
                 ExchangeSigningBybitEvidence.
                 exchange-signing-reverse-infer-bybit))

(export ExchangeSigningInvestigationTask.
        exchange-signing-bybit-investigation-brief-from-receipt
        exchange-signing-bybit-investigation-brief
        exchange-signing-bybit-explore)

(def ExchangeSigningInvestigationTask.
  (.o kind: 'lambda-episteme.exchange.investigation-task
      claim: #f
      collection: #f
      expected-owner: #f
      independence-group: #f
      source-uri: #f
      claimed-content-digest: #f
      read-only?: #t
      tool-binding: #f
      execution-authority?: #f
      evidence-admitted?: #f))

(def (investigation-task claim-value collection-value owner-value
                         (group-value #f) (uri-value #f)
                         (digest-value #f))
  (.o (:: @ ExchangeSigningInvestigationTask.)
      claim: claim-value
      collection: collection-value
      expected-owner: owner-value
      independence-group: group-value
      source-uri: uri-value
      claimed-content-digest: digest-value))

(def (missing-claim-collection-option claim-value)
  (case claim-value
    ((signer-key-compromise)
     (investigation-task claim-value 'key-use-attestation
                         'independent-signer-custodian))
    ((javascript-target javascript-substituted-signed-fields)
     (investigation-task claim-value 'signed-payload-and-ui-artifact
                         'independent-forensic-custodian))
    (else
     (investigation-task claim-value 'source-owner-to-specify
                         'case-investigator))))

(def (unresolved-witness-task claim-value)
  (case claim-value
    ((initial-developer-machine-entry)
     (investigation-task claim-value 'workstation-entry-timeline
                         'independent-forensic-custodian))
    ((each-signer-trusted-display)
     (investigation-task claim-value 'per-signer-display-receipt
                         'signer-device-owner))
    ((independent-signing-intent-receipt)
     (investigation-task claim-value 'intent-to-signed-bytes-receipt
                         'signing-intent-owner))
    (else
     (investigation-task claim-value 'source-owner-to-specify
                         'case-investigator))))

(def (source-binding-tasks references)
  (let loop ((pending references) (seen-references '()) (tasks '()))
    (if (null? pending) (reverse tasks)
      (let* ((reference (cadar pending))
             (uri (.ref reference 'uri))
             (group (.ref reference 'independence-group))
             (source (.ref reference 'source))
             (digest (.ref reference 'content-digest))
             (key (list uri group digest)))
        (if (member key seen-references)
          (loop (cdr pending) seen-references tasks)
          (loop (cdr pending) (cons key seen-references)
                (cons
                 (investigation-task
                  source 'canonical-source-snapshot
                  source group uri digest)
                 tasks)))))))

(def (distinct-missing-claims results)
  (let loop ((pending
              (apply append
                     (map (lambda (result) (.ref result 'missing-claims))
                          results)))
             (seen '()))
    (if (null? pending) (reverse seen)
      (loop (cdr pending)
            (if (memq (car pending) seen) seen
              (cons (car pending) seen))))))

(def (exchange-signing-bybit-investigation-brief-from-receipt receipt)
  (let* ((witnesses (.ref receipt 'unresolved-witnesses))
         (reference-tasks
          (source-binding-tasks (.ref receipt 'evidence-references)))
         (option-values
          (map missing-claim-collection-option
               (distinct-missing-claims
                (.ref receipt 'hypothesis-results))))
         (witness-tasks
          (map unresolved-witness-task witnesses))
         (interface-result
          (poo-flow-inference-hypothesis-result
           receipt 'interface-substitution)))
    (.o kind: 'lambda-episteme.exchange.investigation-brief
        case: 'bybit-reference-signing-chain
        source-binding-tasks: reference-tasks
        collection-options: option-values
        unresolved-witness-tasks: witness-tasks
        interface-witness-path: (.ref interface-result 'witness-path)
        hypothesis-results: (.ref receipt 'hypothesis-results)
        evidence-without-content-digest:
        (.ref receipt 'evidence-without-content-digest)
        source-authenticity-verified?: #f
        tool-executed?: #f
        action-authority?: #f)))

(def (exchange-signing-bybit-investigation-brief
      (case-value ExchangeSigningBybitEvidence.))
  (exchange-signing-bybit-investigation-brief-from-receipt
   (exchange-signing-reverse-infer-bybit case-value)))

;;; An Agent may supply several POO branches. All are replayed together;
;;; this Case neither selects one branch nor treats it as an observation.
(def (exchange-signing-bybit-explore branch-values
                                    (case-value ExchangeSigningBybitEvidence.))
  (poo-flow-reverse-inference-explore case-value branch-values))
