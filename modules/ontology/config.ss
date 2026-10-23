;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :yuanxu/module-system/selection/objects
                 agentic-ai-lab-user-module-selection?
                 agentic-ai-lab-user-module-selection-flags
                 agentic-ai-lab-user-module-selection-key)
        (only-in :agentic-ai-lab/modules/governance/funs
                 agentic-ai-lab-governance-contribution)
        (only-in "objects.ss"
                 OntologyProfile))

(export ontology-module ontology-config)

(def ontology-module
  (agentic-ai-lab-governance-contribution
   OntologyProfile '(ontology-governance) '()))

(def (ontology-config selection)
  (unless (and (agentic-ai-lab-user-module-selection? selection)
               (equal? (agentic-ai-lab-user-module-selection-key selection)
                       '(custom . ontology))
               (null? (agentic-ai-lab-user-module-selection-flags selection)))
    (error "invalid ontology module selection"))
  ontology-module)
