;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; This Case declares the Bybit reference evidence and reverse steps. POO
;;; Flow owns bounded GQL selection, Ascent joins, conflict diagnostics, and
;;; candidate reachability. No claim here authenticates the underlying source.
(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/modules/reverse-inference/interface
                 PooFlowReverseInferenceCase.
                 poo-flow-inference-evidence-reference
                 poo-flow-inference-claim
                 poo-flow-inference-step
                 poo-flow-inference-hypothesis
                 poo-flow-reverse-inference-evaluate)
        (only-in "query.ss" ExchangeSigningBybitClaimQuery))

(export ExchangeSigningBybitEvidence.
        exchange-signing-reverse-infer-bybit)

(def BybitOfficialReference.
  (poo-flow-inference-evidence-reference
   'bybit-official-timeline
   "https://www.bybit.com/en/learn/this-week-in-bybit/bybit-security-incident-timeline"
   'bybit-official))

(def NccOnchainReference.
  (poo-flow-inference-evidence-reference
   'ncc-onchain-analysis
   "https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/"
   'ncc-group))

(def NccJavascriptReference.
  (poo-flow-inference-evidence-reference
   'ncc-javascript-analysis
   "https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/"
   'ncc-group))

(def NccForensicReference.
  (poo-flow-inference-evidence-reference
   'ncc-forensic-report-summary
   "https://www.nccgroup.com/research/in-depth-technical-analysis-of-the-bybit-hack/"
   'ncc-group))

(def ExchangeSigningBybitEvidence.
  (.o (:: @ PooFlowReverseInferenceCase.)
      query: ExchangeSigningBybitClaimQuery
      claims:
      (list
       (poo-flow-inference-claim
        'funds-outflow 'present 'bybit-official-timeline
        BybitOfficialReference.)
       (poo-flow-inference-claim
        'safe-implementation-rewritten 'present 'ncc-onchain-analysis
        NccOnchainReference.)
       (poo-flow-inference-claim
        'exec-delegatecall 'present 'ncc-onchain-analysis
        NccOnchainReference.)
       (poo-flow-inference-claim
        'attacker-target-in-execution
        '0x96221423681a6d52e184d440a8efcebb105c7242
        'ncc-onchain-analysis NccOnchainReference.)
       (poo-flow-inference-claim
        'valid-safe-signatures 'present 'ncc-onchain-analysis
        NccOnchainReference.)
       (poo-flow-inference-claim
        'javascript-substituted-signed-fields 'present
        'ncc-javascript-analysis NccJavascriptReference.)
       (poo-flow-inference-claim
        'javascript-target
        '0x96221423681a6d52e184d440a8efcebb105c7242
        'ncc-javascript-analysis NccJavascriptReference.)
       (poo-flow-inference-claim
        'safe-developer-machine-compromised 'present
        'ncc-forensic-report-summary NccForensicReference.))
      steps:
      (list
       (poo-flow-inference-step
        'outflow 'wallet-control
        'funds-outflow 'safe-implementation-rewritten)
       (poo-flow-inference-step
        'wallet-control 'delegatecall-execution
        'safe-implementation-rewritten 'exec-delegatecall)
       (poo-flow-inference-step
        'delegatecall-execution 'signed-transaction
        'exec-delegatecall 'valid-safe-signatures)
       (poo-flow-inference-step
        'signed-transaction 'onchain-payload
        'valid-safe-signatures 'attacker-target-in-execution)
       (poo-flow-inference-step
        'onchain-payload 'javascript-substitution
        'attacker-target-in-execution 'javascript-target 'equal-value)
       (poo-flow-inference-step
        'javascript-substitution 'compromised-interface
        'javascript-target 'javascript-substituted-signed-fields)
       (poo-flow-inference-step
        'compromised-interface 'reported-developer-compromise
        'javascript-substituted-signed-fields
        'safe-developer-machine-compromised)
       (poo-flow-inference-step
        'outflow 'key-compromise
        'funds-outflow 'signer-key-compromise))
      hypotheses:
      (list
       (poo-flow-inference-hypothesis
        'interface-substitution 'outflow 'compromised-interface
        '(funds-outflow safe-implementation-rewritten
          exec-delegatecall valid-safe-signatures
          attacker-target-in-execution javascript-target
          javascript-substituted-signed-fields))
       (poo-flow-inference-hypothesis
        'reported-developer-compromise 'outflow
        'reported-developer-compromise
        '(funds-outflow safe-implementation-rewritten
          exec-delegatecall valid-safe-signatures
          attacker-target-in-execution javascript-target
          javascript-substituted-signed-fields
          safe-developer-machine-compromised))
       (poo-flow-inference-hypothesis
        'signer-key-compromise 'outflow 'key-compromise
        '(funds-outflow signer-key-compromise)))
      unresolved:
      '(initial-developer-machine-entry
        each-signer-trusted-display
        independent-signing-intent-receipt)))

(def exchange-signing-reverse-infer-bybit
  poo-flow-reverse-inference-evaluate)
