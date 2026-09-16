#!/usr/bin/env gxi
(import (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-process-isolation-profile+
                 +testing-serial-resource-profile+
                 testing-interface-map-profile
                 testing-test-selector
                 init-profiled-test-environment!)
        (only-in :poo-flow/src/module-system/observability/testing-extension
                 poo-flow-testing-observability-extension))

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
    +testing-serial-resource-profile+)))

(init-profiled-test-environment! +lambda-episteme-testing-interface+)
