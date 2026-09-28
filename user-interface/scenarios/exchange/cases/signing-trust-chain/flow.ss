;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The current public binding is `user-composition`, followed by a native
;;; `(compose profiles ...)` expression with module-local aliases. Attack
;;; variants inherit their POO Profile from flow-profiles.ss.
(import (only-in :poo-flow/src/module-system/profile-composition/profile-bundle
                 profiles compose)
        :poo-flow/src/module-system/profile-composition/binding-syntax
        (only-in :poo-flow/modules/funflow/profile-library
                 FunflowProfileModule)
        (only-in "flow-profiles.ss" ExchangeSigningAttackModule))

(export exchange-signing-record-mutation
        exchange-signing-api-replay
        exchange-signing-queue-injection
        exchange-signing-address-map-substitution
        exchange-signing-interface-substitution
        exchange-signing-backend-admin-change)

(user-composition exchange-signing-record-mutation
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack record-mutation)))

(user-composition exchange-signing-api-replay
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack api-replay)))

(user-composition exchange-signing-queue-injection
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack queue-injection)))

(user-composition exchange-signing-address-map-substitution
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack address-map-substitution)))

(user-composition exchange-signing-interface-substitution
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack interface-substitution)))

(user-composition exchange-signing-backend-admin-change
  (compose profiles
    (use-module FunflowProfileModule as flow python-anyio)
    (use-module ExchangeSigningAttackModule as attack backend-admin-change)))
