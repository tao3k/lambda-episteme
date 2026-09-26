;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/modules/governance/funs
                 poo-flow-governance-module-config)
        "funs.ss")
(export diataxis-config)
(def (diataxis-config selection)
  (poo-flow-governance-module-config
   selection 'diataxis diataxis-module))
