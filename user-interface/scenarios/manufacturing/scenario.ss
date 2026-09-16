;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyScenario)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/manufacturing/profiles/base
                 ManufacturingBaseProfile))

(export ManufacturingScenario)

(.def (ManufacturingScenario @ OntologyScenario)
  (identity 'manufacturing)
  (base-profile ManufacturingBaseProfile))
