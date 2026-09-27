;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .o .ref)
        (only-in :gerbil/core hash-get)
        (only-in :std/encoding/json string->json make-JSONReadOptions)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph poo-flow-graph-edge-kind
                 poo-flow-graph-edges poo-flow-graph-nodes)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-compose-case ontology-evaluate-case
                 ontology-evaluation-diagnostic-codes)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/vehicle/handoff
                 vehicle-tara-reference-candidate vehicle-tara-reference-json)
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
       (let (json
             (string->json
              (vehicle-tara-reference-json candidate)
              (make-JSONReadOptions key-as-symbol: #f
                                    array-as-vector: #f
                                    object-as-hash: #t)))
         (check-equal? (hash-get json "source") "example-tara")
         (check-equal? (hash-get json "workProductId")
                       "EXAMPLE-TARA-OTA-001")
         (check-equal? (hash-get json "revision") "example-1")
         (check-equal? (hash-get json "approvalRef") "")
         (check-equal? (hash-get json "treatmentGoal")
                       "EXAMPLE-OTA-ROLLBACK-GOAL"))))

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
