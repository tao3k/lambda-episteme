#!/usr/bin/env gxi
(import (only-in :asp-gerbil-scheme/testing-runner-api
                 init-profiled-test-environment!)
        (only-in "testing-interface.ss"
                 +lambda-episteme-testing-interface+))

(init-profiled-test-environment! +lambda-episteme-testing-interface+)
