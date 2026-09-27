;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph poo-flow-graph-edge-kind
                 poo-flow-graph-edges poo-flow-graph-nodes)
        (only-in :poo-flow/modules/authorization/providers/cedar/interface
                 poo-flow-cedar-policy?)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-compose-case ontology-evaluate-case
                 ontology-evaluation-diagnostic-codes)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/vehicle/handoff
                 vehicle-tara-reference-candidate
                 vehicle-cedar-treatment-candidate)
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

   (test-case "accepted evaluation projects only a reviewable reference"
     (let* ((evaluation
             (ontology-evaluate-case
              (ontology-compose-case VehicleOtaTreatmentHandoffCase)))
            (candidate (vehicle-tara-reference-candidate evaluation))
            (tara (.ref candidate 'tara)))
       (check-equal? (.ref tara 'source) "example-tara")
       (check-equal? (.ref tara 'workProductId) "EXAMPLE-TARA-OTA-001")
       (check-equal? (.ref tara 'revision) "example-1")
       (check-equal? (.ref tara 'approvalRef) "")
       (check-equal? (.ref tara 'treatmentGoal)
                     "EXAMPLE-OTA-ROLLBACK-GOAL")
       (check-equal? (.ref candidate 'approval-reference-present?) #f)
       (check-equal? (.ref candidate 'external-approval-verified?) #f)
       (check-equal? (.ref candidate 'publication) #f)
       (check-exception
        (vehicle-cedar-treatment-candidate
         evaluation "vehicle-ota-treatment"
         "user-interface/scenarios/vehicle/cases/ota-treatment-handoff/source.org")
        true)))

   (test-case "a generated Cedar file enters the existing Provider"
     (let (path (getenv "LEAN_POO_CEDAR_FILE" #f))
       (when path
         (let* ((evaluation
                 (ontology-evaluate-case
                  (ontology-compose-case VehicleOtaTreatmentHandoffCase)))
                (candidate
                 (vehicle-cedar-treatment-candidate
                  evaluation "vehicle-ota-treatment" path))
                (policy (.ref candidate 'cedar-policy)))
           (check-equal? (poo-flow-cedar-policy? policy) #t)
           (check-equal? (.ref policy 'source)
                         (call-with-input-file path read-all-as-string))
           (check-equal? (.ref candidate 'publication) #f)
           (check-equal? (.ref candidate 'runtime-executed?) #f)))))

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
              ? values)
       (check-exception
        (vehicle-tara-reference-candidate evaluation)
        true)))))
