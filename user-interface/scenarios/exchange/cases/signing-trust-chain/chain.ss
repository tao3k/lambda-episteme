;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A source-preserving qualification handoff. GQL specifies the observation
;;; selection, ASCENT ranks replay hypotheses, TLA+ checks the corresponding
;;; finite threat path, and Lean/Cedar checks its authorization cut. This does
;;; not execute GQL or admit external evidence into the signer Host.
(import (only-in :clan/poo/object .o .ref .slot? .call object?)
        (only-in :std/list/list every)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/query
                 ExchangeSigningSignalQuery ExchangeSigningSignalSource)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/hypotheses
                 ExchangeSigningReportedFamilyEvidence.
                 exchange-signing-compare-families))

(export ExchangeSigningChainCase.
        ExchangeSigningReportedChain.
        exchange-signing-plan-chain)

(def ExchangeSigningChainCase.
  (.o kind: 'lambda-episteme.exchange.signing-chain-case
      query: ExchangeSigningSignalQuery
      query-source: ExchangeSigningSignalSource
      hypothesis: ExchangeSigningReportedFamilyEvidence.
      resolve:
      (lambda (family)
        (case family
          ((backend-signed-transfer)
           (.o tla-config: "DirectAttack.cfg"
               cedar-root: "Integrated"
               host-cut: 'independent-byte-and-operation-binding))
          ((backend-admin-change)
           (.o tla-config: "AdminAttack.cfg"
               cedar-root: "Integrated"
               host-cut: 'independent-byte-and-operation-binding))
          ((interface-admin-change)
           (.o tla-config: "InterfaceAttack.cfg"
               cedar-root: "Integrated"
               host-cut: 'independent-display-and-operation-binding))
          (else #f)))))

(def ExchangeSigningReportedChain.
  (.o (:: @ ExchangeSigningChainCase.)))

(def (exchange-signing-plan-chain case-value)
  (unless (and (object? case-value)
               (.slot? case-value 'query)
               (.slot? case-value 'hypothesis)
               (.slot? case-value 'resolve))
    (error "invalid Exchange signing chain Case" case-value))
  (let* ((query (.ref case-value 'query))
         (hypothesis (.ref case-value 'hypothesis))
         (selected (.ref query 'selected-element-identities))
         (reported (.ref hypothesis 'reported-signals)))
    (unless (every (lambda (row) (memq (car row) selected)) reported)
      (error "Exchange signing GQL selection omits a reported signal"))
    (let* ((compared (exchange-signing-compare-families hypothesis))
           (compatible (.ref compared 'model-compatible-families))
           (handoffs
            (filter-map
             (lambda (fit)
               (let* ((family-id (car fit))
                      (route (.call case-value resolve family-id)))
                 (and route
                      (.o kind: 'lambda-episteme.exchange.family-handoff
                          family: family-id
                          model-fit: fit
                          model-compatible?:
                          (and (memq family-id compatible) #t)
                          tla-config: (.ref route 'tla-config)
                          cedar-root: (.ref route 'cedar-root)
                          host-cut: (.ref route 'host-cut)))))
             (.ref compared 'fit))))
      (.o kind: 'lambda-episteme.exchange.signing-chain-result
          gql-source: (.ref case-value 'query-source)
          gql-source-identity: (.ref query 'semantic-revision)
          gql-selected-identities: selected
          reported-sources: (map cadr reported)
          reported-signal-rows: reported
          model-compatible-families: compatible
          family-handoffs: handoffs
          preliminary-family-screen?: #t
          route-qualification-required?: #t
          family-fit: (.ref compared 'fit)
          family-matches: (.ref compared 'matched)
          family-challenges: (.ref compared 'challenged)
          tla-configs: (map (lambda (row) (.ref row 'tla-config)) handoffs)
          cedar-roots: (map (lambda (row) (.ref row 'cedar-root)) handoffs)
          host-cuts: (map (lambda (row) (.ref row 'host-cut)) handoffs)
          gql-executed?: #f
          evidence-admitted?: #f
          handoff-resolved?: (pair? handoffs)
          action-authority?: #f))))
