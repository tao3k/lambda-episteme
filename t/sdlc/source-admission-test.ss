;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :gerbil/gambit
        (only-in :clan/poo/object .cc .ref)
        (only-in :clan/testing find-test-files)
        (only-in :asp-gerbil-scheme/testing-api
                 +asp-testing-interface+
                 +testing-source-admission-profile+
                 testing-interface-add-profile
                 testing-interface-prepared-source-admission-suite)
        (only-in :std/misc/path path-enough)
        (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/test check)
        (only-in :poo-flow/src/module-system/observability/source-admission
                 poo-flow-source-admission))

(export sdlc-source-admission-test)

;;; Hold the contributor root as a value.  Never mutate cwd while another test
;;; file may be imported in the same native gxtest batch.
(def +lambda-contributor-root+
  (if (file-exists? "modules/sdlc/interface.ss")
    (current-directory)
    (path-normalize (path-expand "lambda-episteme"))))

(def +source-admission-budget-us+ 15000000)

(def (sdlc-test-entries root)
  (filter (lambda (path)
            (and (string-prefix? "t/sdlc/" path)
                 (not (equal? path "t/sdlc/source-admission-test.ss"))))
          (map (lambda (path) (path-enough path root))
               (find-test-files root))))

(def +sdlc-source-admission-interface+
  (.cc (testing-interface-add-profile
        +asp-testing-interface+
        +testing-source-admission-profile+)
       .admit-prepared-source-graph:
       (lambda (_test entries)
         (let* ((root +lambda-contributor-root+)
                (receipt (poo-flow-source-admission root entries)))
           (displayln "[poo-flow-observability] phase=source-scanned"
                      " owner=lambda-episteme module=sdlc"
                      " files=" (.ref receipt 'file-count)
                      " observations=" (.ref receipt 'observation-count)
                      " diagnostics=" (.ref receipt 'diagnostic-count)
                      " preparedGraphElapsedUs="
                      (.ref receipt 'prepared-graph-elapsed-us)
                      " policyElapsedUs="
                      (.ref receipt 'authoring-policy-elapsed-us)
                      " elapsedUs=" (.ref receipt 'elapsed-us))
           (force-output)
           (check (.ref receipt 'admitted?) => #t)
           (check (< (.ref receipt 'elapsed-us)
                     +source-admission-budget-us+)
                  => #t)
           receipt))))

(def +sdlc-prepared-source-roots+
  (sdlc-test-entries +lambda-contributor-root+))

(def sdlc-source-admission-test
  (testing-interface-prepared-source-admission-suite
   +sdlc-source-admission-interface+
   "lambda-episteme/sdlc"
   +sdlc-prepared-source-roots+))
