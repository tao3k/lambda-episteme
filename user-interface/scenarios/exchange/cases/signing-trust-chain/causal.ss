;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; A public report anchors a prospective threat trajectory. The proposed
;;; ingress, signing and recurrence are counterfactual, never incident facts.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/modules/temporal-causality/interface
                 poo-flow-temporal-observation
                 poo-flow-causal-event
                 poo-flow-causal-event-graph
                 poo-flow-causal-trajectory-contract
                 poo-flow-causal-trajectory-assess
                 poo-flow-causal-trajectory-assessment-digest
                 poo-flow-causal-cut))

(export exchange-signing-causal-trajectory)

(def (exchange-signing-causal-trajectory route-name
                                         (required-evidence '()))
  (unless (memq route-name '(record-mutation api-replay queue-injection
                        address-map-substitution interface-substitution
                        backend-admin-change))
    (error "unknown Exchange signing causal route" route-name))
  (let* ((prefix (string-append "exchange/signing/" (symbol->string route-name)))
         (subject (string-append prefix "/recurrence-model"))
         (source-identity
          (if (eq? route-name 'interface-substitution)
            "ncc-group/bybit-technical-analysis"
            "bitget/official-security-incident"))
         (report (string-append prefix "/public-report"))
         (review (string-append prefix "/declared-independent-review"))
         (ingress (string-append prefix "/proposed-ingress"))
         (signature (string-append prefix "/weak-signature"))
         (effect (string-append prefix "/unauthorized-effect"))
         (impact (string-append prefix "/potential-loss"))
         (event
          (lambda (id kind position parents modality committed? provenance)
            (poo-flow-causal-event
             id subject kind
             (poo-flow-temporal-observation
              (string-append id "/time") 'logical-version position provenance)
             id parents modality committed?)))
         (graph
          (poo-flow-causal-event-graph
           subject
           (list (event report 'public-incident-report 0 '() 'observed #t
                        source-identity)
                 (event review 'independent-review 1 (list report)
                        'declared #f "exchange/response-contract")
                 (event ingress route-name 1 (list report) 'counterfactual #f
                        "exchange/route-assumption")
                 (event signature 'weak-signing-boundary 2 (list ingress)
                        'counterfactual #f "exchange/threat-model")
                 (event effect 'unauthorized-transfer 3 (list signature)
                        'counterfactual #f "exchange/threat-model")
                 (event impact 'potential-loss 4 (list effect)
                        'hypothesized #f "exchange/impact-assumption"))))
         (contract
          (poo-flow-causal-trajectory-contract
           (string-append prefix "/trajectory") report (list review)
           (list (list ingress signature effect)) '() (list impact)))
         (assessment (poo-flow-causal-trajectory-assess contract graph))
         (cut (poo-flow-causal-cut graph 0)))
    (.o kind: 'lambda-episteme.exchange.signing-causal-trajectory
        route: route-name
        graph-identity: (.ref graph 'identity)
        report-source: source-identity
        assessment-status: (.ref assessment 'status)
        assessment-digest:
        (poo-flow-causal-trajectory-assessment-digest assessment)
        report-cut-complete?: (.ref cut 'complete?)
        report-cut-event-ids: (map (lambda (e) (.ref e 'identity))
                                   (.ref cut 'events))
        proposed-path: (list ingress signature effect)
        first-unobserved-frontier: ingress
        required-independent-evidence: required-evidence
        historical-ingress-observed?: #f
        action-authority?: #f)))
