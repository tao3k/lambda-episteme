;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test)

(export ownership-boundary-test)

(def package-root
  (if (file-exists? "gerbil.pkg")
    "."
    "packages/lambda-episteme"))

(def (package-path path)
  (string-append package-root "/" path))

(def removed-legacy-paths
  '("ontology"
    "policies"
    "prompts"
    "sources"
    "tests"
    "pyproject.toml"
    "uv.lock"
    "episteme.toml"
    "wendao-legacy.toml"
    "packages/proof"))

(def ownership-boundary-test
  (test-suite
   "Lambda Episteme ownership boundary"

   (test-case "legacy and Aitia-owned surfaces are absent"
     (for-each
      (lambda (path)
        (check-equal? (file-exists? (package-path path)) #f))
      removed-legacy-paths))))
