;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Conditional comparison of four backend ingress hypotheses. Factor values
;;; are explicit model assumptions, not measured incident frequencies or
;;; calibrated likelihoods. Ascent preserves each signal/source/factor join;
;;; the small Scheme fold computes transparent relative support shares.
(import (only-in :clan/poo/object .o .ref object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program)
        (only-in "hypotheses.ss"
                 ExchangeSigningReportedFamilyEvidence.))

(export ExchangeSigningIngressCase.
        ExchangeSigningPublicIngress.
        exchange-signing-compare-ingress)

(def ExchangeSigningIngressCase.
  (.o kind: 'lambda-episteme.exchange.signing-ingress-case
      structural-risk: 'signed-but-unintended-effect
      reference-case: 'bybit-2025-safe-interface-admin-change
      reference-source: 'bybit-official-timeline
      reference-use: 'threat-class-validation-only
      routes:
      '(record-mutation api-replay queue-injection address-map-substitution)
      reported-signals: '()
      independent-signals: '()
      model-factors:
      '((api-replay fixed-round-gas-limits 2 internal-operation-shape)
        (queue-injection fixed-round-gas-limits 2 internal-operation-shape)
        (record-mutation withdrawal-without-intent 4 exact-intent-receipt)
        (api-replay duplicate-request-id 4 signer-request-ledger)
        (queue-injection orphan-queue-message 4 signer-ingress-ledger)
        (address-map-substitution destination-mismatch 4 destination-binding))
      hard-challenges:
      '((record-mutation authenticated-intent-exact)
        (api-replay one-use-request-record)
        (queue-injection verified-producer-chain)
        (address-map-substitution independently-matched-destination))
      evidence-questions:
      '((record-mutation withdrawal-without-intent)
        (api-replay duplicate-request-id)
        (queue-injection orphan-queue-message)
        (address-map-substitution destination-mismatch))))

(def ExchangeSigningPublicIngress.
  (.o (:: @ ExchangeSigningIngressCase.)
      reported-signals:
      (.ref ExchangeSigningReportedFamilyEvidence. 'reported-signals)))

(def (signal-row? row)
  (and (list? row) (= (length row) 2)
       (symbol? (car row)) (symbol? (cadr row))))

(def (factor-row? row)
  (and (list? row) (= (length row) 4)
       (symbol? (car row)) (symbol? (cadr row))
       (integer? (caddr row)) (> (caddr row) 0)
       (symbol? (cadddr row))))

(def (model-case? value)
  (and (object? value)
       (eq? (.ref value 'kind)
            'lambda-episteme.exchange.signing-ingress-case)
       (every symbol? (.ref value 'routes))
       (every signal-row? (.ref value 'reported-signals))
       (every signal-row? (.ref value 'independent-signals))
       (every factor-row? (.ref value 'model-factors))
       (every signal-row? (.ref value 'hard-challenges))
       (every signal-row? (.ref value 'evidence-questions))))

(def (route-weight route hits challenges)
  (if (assoc route challenges)
    0
    (let loop ((pending hits) (weight 1))
      (if (null? pending) weight
        (loop (cdr pending)
              (if (eq? route (caar pending))
                (* weight (caddar pending))
                weight))))))

(def (insert-ranked score ranked)
  (cond
   ((null? ranked) (list score))
   ((> (cadr score) (cadar ranked)) (cons score ranked))
   (else (cons (car ranked) (insert-ranked score (cdr ranked))))))

(def (exchange-signing-compare-ingress case-value
                                      (eligible-routes #f))
  (unless (model-case? case-value)
    (error "invalid Exchange signing ingress Case" case-value))
  (let* ((eligible (or eligible-routes (.ref case-value 'routes)))
         (_ (unless (and (list? eligible)
                         (every (lambda (route)
                                  (memq route (.ref case-value 'routes)))
                                eligible))
              (error "invalid causal/TLA route eligibility" eligible)))
         (observations
          (append
           (map (lambda (row) (list (car row) (cadr row) 'reported))
                (.ref case-value 'reported-signals))
           (map (lambda (row) (list (car row) (cadr row) 'independent))
                (.ref case-value 'independent-signals))))
         (result
          (gerbil-ascent-evaluate-program
           (ascent
            (relation observation (signal source class) observations)
            (relation eligible-route (route)
              (map list eligible))
            (relation factor (route signal multiplier assumption)
              (.ref case-value 'model-factors))
            (relation challenge (route signal)
              (.ref case-value 'hard-challenges))
            (relation factor-match
              (route signal multiplier assumption source class))
            (relation factor-hit (route signal multiplier assumption))
            (relation challenge-hit (route signal source))
            ((factor-match r s multiplier assumption src class) <--
             (eligible-route r)
             (factor r s multiplier assumption)
             (observation s src class))
            ((factor-hit r s multiplier assumption) <--
             (factor-match r s multiplier assumption src class))
            ((challenge-hit r s src) <--
             (eligible-route r)
             (challenge r s) (observation s src independent))
            (bounds 64 256 512))))
         (rows-of (.ref result 'rows-of))
         (matches (rows-of 'factor-match))
         (hits (rows-of 'factor-hit))
         (challenges (rows-of 'challenge-hit))
         (scores
          (map (lambda (route)
                 (list route (route-weight route hits challenges)))
               eligible))
         (ranked (foldl (lambda (score ordered)
                          (insert-ranked score ordered))
                        '() scores))
         (total (apply + (map cadr scores)))
         (leaders
          (if (or (null? ranked) (zero? (cadar ranked))) '()
            (map car
                 (filter (lambda (score)
                           (= (cadr score) (cadar ranked)))
                         ranked)))))
    (.o kind: 'lambda-episteme.exchange.signing-ingress-comparison
        structural-risk: (.ref case-value 'structural-risk)
        reference-case: (.ref case-value 'reference-case)
        reference-source: (.ref case-value 'reference-source)
        reference-use: (.ref case-value 'reference-use)
        eligible-routes: eligible
        ranked-support: ranked
        relative-support-shares:
        (map (lambda (score) (list (car score) (cadr score) total)) ranked)
        leading-routes: leaders
        source-linked-factor-matches: matches
        applied-factors: hits
        independent-challenges: challenges
        evidence-questions: (.ref case-value 'evidence-questions)
        model-factors: (.ref case-value 'model-factors)
        conditional-on-reports?: #t
        calibrated-probabilities?: #f
        route-attributed?: #f
        action-authority?: #f)))
