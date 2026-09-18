#!/usr/bin/env gxi
(import :gerbil/gambit)

;;; This file intentionally stays a minimal native Gerbil bootstrap.  Static
;;; imports are loaded only after the first observable receipt, so a cold
;;; compiler cannot leave the developer with an unexplained silent interval.
(displayln "[asp-testing] phase=bootstrap-start")
(force-output)

(load "./profiled-unit-tests.ss")
