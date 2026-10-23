;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Abductive comparison over explicitly sourced observations. These rules
;;; produce discriminators, not an incident attribution or an authorization.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-count
                 gerbil-ascent-evaluate-program))

(export ExchangeSigningHypothesisCase.
        ExchangeSigningPublicEvidence.
        exchange-signing-compare-hypotheses
        ExchangeSigningFamilyCase.
        ExchangeSigningReportedFamilyEvidence.
        exchange-signing-compare-families)

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
        (interface-substitution display-byte-mismatch)
        (admin-change-path unauthorized-outflow)
        (admin-change-path observed-admin-effect))
      discriminators:
      '((withdrawal-without-intent)
        (duplicate-request-id)
        (orphan-queue-message)
        (destination-mismatch)
        (display-byte-mismatch)
        (observed-admin-effect))
      challenges:
      '((record-mutation authenticated-intent-exact)
        (api-replay one-use-request-record)
        (queue-injection verified-producer-chain)
        (address-map-substitution independently-matched-destination)
        (interface-substitution trusted-rendering-match)
        (admin-change-path complete-transfer-only-signing-ledger))))

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

;;; A separate, coarser inference answers which *effect family* best explains
;;; the published record. Reported facts retain their source; they are not
;;; signer ingress receipts or MRR-admitted evidence. Missing facts are unknown,
;;; never negative evidence. The ranking is a conditional model comparison,
;;; not a calibrated probability or a claim about the exact entry point.
(def ExchangeSigningFamilyCase.
  (.o kind: 'lambda-episteme.exchange.signing-family-case
      reported-signals: '()
      families:
      '(backend-signed-transfer backend-admin-change
        interface-admin-change key-exfiltration)
      expectations:
      '((backend-signed-transfer backend-compromise)
        (backend-signed-transfer spoofed-transaction-data)
        (backend-signed-transfer wallet-signed-transfers)
        (backend-signed-transfer cross-chain-bursts)
        (backend-signed-transfer fixed-round-gas-limits)
        (backend-admin-change backend-compromise)
        (backend-admin-change spoofed-transaction-data)
        (backend-admin-change observed-admin-effect)
        (interface-admin-change display-byte-mismatch)
        (interface-admin-change observed-admin-effect)
        (key-exfiltration private-key-compromise))
      selection-requirements:
      '((backend-signed-transfer wallet-signed-transfers)
        (backend-signed-transfer fixed-round-gas-limits)
        (backend-admin-change observed-admin-effect)
        (interface-admin-change display-byte-mismatch)
        (interface-admin-change observed-admin-effect)
        (key-exfiltration private-key-compromise))
      challenges:
      '((backend-signed-transfer observed-admin-effect)
        (key-exfiltration no-private-key-compromise))))

(def ExchangeSigningReportedFamilyEvidence.
  (.o (:: @ ExchangeSigningFamilyCase.)
      reported-signals:
      '((backend-compromise bitget-incident-explainer)
        (spoofed-transaction-data bitget-incident-explainer)
        (no-private-key-compromise bitget-incident-explainer)
        (wallet-signed-transfers bitquery-chain-analysis)
        (cross-chain-bursts bitquery-chain-analysis)
        (fixed-round-gas-limits bitquery-chain-analysis))))

(def (family-case? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind reported-signals families expectations
                selection-requirements challenges))
       (eq? (.ref value 'kind)
            'lambda-episteme.exchange.signing-family-case)
       (every signal-row? (.ref value 'reported-signals))
       (every symbol? (.ref value 'families))
       (every signal-row? (.ref value 'expectations))
       (every signal-row? (.ref value 'selection-requirements))
       (every signal-row? (.ref value 'challenges))))

(def (family-fit family expectations signals counts requirements challenges)
  (let* ((required (filter (lambda (row) (eq? (car row) family)) expectations))
         (count-row (assoc family counts))
         (counter (filter (lambda (row) (eq? (car row) family)) challenges))
         (eligible?
          (every (lambda (row)
                   (member row signals))
                 (filter (lambda (row) (eq? (car row) family)) requirements))))
    (list family (if count-row (cadr count-row) 0) (length required)
          (length counter) (and eligible? (null? counter)))))

(def (exchange-signing-compare-families case-value)
  (unless (family-case? case-value)
    (error "invalid Exchange signing family Case" case-value))
  (let* ((result
          (gerbil-ascent-evaluate-program
           (ascent
            (relation reported (signal source)
              (.ref case-value 'reported-signals))
            (relation expects-family (family signal)
              (.ref case-value 'expectations))
            (relation challenges-family (family signal)
              (.ref case-value 'challenges))
            (relation family (identity)
              (map list (.ref case-value 'families)))
            (relation family-match (family signal source))
            (relation family-signal (family signal))
            (relation family-count (family total))
            (relation family-counter (family signal source))
            ((family-match h s src) <--
             (expects-family h s) (reported s src))
            ((family-signal h s) <-- (family-match h s src))
            ((family-count h total) <-- (family h)
             (aggregate total gerbil-ascent-count () (family-signal h s)))
            ((family-counter h s src) <--
             (challenges-family h s) (reported s src))
            (bounds 64 256 512))))
         (rows-of (.ref result 'rows-of))
         (matches (rows-of 'family-match))
         (signals (rows-of 'family-signal))
         (counts (rows-of 'family-count))
         (counters (rows-of 'family-counter))
         (fits
          (map (lambda (family)
                 (family-fit family (.ref case-value 'expectations) signals
                             counts
                             (.ref case-value 'selection-requirements)
                             counters))
               (.ref case-value 'families)))
         (compatible
          (map car (filter (lambda (fit) (list-ref fit 4)) fits))))
    (.o kind: 'lambda-episteme.exchange.signing-family-result
        fit: fits
        matched: matches
        challenged: counters
        model-compatible-families: compatible
        conditional-on-reports?: #t
        exact-entry-point-known?: #f
        action-authority?: #f)))
