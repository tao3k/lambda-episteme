;;; Synthetic complete inventories shared by module-owned tests only.
(import (only-in :clan/poo/object .ref)
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-review
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-structured
        (only-in :std/srfi/1 delete-duplicates append-map))
(def (test-inventories project class-value digest-value)
  (let* ((rules (nasa-trace-rules class-value))
         (categories (delete-duplicates
                      (append-map (lambda (r) (list (.ref r 'source-category) (.ref r 'target-category))) rules)))
         (nodes (map (lambda (kind) (sdlc-trace-node (symbol->string kind) kind project)) categories))
         (edges (map (lambda (r) (sdlc-trace-edge (.ref r 'identity) (.ref r 'identity)
                                                (symbol->string (.ref r 'source-category))
                                                (symbol->string (.ref r 'target-category)) project)) rules)))
    (list (nasa-safety-inventory "synthetic-safety" project digest-value
                               (list (nasa-safety-component "controller" project #t 100 15)))
          (nasa-trace-inventory "synthetic-trace" project digest-value nodes edges))))
