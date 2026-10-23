;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def)
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyScenario)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export HealthcareScenario)

(.def (HealthcareScenario @ OntologyScenario)
  (identity 'healthcare)
  (base-profile HealthcareBaseProfile))
