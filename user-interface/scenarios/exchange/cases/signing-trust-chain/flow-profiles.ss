;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Attack-specific Profile objects and their semantic Module. The common
;;; Funflow step topology is inherited; each attack specializes only its
;;; identity and temporal model selection.
(import (only-in :clan/poo/object .o)
        (only-in :core/module-system/schema/relations poo-flow-semantic-identity)
        (only-in :poo-flow/src/authoring/semantic-module
                 poo-flow-semantic-module)
        (only-in :core/profile-composition/profile-bundle
                 poo-flow-module-profiles poo-flow-profile-export)
        (only-in "simulation.ss"
                 ExchangeSigningCandidateTransfer.
                 ExchangeSigningApiReplay.
                 ExchangeSigningQueueProducer.
                 ExchangeSigningAddressMap.
                 ExchangeSigningInterfaceSubstitution.
                 ExchangeSigningBackendAdmin.))

(export ExchangeSigningRecordMutationProfile.
        ExchangeSigningApiReplayProfile.
        ExchangeSigningQueueInjectionProfile.
        ExchangeSigningAddressMapProfile.
        ExchangeSigningInterfaceProfile.
        ExchangeSigningBackendAdminProfile.
        ExchangeSigningAttackModule)

(def ExchangeSigningAttackProfile.
  (.o identity: 'exchange-signing-attack
      name: 'exchange-signing-attack
      module: 'exchange-signing
      tla-config: #f
      route-case: #f
      observation-needs: '()
      runtime-executed?: #f
      stages:
      (.o replay:
          (.o steps:
              (.o causal-trajectory: (.o contract: 'source-labelled-causal-path)
                  tla-threat-replay: (.o contract: 'route-specific-temporal-check)
                  gql-selection: (.o contract: 'scheme-gql-signal-selection)
                  ascent-ranking: (.o contract: 'qualified-conditional-fit)
                  lean-cedar-replay: (.o policy-root: 'Integrated)
                  attack-surface-comparison:
                  (.o contract: 'candidate-support-and-challenge))
              edges:
              (.o causal-temporal: '(causal-trajectory tla-threat-replay)
                  temporal-selection: '(tla-threat-replay gql-selection)
                  selection-ranking: '(gql-selection ascent-ranking)
                  ranking-authorization:
                  '(ascent-ranking lean-cedar-replay)
                  authorization-comparison:
                  '(lean-cedar-replay attack-surface-comparison))))))

(def ExchangeSigningRecordMutationProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'record-mutation name: 'record-mutation
      route-case: ExchangeSigningCandidateTransfer.
      observation-needs:
      '(authenticated-withdrawal-intent signer-decoded-transaction
        record-write-audit)
      tla-config: "RecordAttack.cfg"))

(def ExchangeSigningApiReplayProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'api-replay name: 'api-replay
      route-case: ExchangeSigningApiReplay.
      observation-needs:
      '(one-use-request-ledger signer-request-authentication
        signer-decoded-transaction)
      tla-config: "ApiAttack.cfg"))

(def ExchangeSigningQueueInjectionProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'queue-injection name: 'queue-injection
      route-case: ExchangeSigningQueueProducer.
      observation-needs:
      '(queue-producer-attestation signer-ingress-receipt
        signer-decoded-transaction)
      tla-config: "QueueAttack.cfg"))

(def ExchangeSigningAddressMapProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'address-map-substitution name: 'address-map-substitution
      route-case: ExchangeSigningAddressMap.
      observation-needs:
      '(independent-destination-commitment address-map-version
        signer-decoded-transaction)
      tla-config: "AddressMapAttack.cfg"))

(def ExchangeSigningInterfaceProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'interface-substitution name: 'interface-substitution
      route-case: ExchangeSigningInterfaceSubstitution.
      observation-needs:
      '(trusted-rendered-bytes signed-admin-operation
        linked-control-change)
      tla-config: "InterfaceAttack.cfg"))

(def ExchangeSigningBackendAdminProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'backend-admin-change name: 'backend-admin-change
      route-case: ExchangeSigningBackendAdmin.
      observation-needs:
      '(signed-admin-operation linked-control-change
        controlled-wallet-drain)
      tla-config: "AdminAttack.cfg"))

(def ExchangeSigningAttackModule
  (poo-flow-semantic-module
   (poo-flow-semantic-identity 'lambda-episteme 'exchange-signing-attack)
   profiles:
   (poo-flow-module-profiles
    (poo-flow-profile-export 'record-mutation
                             ExchangeSigningRecordMutationProfile.)
    (poo-flow-profile-export 'api-replay
                             ExchangeSigningApiReplayProfile.)
    (poo-flow-profile-export 'queue-injection
                             ExchangeSigningQueueInjectionProfile.)
    (poo-flow-profile-export 'address-map-substitution
                             ExchangeSigningAddressMapProfile.)
    (poo-flow-profile-export 'interface-substitution
                             ExchangeSigningInterfaceProfile.)
    (poo-flow-profile-export 'backend-admin-change
                             ExchangeSigningBackendAdminProfile.))))
