;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .all-slots .ref)
        (only-in :poo-flow/src/modules/standards/interface
                 poo-flow-standard-edition-ref?)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/regions/australia
                 AustraliaHealthcareRegionProfile))

(export standards-australia-profile-test)

(def standards-australia-profile-test
  (test-suite "Lambda Australia Healthcare Standard bindings"
    (test-case "Profile selects exact FHIR and Australian editions"
      (let (requirements (.ref AustraliaHealthcareRegionProfile
                                'standard-requirements))
        (check-equal? (map (lambda (edition) (.ref edition 'identity))
                           requirements)
                      '("hl7.fhir.r4.core@4.0.1"
                        "hl7.fhir.au.base@5.0.0"
                        "hl7.fhir.au.core@1.0.0"))
        (check-equal? (every poo-flow-standard-edition-ref? requirements) #t)))
    (test-case "domain identity maps without renaming Lambda ontology"
      (let (mapping
            (.ref (.ref AustraliaHealthcareRegionProfile 'standard-mappings)
                  'medication-order))
        (check-equal? (.ref mapping 'domain-identity)
                      "lambda-episteme/healthcare/medication-order")
        (check-equal? (.ref mapping 'standard-profile)
                      "http://hl7.org/fhir/StructureDefinition/MedicationRequest")))
    (test-case "ordinary Region mapping does not duplicate Migration ownership"
      (check-equal?
       (.all-slots (.ref AustraliaHealthcareRegionProfile 'standard-mappings))
       '(medication-order)))))
