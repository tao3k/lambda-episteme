;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; AOT control-plane wrapper around Gerbil's native test command. ASP still
;;; projects POO Profiles and gxtest owns loading and executing every suite.

(import (only-in :std/srfi/1 filter)
        (only-in :std/srfi/13 string-contains string-prefix? string-suffix?)
        (only-in :asp-gerbil-scheme/testing-api
                 testing-interface-run-test-files!)
        (only-in :asp-gerbil-scheme/testing-runner-api
                 testing-interface-test-files)
        (only-in ./testing-interface +lambda-episteme-testing-interface+))

(export run-observed-test
        lambda-episteme-selected-test-files)

(def (emit phase test-path)
  (display "[poo-flow-testing] phase=")
  (display phase)
  (display " test=")
  (display test-path)
  (newline)
  (force-output))

(def (emit-selection test-path file-count)
  (display "[poo-flow-testing] phase=selection-complete test=")
  (display test-path)
  (display " fileCount=")
  (display file-count)
  (newline)
  (force-output))

(def (lambda-episteme-selected-test-files test-path)
  (let (test-files
        (if (and (string-suffix? ".ss" test-path)
                 (file-exists? test-path))
          (list test-path)
          (let* ((package-local?
                  (or (equal? test-path "t")
                      (string-prefix? "t/" test-path)))
                 (test-boundary
                  (and (not package-local?)
                       (string-contains test-path "/t/"))))
            (unless (or package-local? test-boundary)
              (error "Lambda Episteme test directory is outside a package t/ tree"
                     test-path))
            (let* ((package-root
                    (if package-local?
                      "."
                      (substring test-path 0 test-boundary)))
                   (directory-prefix
                    (string-append
                     (if package-local? "./" "")
                     test-path
                     (if (string-suffix? "/" test-path) "" "/"))))
              (filter
               (lambda (path) (string-prefix? directory-prefix path))
               (testing-interface-test-files
                +lambda-episteme-testing-interface+
                test-path
                pkgdir: package-root))))))
    (when (null? test-files)
      (error "no Lambda Episteme test files selected" test-path))
    test-files))

(def (run-observed-test test-path)
  (emit 'native-test-process-start test-path)
  (let (test-files (lambda-episteme-selected-test-files test-path))
    (emit-selection test-path (length test-files))
    (testing-interface-run-test-files!
     +lambda-episteme-testing-interface+
     test-files))
  (emit 'native-test-process-complete test-path))
