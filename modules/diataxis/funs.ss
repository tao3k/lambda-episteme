;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/modules/governance/funs
                 poo-flow-governance-module-contribution)
        "objects.ss")
(export diataxis-contribution diataxis-module)
(def (diataxis-contribution profile)
  (poo-flow-governance-module-contribution
   profile 'diataxis '(knowledge-governance) '()))
(def diataxis-module (diataxis-contribution DiataxisProfile))
