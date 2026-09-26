;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-user-module-selection?
                 poo-flow-user-module-selection-flags
                 poo-flow-user-module-selection-key)
        (only-in :poo-flow/modules/governance/funs
                 poo-flow-governance-contribution)
        (only-in "objects.ss"
                 OntologyProfile))

(export ontology-module ontology-config)

(def ontology-module
  (poo-flow-governance-contribution
   OntologyProfile '(ontology-governance) '()))

(def (ontology-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection)
                       '(custom . ontology))
               (null? (poo-flow-user-module-selection-flags selection)))
    (error "invalid ontology module selection"))
  ontology-module)
