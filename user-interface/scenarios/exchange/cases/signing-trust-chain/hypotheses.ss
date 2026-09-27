;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Abductive comparison over explicitly sourced observations. These rules
;;; produce discriminators, not an incident attribution or an authorization.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program))

(export ExchangeSigningHypothesisCase.
        ExchangeSigningPublicEvidence.
        exchange-signing-compare-hypotheses)

(def ExchangeSigningHypothesisCase.
  (.o kind: 'lambda-episteme.exchange.signing-hypothesis-case
      admitted-signals: '()
      provisional-signals: '()
      expectations:
      '((record-mutation unauthorized-outflow)
        (record-mutation withdrawal-without-intent)
        (api-replay unauthorized-outflow)
        (api-replay duplicate-request-id)
        (queue-injection unauthorized-outflow)
        (queue-injection orphan-queue-message)
        (address-map-substitution unauthorized-outflow)
        (address-map-substitution destination-mismatch)
        (interface-substitution unauthorized-outflow)
        (interface-substitution display-byte-mismatch))
      discriminators:
      '((withdrawal-without-intent)
        (duplicate-request-id)
        (orphan-queue-message)
        (destination-mismatch)
        (display-byte-mismatch))
      challenges:
      '((record-mutation authenticated-intent-exact)
        (api-replay one-use-request-record)
        (queue-injection verified-producer-chain)
        (address-map-substitution independently-matched-destination)
        (interface-substitution trusted-rendering-match))))

(def ExchangeSigningPublicEvidence.
  (.o (:: @ ExchangeSigningHypothesisCase.)
      admitted-signals: '((unauthorized-outflow bitget-public-notice))))

(def (signal-row? row)
  (and (list? row) (= (length row) 2)
       (symbol? (car row)) (symbol? (cadr row))))

(def (unary-row? row)
  (and (list? row) (= (length row) 1) (symbol? (car row))))

(def (hypothesis-case? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind admitted-signals provisional-signals expectations
                discriminators challenges))
       (eq? (.ref value 'kind)
            'lambda-episteme.exchange.signing-hypothesis-case)
       (every signal-row? (.ref value 'admitted-signals))
       (every signal-row? (.ref value 'provisional-signals))
       (every signal-row? (.ref value 'expectations))
       (every unary-row? (.ref value 'discriminators))
       (every signal-row? (.ref value 'challenges))))

(def (exchange-signing-compare-hypotheses case-value)
  (unless (hypothesis-case? case-value)
    (error "invalid Exchange signing hypothesis Case" case-value))
  (let* ((result
          (gerbil-ascent-evaluate-program
           (ascent
            (relation admitted (signal source)
              (.ref case-value 'admitted-signals))
            (relation provisional (signal source)
              (.ref case-value 'provisional-signals))
            (relation expects (hypothesis signal)
              (.ref case-value 'expectations))
            (relation discriminator (signal)
              (.ref case-value 'discriminators))
            (relation challenges (hypothesis signal)
              (.ref case-value 'challenges))
            (relation support (hypothesis signal source))
            (relation provisional-support (hypothesis signal source))
            (relation specific-support (hypothesis signal source))
            (relation challenged (hypothesis signal source))
            ((support h s src) <-- (expects h s) (admitted s src))
            ((provisional-support h s src) <--
             (expects h s) (provisional s src))
            ((specific-support h s src) <--
             (support h s src) (discriminator s))
            ((challenged h s src) <--
             (challenges h s) (admitted s src))
            (bounds 64 256 512))))
         (rows-of (.ref result 'rows-of)))
    (.o kind: 'lambda-episteme.exchange.signing-hypothesis-result
        support: (rows-of 'support)
        provisional-support: (rows-of 'provisional-support)
        specific-support: (rows-of 'specific-support)
        challenged: (rows-of 'challenged)
        hypothesis-confirmed?: #f
        action-authority?: #f)))
