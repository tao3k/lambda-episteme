;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot?)
        (only-in :agentic-ai-lab/modules/governance/types
                 agentic-ai-lab-governance-profile?))
(export diataxis-profile?)
(def (diataxis-profile? value)
  (and (agentic-ai-lab-governance-profile? value)
       (.slot? value 'module-family)
       (eq? (.ref value 'module-family) 'diataxis)))
