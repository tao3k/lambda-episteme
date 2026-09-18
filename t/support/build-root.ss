;;; -*- Gerbil -*-
;;; Test-only closure root. Qualification-only fixtures stay out of the
;;; production contribution build.

(import :poo-flow/lambda-episteme/t/governance/build-root)

(export contribution-test-fixtures-loaded?)
(def contribution-test-fixtures-loaded? #t)
