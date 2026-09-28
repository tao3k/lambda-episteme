;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A source-preserving diagnostic projection for one named attack composition.
;;; Public observations, synthetic route links, and missing independent
;;; witnesses remain distinct. This projection never admits evidence or runs
;;; TLC, GQL, Lean, or Cedar on behalf of the caller.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :poo-flow/src/module-system/profile-composition/accessors
                 poo-flow-scenario-case-profiles)
        (only-in "chain.ss"
                 ExchangeSigningReportedChain.
                 exchange-signing-plan-chain)
        (only-in "reasoning.ss" exchange-signing-route-candidates))

(export exchange-signing-replay-observability)

(def (attack-profile profiles)
  (cond
   ((null? profiles)
    (error "composition has no Exchange signing attack Profile"))
   ((and (object? (car profiles))
         (.slot? (car profiles) 'module)
         (eq? (.ref (car profiles) 'module) 'exchange-signing))
    (car profiles))
   (else (attack-profile (cdr profiles)))))

(def (observation-row? row)
  (and (list? row) (= (length row) 3)
       (symbol? (car row)) (symbol? (cadr row))
       (memq (caddr row) '(admitted provisional))))

(def (admitted-signal? signal observations)
  (let loop ((pending observations))
    (and (pair? pending)
         (or (and (eq? signal (caar pending))
                  (eq? (caddar pending) 'admitted))
             (loop (cdr pending))))))

(def (qualification-row? row)
  (and (list? row) (= (length row) 4)
       (string? (car row))
       (memq (cadr row) '(defended counterexample))
       (eq? (caddr row) 'NoUnauthorizedEffect)
       (list? (cadddr row))
       (andmap string? (cadddr row))))

(def (exchange-signing-replay-observability composition
                                            (observations '())
                                            (qualifications '()))
  (unless (and (list? observations)
               (andmap observation-row? observations))
    (error "observations require (signal source admitted|provisional) rows"
           observations))
  (unless (and (list? qualifications)
               (andmap qualification-row? qualifications))
    (error "invalid TLA+ qualification rows" qualifications))
  (let* ((profile
          (attack-profile (poo-flow-scenario-case-profiles composition)))
         (route-case (.ref profile 'route-case))
         (routes (exchange-signing-route-candidates route-case))
         (chain (exchange-signing-plan-chain ExchangeSigningReportedChain.))
         (qualification
          (assoc (.ref profile 'tla-config) qualifications))
         (needed (.ref profile 'observation-needs))
         (missing (filter (lambda (signal)
                            (not (admitted-signal? signal observations)))
                          needed)))
    (.o kind: 'lambda-episteme.exchange.signing-replay-observability
        composition: (.ref composition 'name)
        attack-profile: (.ref profile 'identity)
        public-observed-edges: (.ref routes 'observed-edges)
        synthetic-proposed-edges: (.ref routes 'proposed-edges)
        possible-candidates: (.ref routes 'possible-candidates)
        observed-candidates: (.ref routes 'observed-candidates)
        supplied-observations: observations
        missing-independent-observations: missing
        public-family-preference: (.ref chain 'preferred-family)
        public-family-fit: (.ref chain 'family-fit)
        public-family-matches: (.ref chain 'family-matches)
        public-family-challenges: (.ref chain 'family-challenges)
        reported-signal-rows: (.ref chain 'reported-signal-rows)
        reported-sources: (.ref chain 'reported-sources)
        tla-config: (.ref profile 'tla-config)
        tla-qualification-status:
        (if qualification (cadr qualification) 'not-supplied)
        tla-counterexample-transitions:
        (if qualification (cadddr qualification) '())
        cedar-root: (.ref chain 'cedar-root)
        cedar-runtime-status: 'not-supplied
        gql-executed?: #f
        evidence-admitted?: #f
        route-attributed?: #f
        action-authority?: #f)))
