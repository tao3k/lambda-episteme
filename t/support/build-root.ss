;;; -*- Gerbil -*-
;;; Test-only closure root.  Legacy executable exercises stay out of the
;;; production contribution build and are compiled only for qualification.

(import :poo-flow/lambda-episteme/t/governance/build-root
        :poo-flow/lambda-episteme/t/ontology/build-root)

(export contribution-test-fixtures-loaded?)
(def contribution-test-fixtures-loaded? #t)
