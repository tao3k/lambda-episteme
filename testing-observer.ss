;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; AOT control-plane wrapper around Gerbil's native test command. ASP still
;;; projects POO Profiles and gxtest owns loading and executing every suite.

(import :std/list/list
        (only-in :gerbil/core string-contains string-prefix? string-suffix?)
        (only-in :std/string/misc string-trim-prefix)
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
  (let* ((normalized-test-path (string-trim-prefix "./" test-path))
         (test-files
        (if (and (string-suffix? ".ss" normalized-test-path)
                 (file-exists? normalized-test-path))
          (list normalized-test-path)
          (let* ((package-local?
                  (or (equal? normalized-test-path "t")
                      (string-prefix? "t/" normalized-test-path)))
                 (test-boundary
                  (and (not package-local?)
                       (string-contains normalized-test-path "/t/"))))
            (unless (or package-local? (fixnum? test-boundary))
              (error "Lambda Episteme test directory is outside a package t/ tree"
                     normalized-test-path))
            (let* ((package-root
                    (if package-local?
                      "."
                      (if (fixnum? test-boundary)
                        (substring normalized-test-path 0 test-boundary)
                        (error "Lambda Episteme test boundary is not an index"
                               normalized-test-path))))
                   (directory-prefix
                    (string-append
                     (if package-local? "./" "")
                     normalized-test-path
                     (if (string-suffix? "/" normalized-test-path) "" "/"))))
              (filter
               (lambda (path) (string-prefix? directory-prefix path))
               (testing-interface-test-files
                +lambda-episteme-testing-interface+
                normalized-test-path
                pkgdir: package-root)))))))
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
