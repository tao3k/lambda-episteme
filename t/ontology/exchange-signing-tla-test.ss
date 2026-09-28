;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :std/test test-suite check-equal?)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :clan/poo/object .ref)
        (only-in :core/observability/testing-case poo-flow-test-case)
        (only-in :gerbil-parser/src/runtime/artifact sha256-text)
        (only-in :gerbil-parser/src/runtime/cst
                 syntax-node? syntax-node-kind)
        (only-in :poo-flow/modules/tla-plus/interface
                 poo-flow-tla-parse-source poo-flow-tla-parser-cst))

(export exchange-signing-tla-test)

(def (threat-model-path)
  (string-append
   (getenv "EXCHANGE_CASE_ROOT" ".")
   "/user-interface/scenarios/exchange/cases/signing-trust-chain/proof/tla/SigningIntentBoundary.tla"))

(def exchange-signing-tla-test
  (test-suite "Exchange signing intent threat model"
    (poo-flow-test-case "TLA+ model retains parser-owned source and syntax"
      (let* ((source
              (call-with-input-file (threat-model-path) read-all-as-string))
             (document (poo-flow-tla-parse-source source))
             (root (poo-flow-tla-parser-cst document)))
        (check-equal? (.ref document 'source-digest) (sha256-text source))
        (check-equal? (.ref document 'exact-roundtrip?) #t)
        (check-equal? (.ref document 'semantic-validation?) #f)
        (check-equal? (.ref document 'model-checking?) #f)
        (check-equal? (syntax-node? root) #t)
        (check-equal? (syntax-node-kind root) 'SourceFile)))))
