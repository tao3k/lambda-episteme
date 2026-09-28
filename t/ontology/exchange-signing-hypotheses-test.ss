;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :clan/poo/object .o .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/hypotheses
                 ExchangeSigningPublicEvidence.
                 exchange-signing-compare-hypotheses
                 ExchangeSigningFamilyCase.
                 ExchangeSigningReportedFamilyEvidence.
                 exchange-signing-rank-families))

(export exchange-signing-hypotheses-test)

(def (contains? rows value)
  (not (not (member value rows))))

(def exchange-signing-hypotheses-test
  (test-suite "Exchange signing hypothesis discriminators"
    (poo-flow-test-case "public outflow leaves every ingress hypothesis open"
      (let (result
            (exchange-signing-compare-hypotheses
             ExchangeSigningPublicEvidence.))
        (check-equal? (length (.ref result 'support)) 6)
        (check-equal? (.ref result 'specific-support) '())
        (check-equal? (.ref result 'challenged) '())
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))
    (poo-flow-test-case "a provisional backend log cannot become admitted support"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  provisional-signals:
                  '((orphan-queue-message backend-controlled-log))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal? (.ref result 'specific-support) '())
        (check-equal?
         (contains? (.ref result 'provisional-support)
                    '(queue-injection orphan-queue-message
                      backend-controlled-log)) #t)))
    (poo-flow-test-case "independent queue evidence narrows but does not prove ingress"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (orphan-queue-message independent-signer-log))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (.ref result 'specific-support)
         '((queue-injection orphan-queue-message independent-signer-log)))
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)
        (check-equal? (.ref result 'action-authority?) #f)))
    (poo-flow-test-case "an observed admin effect narrows operation, not ingress"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (observed-admin-effect independent-chain-receipt))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (contains? (.ref result 'specific-support)
                    '(admin-change-path observed-admin-effect
                      independent-chain-receipt)) #t)
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))
    (poo-flow-test-case "contradictory independent observations remain visible"
      (let* ((case-value
              (.o (:: @ ExchangeSigningPublicEvidence.)
                  admitted-signals:
                  '((unauthorized-outflow bitget-public-notice)
                    (orphan-queue-message independent-signer-log)
                    (verified-producer-chain independent-queue-audit))))
             (result (exchange-signing-compare-hypotheses case-value)))
        (check-equal?
         (contains? (.ref result 'specific-support)
                    '(queue-injection orphan-queue-message
                      independent-signer-log)) #t)
        (check-equal?
         (contains? (.ref result 'challenged)
                    '(queue-injection verified-producer-chain
                      independent-queue-audit)) #t)
        (check-equal? (.ref result 'hypothesis-confirmed?) #f)))
    (poo-flow-test-case "published record favors backend signed transfer family"
      (let (result (exchange-signing-rank-families
                    ExchangeSigningReportedFamilyEvidence.))
        (check-equal? (.ref result 'preferred-family)
                      'backend-signed-transfer)
        (check-equal? (car (.ref result 'fit))
                      '(backend-signed-transfer 5 5 0 #t))
        (check-equal? (.ref result 'conditional-on-reports?) #t)
        (check-equal? (.ref result 'exact-entry-point-known?) #f)))
    (poo-flow-test-case "backend report alone cannot select an effect family"
      (let* ((case-value
              (.o (:: @ ExchangeSigningFamilyCase.)
                  reported-signals:
                  '((backend-compromise bitget-incident-explainer)
                    (spoofed-transaction-data bitget-incident-explainer))))
             (result (exchange-signing-rank-families case-value)))
        (check-equal? (.ref result 'preferred-family) 'undetermined)))
    (poo-flow-test-case "without the gas discriminator the family stays open"
      (let* ((case-value
              (.o (:: @ ExchangeSigningReportedFamilyEvidence.)
                  reported-signals:
                  '((backend-compromise bitget-incident-explainer)
                    (spoofed-transaction-data bitget-incident-explainer)
                    (no-private-key-compromise bitget-incident-explainer)
                    (wallet-signed-transfers bitquery-chain-analysis)
                    (cross-chain-bursts bitquery-chain-analysis))))
             (result (exchange-signing-rank-families case-value)))
        (check-equal? (.ref result 'preferred-family) 'undetermined)))
    (poo-flow-test-case "an observed control change redirects the family"
      (let* ((case-value
              (.o (:: @ ExchangeSigningFamilyCase.)
                  reported-signals:
                  '((backend-compromise independent-backend-receipt)
                    (spoofed-transaction-data independent-ingress-receipt)
                    (observed-admin-effect independent-chain-receipt))))
             (result (exchange-signing-rank-families case-value)))
        (check-equal? (.ref result 'preferred-family)
                      'backend-admin-change)))
    (poo-flow-test-case "extra reporter does not count one signal twice"
      (let* ((case-value
              (.o (:: @ ExchangeSigningReportedFamilyEvidence.)
                  reported-signals:
                  (cons '(fixed-round-gas-limits second-chain-analysis)
                        (.ref ExchangeSigningReportedFamilyEvidence.
                              'reported-signals))))
             (result (exchange-signing-rank-families case-value)))
        (check-equal? (car (.ref result 'fit))
                      '(backend-signed-transfer 5 5 0 #t))))))
