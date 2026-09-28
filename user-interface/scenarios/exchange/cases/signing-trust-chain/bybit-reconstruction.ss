;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Reverse explanation of the disclosed Bybit mechanism. Evidence rows are
;;; source-labelled claims, not pre-connected causal edges. The Ascent rules
;;; make the joins and reverse reachability inspectable. A complete candidate
;;; remains a model explanation, not independent forensic attribution.
(import (only-in :clan/poo/object .o .ref object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program))

(export ExchangeSigningBybitEvidence.
        exchange-signing-reconstruct-bybit)

(def ExchangeSigningBybitEvidence.
  (.o kind: 'lambda-episteme.exchange.bybit-evidence
      claims:
      '((funds-outflow present bybit-official-timeline)
        (safe-implementation-rewritten present ncc-onchain-analysis)
        (exec-delegatecall present ncc-onchain-analysis)
        (attacker-target-in-execution
         0x96221423681a6d52e184d440a8efcebb105c7242 ncc-onchain-analysis)
        (valid-safe-signatures present ncc-onchain-analysis)
        (javascript-substituted-signed-fields present ncc-javascript-analysis)
        (javascript-target
         0x96221423681a6d52e184d440a8efcebb105c7242 ncc-javascript-analysis)
        (safe-developer-machine-compromised present
         ncc-forensic-report-summary))
      unresolved:
      '(initial-developer-machine-entry
        each-signer-trusted-display
        independent-signing-intent-receipt)))

(def reverse-steps
  '((outflow wallet-control
      funds-outflow safe-implementation-rewritten)
    (wallet-control delegatecall-execution
      safe-implementation-rewritten exec-delegatecall)
    (delegatecall-execution signed-transaction
      exec-delegatecall valid-safe-signatures)
    (signed-transaction onchain-payload
      valid-safe-signatures attacker-target-in-execution)
    (javascript-substitution compromised-interface
      javascript-target javascript-substituted-signed-fields)
    (compromised-interface reported-developer-compromise
      javascript-substituted-signed-fields safe-developer-machine-compromised)))

(def target-join-step
  '((onchain-payload javascript-substitution
      attacker-target-in-execution javascript-target)))

(def (claim-row? row)
  (and (list? row) (= (length row) 3)
       (symbol? (car row)) (symbol? (caddr row))
       (if (memq (car row)
                 '(attacker-target-in-execution javascript-target))
         (symbol? (cadr row))
         (eq? (cadr row) 'present))))

(def (exchange-signing-reconstruct-bybit case-value)
  (unless (and (object? case-value)
               (eq? (.ref case-value 'kind)
                    'lambda-episteme.exchange.bybit-evidence)
               (list? (.ref case-value 'claims))
               (every claim-row? (.ref case-value 'claims)))
    (error "invalid Bybit evidence Case" case-value))
  (let* ((result
          (gerbil-ascent-evaluate-program
           (ascent
            (relation claim (name value source) (.ref case-value 'claims))
            (relation step (from to first second) reverse-steps)
            (relation target-step (from to first second) target-join-step)
            (relation supported-step
              (from to first first-source second second-source))
            (relation reverse-reach (from to))
            ((supported-step from to first first-source second second-source)
             <-- (step from to first second)
                 (claim first first-value first-source)
                 (claim second second-value second-source))
            ((supported-step from to first first-source second second-source)
             <-- (target-step from to first second)
                 (claim first target first-source)
                 (claim second target second-source))
            ((reverse-reach from to)
             <-- (supported-step from to first first-source
                                 second second-source))
            ((reverse-reach from end)
             <-- (reverse-reach from middle)
                 (supported-step middle end first first-source
                                 second second-source))
            (bounds 64 256 512))))
         (rows-of (.ref result 'rows-of))
         (supported (rows-of 'supported-step))
         (reach (rows-of 'reverse-reach)))
    (.o kind: 'lambda-episteme.exchange.bybit-reconstruction
        supplied-claims: (.ref case-value 'claims)
        supported-reverse-steps: supported
        reachable-mechanisms: reach
        mechanism-chain-supported?:
        (and (member '(outflow compromised-interface) reach) #t)
        reported-compromise-linked?:
        (and (member '(outflow reported-developer-compromise) reach) #t)
        unresolved-witnesses: (.ref case-value 'unresolved)
        historical-attribution-verified?: #f
        source-authenticity-verified?: #f
        action-authority?: #f)))
