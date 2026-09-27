;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Synthetic attack-chain snapshots, never an account of Bitget internals.
;;; Each POO extension adds one proposed edge; the public notice supports
;;; only the terminal unauthorized-transfer observation.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/exchange/cases/signing-trust-chain/reasoning
                 ExchangeSigningRouteCase.
                 exchange-signing-route-candidates))

(export ExchangeSigningNotice.
        ExchangeSigningRecordSubstitution.
        ExchangeSigningQueueInjection.
        ExchangeSigningSignerIngress.
        ExchangeSigningCandidateTransfer.
        ExchangeSigningQueueInterrupted.
        ExchangeSigningInterfaceSubstitution.
        ExchangeSigningApiReplay.
        ExchangeSigningQueueProducer.
        ExchangeSigningAddressMap.
        exchange-signing-attack-stages
        exchange-signing-evaluate-stage)

(def ExchangeSigningNotice.
  (.o (:: @ ExchangeSigningRouteCase.)
      observed-edges: '((transfer outflow bitget-public-notice))
      surfaces: '((backend))
      targets: '((outflow))))

(def ExchangeSigningRecordSubstitution.
  (.o (:: @ ExchangeSigningNotice.)
      proposed-edges:
      '((backend payload synthetic-record-substitution))))

(def ExchangeSigningQueueInjection.
  (.o (:: @ ExchangeSigningRecordSubstitution.)
      proposed-edges:
      '((backend payload synthetic-record-substitution)
        (payload queue synthetic-queue-injection))))

(def ExchangeSigningSignerIngress.
  (.o (:: @ ExchangeSigningQueueInjection.)
      proposed-edges:
      '((backend payload synthetic-record-substitution)
        (payload queue synthetic-queue-injection)
        (queue signer synthetic-signer-ingress))))

(def ExchangeSigningCandidateTransfer.
  (.o (:: @ ExchangeSigningSignerIngress.)
      proposed-edges:
      '((backend payload synthetic-record-substitution)
        (payload queue synthetic-queue-injection)
        (queue signer synthetic-signer-ingress)
        (signer transfer synthetic-signing-effect))))

;;; A counterfactual cut preserves every other proposed link. It does not
;;; erase the public terminal observation.
(def ExchangeSigningQueueInterrupted.
  (.o (:: @ ExchangeSigningCandidateTransfer.)
      proposed-edges:
      '((backend payload synthetic-record-substitution)
        (queue signer synthetic-signer-ingress)
        (signer transfer synthetic-signing-effect))))

;;; Separate Bybit-inspired mechanism. This uses the same authorization
;;; boundary, but is not imported as an observation about Bitget.
(def ExchangeSigningInterfaceSubstitution.
  (.o (:: @ ExchangeSigningNotice.)
      surfaces: '((interface))
      proposed-edges:
      '((interface display synthetic-interface-substitution)
        (display signer synthetic-displayed-bytes-mismatch)
        (signer transfer synthetic-signing-effect))))

(def ExchangeSigningApiReplay.
  (.o (:: @ ExchangeSigningNotice.)
      surfaces: '((internal-api))
      proposed-edges:
      '((internal-api signer synthetic-replayed-request)
        (signer transfer synthetic-signing-effect))))

(def ExchangeSigningQueueProducer.
  (.o (:: @ ExchangeSigningNotice.)
      surfaces: '((queue-producer))
      proposed-edges:
      '((queue-producer queue synthetic-message-injection)
        (queue signer synthetic-signer-ingress)
        (signer transfer synthetic-signing-effect))))

(def ExchangeSigningAddressMap.
  (.o (:: @ ExchangeSigningNotice.)
      surfaces: '((address-map))
      proposed-edges:
      '((address-map payload synthetic-destination-rewrite)
        (payload queue synthetic-queue-delivery)
        (queue signer synthetic-signer-ingress)
        (signer transfer synthetic-signing-effect))))

(def (stage stage-id case-value)
  (.o kind: 'lambda-episteme.exchange.signing-stage
      identity: stage-id
      route-case: case-value))

(def (exchange-signing-attack-stages)
  (list
   (stage 'public-notice ExchangeSigningNotice.)
   (stage 'record-substitution ExchangeSigningRecordSubstitution.)
   (stage 'queue-injection ExchangeSigningQueueInjection.)
   (stage 'signer-ingress ExchangeSigningSignerIngress.)
   (stage 'candidate-transfer ExchangeSigningCandidateTransfer.)
   (stage 'queue-interrupted ExchangeSigningQueueInterrupted.)
   (stage 'interface-substitution ExchangeSigningInterfaceSubstitution.)
   (stage 'api-replay ExchangeSigningApiReplay.)
   (stage 'queue-producer-injection ExchangeSigningQueueProducer.)
   (stage 'address-map-substitution ExchangeSigningAddressMap.)))

(def (exchange-signing-evaluate-stage stage-value)
  (exchange-signing-route-candidates (.ref stage-value 'route-case)))
