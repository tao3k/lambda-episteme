#!/usr/bin/env gxi
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; -*- Gerbil -*-
;;; Native Lambda package build. ASP projects the import closure of these
;;; public roots; std/make alone owns currentness, scheduling, and clean.

(import (only-in :std/build-script defbuild-script)
        (only-in :asp-gerbil-scheme/building-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))

(def +lambda-episteme-public-entry-modules+
  '("interface.ss"
    "modules/decision-kind/interface.ss"
    "modules/diataxis/interface.ss"
    "modules/healthcare/interface.ss"
    "modules/ontology/interface.ss"
    "user-interface/init.ss"))

(asp-gerbil-scheme-package-spec!
 (lambda-episteme-package @ asp-gerbil-scheme-library-package-prototype)
 (spec lambda-episteme-native-spec)
 (public-entry-modules +lambda-episteme-public-entry-modules+)
 (extra-spec
  '((gxc: "testing-interface")
    (gxc: "testing-observer"))))

(defbuild-script (lambda-episteme-native-spec))
