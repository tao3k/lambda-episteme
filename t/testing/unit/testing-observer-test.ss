;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :poo-flow/lambda-episteme/testing-observer
                 lambda-episteme-selected-test-files))

(export testing-observer-test)

(def +package-local?+
  (file-exists? "t/healthcare/standards/migration-test.ss"))

(def +healthcare-test-root+
  (if +package-local?+
    "t/healthcare"
    "packages/lambda-episteme/t/healthcare"))

(def +migration-test+
  (if +package-local?+
    "t/healthcare/standards/migration-test.ss"
    "packages/lambda-episteme/t/healthcare/standards/migration-test.ss"))

(def +healthcare-test-files+
  (if +package-local?+
    '("./t/healthcare/standards/fhir-test.ss"
      "./t/healthcare/standards/migration-test.ss")
    '("packages/lambda-episteme/t/healthcare/standards/fhir-test.ss"
      "packages/lambda-episteme/t/healthcare/standards/migration-test.ss")))

(def testing-observer-test
  (test-suite
   "Lambda Episteme profiled test selection"

   (test-case "an exact source test remains one native batch input"
     (check-equal?
      (lambda-episteme-selected-test-files +migration-test+)
      (list +migration-test+)))

   (test-case "a module directory is discovered through clan/testing"
     (check-equal?
      (lambda-episteme-selected-test-files +healthcare-test-root+)
      +healthcare-test-files+))

   (test-case "an empty module selection fails closed"
     (check-exception
      (lambda-episteme-selected-test-files
       (if +package-local?+
         "t/not-present"
         "packages/lambda-episteme/t/not-present"))
      true))))
