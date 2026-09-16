;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile))

(export ManufacturingBaseProfile)

(.def (ManufacturingBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/manufacturing/base")
  (name 'manufacturing-base)
  (profile-scope 'scenario)
  (scenario 'manufacturing)
  (.import (.o evidence: EvidenceProfile))
  (.add-concept
   (.o machine: (ontology-concept 'Machine '(BaseEntity) '())
       sensor: (ontology-concept 'Sensor '(BaseEntity) '())
       work-order:
       (ontology-concept 'WorkOrder '(Action) '(execution-context-required))
       part: (ontology-concept 'Part '(BaseEntity) '())
       quality-inspection:
       (ontology-concept 'QualityInspection '(Action) '(evidence-required))))
  (.add-relation
   (.o monitored-by: (ontology-relation 'monitoredBy 'Machine 'Sensor '())
       executes-work-order:
       (ontology-relation 'executesWorkOrder 'Machine 'WorkOrder '(required))
       consumes-part: (ontology-relation 'consumesPart 'WorkOrder 'Part '())))
  (policies (.o work-order-context: 'required
                quality-evidence: 'source-bound))
  (.add-rule
   (.o work-order-machine:
       (ontology-required-relation-rule
        'work-order-must-link-machine 'WorkOrder 'executesWorkOrder 'target)
       work-order-part:
       (ontology-required-relation-rule
        'work-order-must-consume-part 'WorkOrder 'consumesPart 'source)))
  (.add-query (.o)))
