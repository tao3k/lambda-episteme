;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export VehicleBaseProfile)

(.def (VehicleBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/vehicle/base")
  (name 'vehicle-base)
  (profile-scope 'scenario)
  (scenario 'vehicle)
  (profile-imports =>.+ (.o evidence: EvidenceProfile))
  (concept-declarations =>.+
   (.o vehicle-fleet:
       (ontology-concept 'VehicleFleet '(BaseEntity) '())
       vehicle-software-release:
       (ontology-concept 'VehicleSoftwareRelease '(BaseEntity) '())))
  (relation-declarations =>.+ (.o))
  (rule-declarations =>.+ (.o))
  (query-declarations =>.+ (.o)))
