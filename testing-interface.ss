;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Declarative Lambda test Profiles shared by the package entrypoint and the
;;; optional observer. Gerbil test remains the only execution framework.

(import (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-process-isolation-profile+
                 +testing-serial-resource-profile+
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

(def +lambda-episteme-testing-interface+
  (poo-flow-testing-observability-extension
   (testing-interface-map-profile
    (testing-interface-map-profile
     +asp-testing-interface+
     +lambda-episteme-atomic-test-selector+
     +testing-process-isolation-profile+)
    +lambda-episteme-source-admission-selector+
    +testing-serial-resource-profile+)
   (make-poo-flow-testing-observability-profile
    'lambda-episteme/testing 5)))
