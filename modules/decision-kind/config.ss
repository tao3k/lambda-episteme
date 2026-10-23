;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :agentic-ai-lab/modules/governance/funs
                 agentic-ai-lab-governance-module-config)
        "funs.ss")
(export decision-kind-config)
(def (decision-kind-config selection)
  (agentic-ai-lab-governance-module-config
   selection 'decision-kind decision-kind-module))
