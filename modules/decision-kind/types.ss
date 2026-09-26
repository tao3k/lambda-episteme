;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot?)
        (only-in :poo-flow/modules/governance/types
                 poo-flow-governance-profile?))
(export decision-kind-profile?)
(def (decision-kind-profile? value)
  (and (poo-flow-governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'decision-kind)))
