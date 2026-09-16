;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :gerbil/gambit
        (only-in :clan/poo/object .cc .o .ref)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-source-admission-profile+
                 testing-interface-add-profile)
        (only-in :asp-gerbil-scheme/testing-source-admission-api
                 testing-interface-prepared-source-admission-suite)
        (only-in :std/test check)
        (only-in :poo-flow/src/module-system/observability/source-admission
                 poo-flow-source-admission-observability-profile-prototype
                 poo-flow-observe-source-admission!
                 poo-flow-source-admission)
        "./build-root")

(export sdlc-source-admission-test)

;;; Hold the contributor root as a value.  Never mutate cwd while another test
;;; file may be imported in the same native gxtest batch.
(def +lambda-contributor-root+
  (if (file-exists? "modules/sdlc/interface.ss")
    (current-directory)
    (path-normalize (path-expand "lambda-episteme"))))

(def +source-admission-budget-us+ 15000000)
(def +prepared-graph-budget-us+ 100000)

(def +sdlc-source-admission-observability+
  (.o (:: @ poo-flow-source-admission-observability-profile-prototype)
      (identity 'lambda-episteme/sdlc-source-admission)
      (owner 'lambda-episteme)
      (module 'sdlc)
      (emit-summary? #t)
      (emit-diagnostics? #t)))

(def +sdlc-source-admission-interface+
  (.cc (testing-interface-add-profile
        +asp-testing-interface+
        +testing-source-admission-profile+)
       .admit-prepared-source-graph:
       (lambda (_test entries)
         (let* ((root +lambda-contributor-root+)
                (receipt (poo-flow-observe-source-admission!
                          +sdlc-source-admission-observability+
                          (poo-flow-source-admission root entries))))
           (check (.ref receipt 'admitted?) => #t)
           ;; The ASP source-admission slot is specifically a prepared-graph
           ;; contract.  A cold import-closure replay can satisfy the broader
           ;; policy budget while violating that lifecycle boundary, so guard
           ;; the graph-reuse phase independently.
           (check (< (.ref receipt 'prepared-graph-elapsed-us)
                     +prepared-graph-budget-us+)
                  => #t)
           (check (< (.ref receipt 'elapsed-us)
                     +source-admission-budget-us+)
                  => #t)
           receipt))))

(def +sdlc-prepared-source-roots+
  ;; The native module graph is declared once by the module's test build root.
  ;; Importing that root above makes it resident before this suite runs; no
  ;; filesystem scan, parallel catalog or cold closure replay is allowed here.
  '("t/sdlc/build-root.ss"))

(def sdlc-source-admission-test
  (testing-interface-prepared-source-admission-suite
   +sdlc-source-admission-interface+
   "lambda-episteme/sdlc"
   +sdlc-prepared-source-roots+))
