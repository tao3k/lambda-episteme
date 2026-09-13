#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import (only-in :std/build-script defbuild-script)
        (only-in :std/source this-source-file)
        (only-in :asp-gerbil-scheme/build-api
                 asp-gerbil-scheme-package-spec!
                 asp-gerbil-scheme-library-package-prototype))
(asp-gerbil-scheme-package-spec!
 (lambda-episteme-package @ asp-gerbil-scheme-library-package-prototype)
 (spec spec)
 (public-entry-modules '("interface.ss" "user-interface/interface.ss")))
(defbuild-script (spec))
