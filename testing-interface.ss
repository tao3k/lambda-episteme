;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Declarative Lambda test Profiles shared by the package entrypoint and the
;;; optional observer. Gerbil test remains the only execution framework.

(import (only-in :clan/poo/object .cc)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-discovery-profile+
                 +testing-memory-profile+
                 +testing-process-isolation-profile+
                 +testing-serial-resource-profile+
                 testing-interface-add-profile
                 testing-interface-map-profile
                 testing-test-selector)
        (only-in :poo-flow/src/module-system/observability/testing-extension
                 make-poo-flow-testing-observability-profile
                 poo-flow-testing-observability-extension))

(export +lambda-episteme-testing-interface+)

(def +lambda-episteme-atomic-test-selector+
  (testing-test-selector 'contains "-test.ss"))

(def +lambda-episteme-source-admission-selector+
  (testing-test-selector 'contains "source-admission-test.ss"))

(def +lambda-episteme-healthcare-assurance-selector+
  (testing-test-selector
   'contains "qualification/healthcare-case-assurance.ss"))

(def +lambda-episteme-healthcare-qualification-selector+
  (testing-test-selector 'contains "t/qualification/healthcare-"))

(def +lambda-episteme-healthcare-standard-migration-selector+
  (testing-test-selector
   'contains "healthcare-standard-migration-case-test.ss"))

(def +lambda-episteme-personal-care-selector+
  (testing-test-selector 'contains "personal-care-coordination-test.ss"))

(def +lambda-episteme-user-composition-selector+
  (testing-test-selector 'contains "t/user-interface/unit/config-test.ss"))

(def +lambda-episteme-performance-selector+
  (testing-test-selector
   'contains "t/ontology/performance/required-relation-index-test.ss"))

;;; Cross-engine qualification and the selected large static POO compositions
;;; exceed the ordinary 1 GiB cold-compile heap. The larger heap is attached to
;;; exact test selectors, never widened into the default Testing Profile.
(def +lambda-episteme-2048-mib-memory-profile+
  (.cc +testing-memory-profile+ maxHeapMiB: 2048))

(def +lambda-episteme-testing-interface+
  (poo-flow-testing-observability-extension
   (testing-interface-map-profile
    (testing-interface-map-profile
     (testing-interface-map-profile
      (testing-interface-map-profile
       (testing-interface-map-profile
        (testing-interface-map-profile
         (testing-interface-map-profile
          (testing-interface-map-profile
           (testing-interface-add-profile
            +asp-testing-interface+
            (.cc +testing-discovery-profile+
                 ignoreDirectories:
                 '("t/qualification/healthcare-hl7v2-migration"
                   "t/qualification/healthcare-fhirpath-syntax"
                   "t/qualification/healthcare-fhir-reference-validator")))
           +lambda-episteme-healthcare-qualification-selector+
           +lambda-episteme-2048-mib-memory-profile+)
          +lambda-episteme-healthcare-assurance-selector+
          +lambda-episteme-2048-mib-memory-profile+)
         +lambda-episteme-healthcare-standard-migration-selector+
         +lambda-episteme-2048-mib-memory-profile+)
        +lambda-episteme-personal-care-selector+
        +lambda-episteme-2048-mib-memory-profile+)
       +lambda-episteme-user-composition-selector+
       +lambda-episteme-2048-mib-memory-profile+)
      +lambda-episteme-atomic-test-selector+
      +testing-process-isolation-profile+)
     +lambda-episteme-source-admission-selector+
     +testing-serial-resource-profile+)
    +lambda-episteme-performance-selector+
    +testing-serial-resource-profile+)
   (make-poo-flow-testing-observability-profile
    'lambda-episteme/testing 5)))
