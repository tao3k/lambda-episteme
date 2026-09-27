;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph poo-flow-graph-edge-kind
                 poo-flow-graph-edges poo-flow-graph-nodes)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-compose-case ontology-evaluate-case
                 ontology-evaluation-diagnostic-codes)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/vehicle/cases/ota-treatment-handoff/case
                 VehicleOtaTreatmentHandoffCase))

(export vehicle-ota-treatment-handoff-test)

(def vehicle-ota-treatment-handoff-test
  (test-suite
   "Vehicle OTA treatment handoff"

   (test-case "a selected assessment, treatment and release compose"
     (let* ((case VehicleOtaTreatmentHandoffCase)
            (composition (ontology-compose-case case))
            (evaluation (ontology-evaluate-case composition)))
       (check-equal? (.ref composition 'accepted?) #t)
       (check-equal? (.ref evaluation 'accepted?) #t)
       (check-equal? (.ref composition 'runtime-executed?) #f)
       (check-equal? (.ref (.ref case 'assessment-reference)
                           'approval-reference) #f)))

   (test-case "a treatment goal without policy is rejected"
     (let* ((original (.ref VehicleOtaTreatmentHandoffCase 'graph))
            (missing-policy
             (poo-flow-graph
              'vehicle-ota-missing-policy
              (poo-flow-graph-nodes original)
              (filter
               (lambda (edge)
                 (not (eq? (poo-flow-graph-edge-kind edge)
                           'realizedByPolicy)))
               (poo-flow-graph-edges original))))
            (broken-case
             (.o (:: @ VehicleOtaTreatmentHandoffCase)
                 graph: missing-policy))
            (evaluation
             (ontology-evaluate-case (ontology-compose-case broken-case))))
       (check-equal? (.ref evaluation 'accepted?) #f)
       (check (memq 'required-relation-missing
                    (ontology-evaluation-diagnostic-codes evaluation))
              ? values)))))
