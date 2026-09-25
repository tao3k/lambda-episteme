;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base/objects
                 HealthcareBaseProfilePrototype))

(export HealthcareBaseProfile)

;; Ordinary Profile declaration: identity and domain choices stay visible;
;; maintained concept, relation, source and rule defaults remain inheritable.
(.def (HealthcareBaseProfile @ HealthcareBaseProfilePrototype)
  (identity "lambda-episteme/ontology/healthcare/base")
  (name 'healthcare-base)
  (policies (.o clinical-status: 'source-bound
                incomplete-scope: 'unknown)))
