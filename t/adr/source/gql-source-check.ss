(import :poo-flow/src/module-system/contribution/testing)
;;; Authoring qualification uses Gerbil's parser, not a query execution engine.
(import :std/test :std/misc/ports
        (only-in :gerbil-parser/languages/gql/iso-39075-2024/parser
                 parse-gql-iso-39075-2024)
        (only-in :gerbil-parser/src/runtime/artifact
                 parse-artifact-success? parse-artifact-valid? parse-artifact-roundtrip))
(def sources '("modules/adr/expired-references.gql"))
(export gql-source-check)
(def gql-source-check
  (test-suite "GQL source authoring through gerbil-parser"
    (test-case "contributed queries preserve their complete native source"
      (for-each
       (lambda (path)
         (let* ((source (call-with-input-file path read-all-as-string))
                (artifact (parse-gql-iso-39075-2024 source)))
           (check-equal? (parse-artifact-success? artifact) #t)
           (check-equal? (parse-artifact-valid? artifact) #t)
           (check-equal? (parse-artifact-roundtrip artifact) source))) sources))
    (test-case "malformed queries are rejected"
      (check-equal? (parse-artifact-success? (parse-gql-iso-39075-2024 "MATCH ( RETURN")) #f))))
