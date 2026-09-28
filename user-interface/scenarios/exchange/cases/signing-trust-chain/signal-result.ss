;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Binds a candidate's projected rows to its digest and the exact Query.
;;; A Provider candidate is still an assertion by its producer: this does
;;; not authenticate its provenance root or execute GQL.
(import (only-in :clan/poo/object .o .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/encoding/hex hex-encode)
        (only-in :poo-flow/modules/query/objects poo-flow-query-element-space)
        (only-in :poo-flow/modules/query/funs poo-flow-query-admit)
        (only-in :poo-flow/modules/query/contracts
                 poo-flow-query-bind-execution-receipt)
        (only-in :poo-flow/modules/query/providers/mrr/interface
                 MrrGqlQueryProvider)
        (only-in "query.ss" ExchangeSigningSignalQuery))

(export exchange-signing-signal-result-digest
        exchange-signing-bind-signal-result)

(def (exchange-signing-signal-result-digest rows)
  (string-append
   "sha256:"
   (hex-encode
    (sha256
     (string->utf8
      (call-with-output-string
       (lambda (port)
         (write 'exchange-signing-signal-result-v1 port)
         (write rows port))))))))

(def (signal-row? row selected)
  (and (list? row) (= (length row) 3)
       (symbol? (car row)) (memq (car row) selected)
       (symbol? (cadr row))
       (memq (caddr row) '(admitted provisional))))

(def (unique-signals? rows)
  (let loop ((pending rows) (seen '()))
    (or (null? pending)
        (and (not (memq (caar pending) seen))
             (loop (cdr pending) (cons (caar pending) seen))))))

(def (exchange-signing-bind-signal-result candidate row-values)
  (let* ((query ExchangeSigningSignalQuery)
         (selected (.ref query 'selected-element-identities))
         (space
          (poo-flow-query-element-space
           (.ref query 'element-space-identity)
           (.ref query 'semantic-revision) selected #t))
         (admission (poo-flow-query-admit query space))
         (receipt
          (poo-flow-query-bind-execution-receipt
           MrrGqlQueryProvider query admission candidate))
         (row-shape-ok?
          (and (list? row-values)
               (<= (length row-values) (.ref query 'result-bound))
               (andmap (lambda (row) (signal-row? row selected)) row-values)
               (unique-signals? row-values)))
         (bound?
          (and (.ref receipt 'admitted?) row-shape-ok?
               (= (length row-values) (.ref receipt 'result-count))
               (equal? (exchange-signing-signal-result-digest row-values)
                       (.ref receipt 'result-digest)))))
    (.o kind: 'lambda-episteme.exchange.signing-signal-result
        query-receipt: receipt
        rows: (if bound? row-values '())
        integrity-bound?: bound?
        provenance-verified?: #f
        gql-executed-by-case?: #f
        action-authority?: #f)))
