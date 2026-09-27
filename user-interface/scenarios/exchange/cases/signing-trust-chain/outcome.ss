;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Fixture-scoped consequence reasoning. A signature alone is not a loss:
;;; direct transfers need a matching chain outflow, while an administrative
;;; instruction needs an observed state change and a subsequent linked drain.
(import (only-in :clan/poo/object .o .ref .slot? .call object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program))

(export ExchangeSigningOutcomeAlgebra.
        ExchangeSigningOutcomeCase.
        ExchangeSigningDirectFixture.
        ExchangeSigningDirectNoSignature.
        ExchangeSigningAdminFixture.
        ExchangeSigningAdminNoEffect.
        exchange-signing-outcome)

(def ExchangeSigningOutcomeAlgebra.
  (.o shapes:
      '((intents 3) (signatures 3) (outflows 4)
        (admin-intents 3) (admin-signatures 3) (admin-effects 3)
        (drains 4) (ordered-links 3))
      valid?:
      (lambda (algebra case-value)
        (and (object? case-value)
             (.slot? case-value 'kind)
             (eq? (.ref case-value 'kind)
                  'lambda-episteme.exchange.signing-outcome-case)
             (every
              (lambda (shape)
                (let ((slot (car shape)) (width (cadr shape)))
                  (and (.slot? case-value slot)
                       (every
                        (lambda (row)
                          (and (list? row) (= (length row) width)
                               (or (not (memq slot '(outflows drains)))
                                   (and (integer? (caddr row))
                                        (exact? (caddr row))
                                        (>= (caddr row) 0)))))
                        (.ref case-value slot)))))
              (.ref algebra 'shapes))))
      different:
      (lambda (intents signatures)
        (let loop ((pending intents) (result '()))
          (if (null? pending)
            result
            (let* ((intent (car pending))
                   (matches
                    (filter (lambda (signed)
                              (and (eq? (car intent) (car signed))
                                   (not (eq? (cadr intent) (cadr signed)))))
                            signatures)))
              (loop (cdr pending)
                    (append result
                            (map (lambda (signed)
                                   (list (car intent) (cadr intent)
                                         (cadr signed)))
                                 matches)))))))
      total:
      (lambda (rows)
        (let loop ((pending rows) (usd 0))
          (if (null? pending)
            usd
            (loop (cdr pending) (+ usd (caddr (car pending)))))))
      derive:
      (lambda (algebra case-value)
        (let* ((direct-different
                (.call algebra different (.ref case-value 'intents)
                       (.ref case-value 'signatures)))
               (admin-different
                (.call algebra different (.ref case-value 'admin-intents)
                       (.ref case-value 'admin-signatures)))
               (result
                (gerbil-ascent-evaluate-program
                 (ascent
                  (relation direct-mismatch (tx expected actual)
                    direct-different)
                  (relation signature (tx bytes source)
                    (.ref case-value 'signatures))
                  (relation outflow (tx bytes usd source)
                    (.ref case-value 'outflows))
                  (relation admin-mismatch (tx expected actual)
                    admin-different)
                  (relation admin-signature (tx bytes source)
                    (.ref case-value 'admin-signatures))
                  (relation admin-effect (tx wallet source)
                    (.ref case-value 'admin-effects))
                  (relation drain (tx wallet usd source)
                    (.ref case-value 'drains))
                  (relation ordered (admin-tx drain-tx source)
                    (.ref case-value 'ordered-links))
                  (relation direct-loss (tx bytes usd chain-source))
                  (relation indirect-loss (tx drain-tx usd chain-source))
                  ((direct-loss tx actual usd source) <--
                   (direct-mismatch tx expected actual)
                   (signature tx actual signer-source)
                   (outflow tx actual usd source))
                  ((indirect-loss admin-tx drain-tx usd source) <--
                   (admin-mismatch admin-tx expected actual)
                   (admin-signature admin-tx actual signer-source)
                   (admin-effect admin-tx wallet effect-source)
                   (ordered admin-tx drain-tx order-source)
                   (drain drain-tx wallet usd source))
                  (bounds 64 256 512))))
               (rows-of (.ref result 'rows-of))
               (direct (rows-of 'direct-loss))
               (indirect (rows-of 'indirect-loss)))
          (.o kind: 'lambda-episteme.exchange.signing-outcome-result
              direct-loss-rows: direct
              indirect-loss-rows: indirect
              direct-loss-usd: (.call algebra total direct)
              indirect-loss-usd: (.call algebra total indirect)
              fixture-only?: #t
              incident-attribution?: #f
              action-authority?: #f)))))

(def ExchangeSigningOutcomeCase.
  (.o kind: 'lambda-episteme.exchange.signing-outcome-case
      semantics: ExchangeSigningOutcomeAlgebra.
      intents: '()
      signatures: '()
      outflows: '()
      admin-intents: '()
      admin-signatures: '()
      admin-effects: '()
      drains: '()
      ordered-links: '()))

;;; Every amount and identity in these two Cases is synthetic. The source
;;; column shows where an independent deployment must bind real receipts.
(def ExchangeSigningDirectFixture.
  (.o (:: @ ExchangeSigningOutcomeCase.)
      intents:
      '((tx-a user-byte-a intent-owner)
        (tx-b user-byte-b intent-owner)
        (tx-c unchanged-byte intent-owner))
      signatures:
      '((tx-a attacker-byte-a signer-ingress)
        (tx-b attacker-byte-b signer-ingress)
        (tx-c unchanged-byte signer-ingress))
      outflows:
      '((tx-a attacker-byte-a 30000 chain-observer)
        (tx-b attacker-byte-b 45000 chain-observer)
        (tx-c unchanged-byte 5000 chain-observer))))

(def ExchangeSigningDirectNoSignature.
  (.o (:: @ ExchangeSigningDirectFixture.)
      signatures: '()))

;;; Bybit-inspired *shape*: a deceived signing interface can obtain an
;;; administrative signature; an independently observed contract change and
;;; a later drain are still required to connect that signature to a loss.
(def ExchangeSigningAdminFixture.
  (.o (:: @ ExchangeSigningOutcomeCase.)
      admin-intents: '((admin-tx routine-transfer intent-owner))
      admin-signatures: '((admin-tx admin-change signer-ingress))
      admin-effects: '((admin-tx wallet-a chain-state-observer))
      drains: '((drain-tx wallet-a 120000 chain-observer))
      ordered-links: '((admin-tx drain-tx chain-order-observer))))

(def ExchangeSigningAdminNoEffect.
  (.o (:: @ ExchangeSigningAdminFixture.)
      admin-effects: '()))

(def (exchange-signing-outcome case-value)
  (unless (and (object? case-value) (.slot? case-value 'semantics))
    (error "invalid Exchange signing outcome Case" case-value))
  (let (algebra (.ref case-value 'semantics))
    (unless (and (object? algebra) (.call algebra valid? algebra case-value))
      (error "invalid Exchange signing outcome Case" case-value))
    (.call algebra derive algebra case-value)))
