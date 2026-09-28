;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Attack-specific Profile objects and their semantic Module. The common
;;; Funflow step topology is inherited; each attack specializes only its
;;; identity and temporal model selection.
(import (only-in :clan/poo/object .o)
        (only-in :core/module-schema/relations poo-flow-semantic-identity)
        (only-in :poo-flow/src/module-system/semantic-module/objects
                 poo-flow-semantic-module)
        (only-in :poo-flow/src/module-system/profile-composition/profile-bundle
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
      runtime-executed?: #f
      stages:
      (.o replay:
          (.o steps:
              (.o gql-selection: (.o contract: 'source-labelled-signal-query)
                  ascent-ranking: (.o contract: 'conditional-family-fit)
                  tla-threat-replay: (.o contract: 'bounded-temporal-check)
                  lean-cedar-replay: (.o policy-root: 'Integrated)
                  attack-surface-comparison:
                  (.o contract: 'candidate-support-and-challenge))
              edges:
              (.o selection-ranking: '(gql-selection ascent-ranking)
                  ranking-temporal: '(ascent-ranking tla-threat-replay)
                  temporal-authorization:
                  '(tla-threat-replay lean-cedar-replay)
                  authorization-comparison:
                  '(lean-cedar-replay attack-surface-comparison))))))

(def ExchangeSigningRecordMutationProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'record-mutation name: 'record-mutation
      route-case: ExchangeSigningCandidateTransfer.
      tla-config: "DirectAttack.cfg"))

(def ExchangeSigningApiReplayProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'api-replay name: 'api-replay
      route-case: ExchangeSigningApiReplay.
      tla-config: "DirectAttack.cfg"))

(def ExchangeSigningQueueInjectionProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'queue-injection name: 'queue-injection
      route-case: ExchangeSigningQueueProducer.
      tla-config: "DirectAttack.cfg"))

(def ExchangeSigningAddressMapProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'address-map-substitution name: 'address-map-substitution
      route-case: ExchangeSigningAddressMap.
      tla-config: "DirectAttack.cfg"))

(def ExchangeSigningInterfaceProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'interface-substitution name: 'interface-substitution
      route-case: ExchangeSigningInterfaceSubstitution.
      tla-config: "InterfaceAttack.cfg"))

(def ExchangeSigningBackendAdminProfile.
  (.o (:: @ ExchangeSigningAttackProfile.)
      identity: 'backend-admin-change name: 'backend-admin-change
      route-case: ExchangeSigningBackendAdmin.
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
