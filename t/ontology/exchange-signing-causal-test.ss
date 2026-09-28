;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/causal
                 exchange-signing-causal-trajectory))

(export exchange-signing-causal-test)

(def exchange-signing-causal-test
  (test-suite "Exchange signing causal trajectory"
    (poo-flow-test-case "public report cut excludes counterfactual ingress"
      (let (path (exchange-signing-causal-trajectory
                  'queue-injection '(queue-producer-attestation)))
        (check-equal? (.ref path 'assessment-status)
                      'causal-trajectory-admitted)
        (check-equal? (.ref path 'report-source)
                      "bitget/official-security-incident")
        (check-equal? (length (.ref path 'report-cut-event-ids)) 1)
        (check-equal? (.ref path 'historical-ingress-observed?) #f)
        (check-equal? (.ref path 'required-independent-evidence)
                      '(queue-producer-attestation))))
    (poo-flow-test-case "Bybit reference uses its own report source"
      (let (path (exchange-signing-causal-trajectory
                  'interface-substitution))
        (check-equal? (.ref path 'report-source)
                      "ncc-group/bybit-technical-analysis")))))
