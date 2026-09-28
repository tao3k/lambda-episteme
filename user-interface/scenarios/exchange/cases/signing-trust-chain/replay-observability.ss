;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A source-preserving diagnostic projection for one named attack composition.
;;; Public observations, synthetic route links, and missing independent
;;; witnesses remain distinct. This projection never admits evidence or runs
;;; TLC, GQL, Lean, or Cedar on behalf of the caller.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :poo-flow/src/scenario/accessors
                 poo-flow-scenario-case-profiles)
        (only-in "chain.ss"
                 ExchangeSigningReportedChain.
                 exchange-signing-plan-chain)
        (only-in "reasoning.ss" exchange-signing-route-candidates)
        (only-in "simulation.ss" ExchangeSigningBybitReference.)
        (only-in "causal.ss" exchange-signing-causal-trajectory)
        (only-in "flow-profiles.ss"
                 ExchangeSigningRecordMutationProfile.
                 ExchangeSigningApiReplayProfile.
                 ExchangeSigningQueueInjectionProfile.
                 ExchangeSigningAddressMapProfile.)
        (only-in "ingress-inference.ss"
                 ExchangeSigningPublicIngress.
                 exchange-signing-compare-ingress)
        (only-in "signal-result.ss"
                 exchange-signing-run-signal-query))

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

(def direct-profiles
  (list (list ExchangeSigningRecordMutationProfile. "entry = \"backend-record\""
              "missingWitness = \"record-intent\"")
        (list ExchangeSigningApiReplayProfile. "entry = \"internal-api\""
              "missingWitness = \"request-identity\"")
        (list ExchangeSigningQueueInjectionProfile. "entry = \"queue-producer\""
              "missingWitness = \"producer-chain\"")
        (list ExchangeSigningAddressMapProfile.
              "entry = \"address-map\""
              "missingWitness = \"destination-binding\"")))

(def (route-qualification entry qualifications)
  (let* ((profile (car entry))
         (causal (exchange-signing-causal-trajectory
                  (.ref profile 'identity)
                  (.ref profile 'observation-needs)))
         (row (assoc (.ref profile 'tla-config) qualifications)))
    (and (eq? (.ref causal 'assessment-status) 'causal-trajectory-admitted)
         (.ref causal 'report-cut-complete?)
         row (eq? (cadr row) 'counterexample)
         (member (cadr entry) (cadddr row))
         (member (caddr entry) (cadddr row))
         (member "WeakSign" (cadddr row))
         (member "ApplyTransfer" (cadddr row))
         (list (.ref profile 'identity)
               (.ref causal 'assessment-digest)
               (.ref profile 'tla-config)
               (cadr entry) (caddr entry)))))

(def (exchange-signing-replay-observability composition
                                            (observations '())
                                            (qualifications '())
                                            (signal-nodes #f))
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
         (reference-routes
          (exchange-signing-route-candidates ExchangeSigningBybitReference.))
         (causal (exchange-signing-causal-trajectory
                  (.ref profile 'identity)
                  (.ref profile 'observation-needs)))
         (bindings-value
          (filter-map (lambda (entry)
                        (route-qualification entry qualifications))
                      direct-profiles))
         (qualified-routes (map car bindings-value))
         (chain (exchange-signing-plan-chain ExchangeSigningReportedChain.))
         (query-result
          (and signal-nodes
               (exchange-signing-run-signal-query signal-nodes)))
         (selected-rows (if query-result (.ref query-result 'rows) '()))
         (independent-rows
          (map (lambda (row) (list (car row) (cadr row)))
               (filter (lambda (row) (eq? (caddr row) 'admitted))
                       (append observations selected-rows))))
         (ingress-case-value
          (.o (:: @ ExchangeSigningPublicIngress.)
              independent-signals: independent-rows))
         (ingress
          (and (memq (.ref profile 'identity)
                     '(record-mutation api-replay queue-injection
                       address-map-substitution))
               (pair? qualified-routes)
               (exchange-signing-compare-ingress
                ingress-case-value qualified-routes)))
         (neutral-ingress
          (and ingress
               (exchange-signing-compare-ingress
                (.o (:: @ ingress-case-value)
                    model-factors:
                    (filter
                     (lambda (row)
                       (not (eq? (cadr row) 'fixed-round-gas-limits)))
                     (.ref ingress-case-value 'model-factors)))
                qualified-routes)))
         (qualification
          (assoc (.ref profile 'tla-config) qualifications))
         (needed (.ref profile 'observation-needs))
         (missing (filter (lambda (signal)
                            (not (admitted-signal? signal observations)))
                          needed)))
    (.o kind: 'lambda-episteme.exchange.signing-replay-observability
        composition: (.ref composition 'name)
        attack-profile: (.ref profile 'identity)
        causal-assessment-status: (.ref causal 'assessment-status)
        causal-assessment-digest: (.ref causal 'assessment-digest)
        causal-report-source: (.ref causal 'report-source)
        causal-report-cut-event-ids: (.ref causal 'report-cut-event-ids)
        causal-proposed-path: (.ref causal 'proposed-path)
        causal-first-unobserved-frontier:
        (.ref causal 'first-unobserved-frontier)
        causal-required-independent-evidence:
        (.ref causal 'required-independent-evidence)
        historical-ingress-observed?: #f
        causal-tla-bindings: bindings-value
        causally-and-temporally-qualified-routes: qualified-routes
        public-observed-edges: (.ref routes 'observed-edges)
        synthetic-proposed-edges: (.ref routes 'proposed-edges)
        possible-candidates: (.ref routes 'possible-candidates)
        observed-candidates: (.ref routes 'observed-candidates)
        supplied-observations: observations
        query-selected-rows: selected-rows
        query-executed-in-scheme?: (and query-result #t)
        query-result-provenance-verified?: #f
        caller-declared-independent-signals:
        (map (lambda (row) (list (car row) (cadr row)))
             (filter (lambda (row) (eq? (caddr row) 'admitted))
                     observations))
        conditional-independent-signals: independent-rows
        input-provenance-verified?: #f
        missing-independent-observations: missing
        public-family-preference: (.ref chain 'preferred-family)
        public-family-screen-preliminary?: #t
        public-family-fit: (.ref chain 'family-fit)
        public-family-matches: (.ref chain 'family-matches)
        public-family-challenges: (.ref chain 'family-challenges)
        reported-signal-rows: (.ref chain 'reported-signal-rows)
        reported-sources: (.ref chain 'reported-sources)
        gql-source-identity: (.ref chain 'gql-source-identity)
        gql-selected-identities: (.ref chain 'gql-selected-identities)
        structural-risk: 'signed-but-unintended-effect
        bybit-reference-use: 'threat-class-validation-only
        bybit-reference-observed-route:
        (.ref reference-routes 'observed-candidates)
        bybit-reference-operation:
        (.ref ExchangeSigningBybitReference. 'operation-kind)
        bybit-reference-control-change:
        (.ref ExchangeSigningBybitReference. 'control-change)
        bybit-display-witness-status:
        (.ref ExchangeSigningBybitReference. 'display-witness-status)
        ingress-leading-routes:
        (and ingress (.ref ingress 'leading-routes))
        ingress-relative-support-shares:
        (and ingress (.ref ingress 'relative-support-shares))
        ingress-without-gas-assumption:
        (and neutral-ingress (.ref neutral-ingress 'relative-support-shares))
        ingress-source-linked-matches:
        (and ingress (.ref ingress 'source-linked-factor-matches))
        ingress-applied-assumptions:
        (and ingress (.ref ingress 'applied-factors))
        ingress-next-probes:
        (and ingress (.ref ingress 'next-probes))
        ingress-calibrated-probabilities?: #f
        ingress-ranking-status:
        (cond ((null? qualified-routes) 'awaiting-tla-qualification)
              ((= (length qualified-routes) (length direct-profiles))
               'all-modeled-routes-qualified)
              (else 'partial-route-qualification))
        tla-config: (.ref profile 'tla-config)
        tla-qualification-status:
        (if qualification (cadr qualification) 'not-supplied)
        tla-counterexample-transitions:
        (if qualification (cadddr qualification) '())
        cedar-root: (.ref chain 'cedar-root)
        cedar-runtime-status: 'not-supplied
        gql-executed?: (and query-result #t)
        evidence-admitted?: #f
        route-attributed?: #f
        action-authority?: #f)))
