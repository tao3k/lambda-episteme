;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-user-module-selection?
                 poo-flow-user-module-selection-flags
                 poo-flow-user-module-selection-key)
        (only-in :poo-flow/lambda-episteme/governance/objects
                 governance-module)
        (only-in :poo-flow/lambda-episteme/modules/ontology/objects
                 OntologyProfile))

(export ontology-module ontology-config)

(def ontology-module
  (governance-module OntologyProfile))

(def (ontology-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection)
                       '(custom . ontology))
               (null? (poo-flow-user-module-selection-flags selection)))
    (error "invalid ontology module selection"))
  ontology-module)
