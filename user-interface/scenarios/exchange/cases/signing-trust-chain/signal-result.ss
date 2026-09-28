;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Source-labelled POO nodes feed the bounded Scheme GQL selector. A local
;;; query result is a conditional model observation, never source admission.
(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/utilities/functional
                 poo-flow-all? poo-flow-map poo-flow-stable-duplicates)
        (only-in :poo-flow/modules/query/scheme-select
                 poo-flow-query-select-scheme-nodes)
        (only-in "query.ss" ExchangeSigningSignalQuery))

(export exchange-signing-signal-nodes
        exchange-signing-run-signal-query)

(def (signal-row? row selected)
  (and (list? row) (= (length row) 3)
       (symbol? (car row)) (memq (car row) selected)
       (symbol? (cadr row))
       (memq (caddr row) '(admitted provisional reported))))

(def (exchange-signing-signal-nodes source-rows)
  (let ((selected
         (.ref ExchangeSigningSignalQuery 'selected-element-identities)))
    (unless (and (list? source-rows)
                 (<= (length source-rows) 64)
                 (poo-flow-all?
                  (lambda (row) (signal-row? row selected))
                  source-rows)
                 (null? (poo-flow-stable-duplicates
                         (poo-flow-map car source-rows))))
      (error "invalid source-labelled signing signal rows"))
    (poo-flow-map
     (lambda (row)
       (.o label: 'SigningSignal
           identity: (car row)
           evidenceSource: (cadr row)
           admissionStatus: (caddr row)))
     source-rows)))

(def (exchange-signing-run-signal-query nodes)
  (let* ((result
          (poo-flow-query-select-scheme-nodes
           ExchangeSigningSignalQuery nodes))
         (selected-rows (.ref result 'rows)))
    (unless (poo-flow-all?
             (lambda (row)
               (signal-row?
                row (.ref ExchangeSigningSignalQuery
                          'selected-element-identities)))
             selected-rows)
      (error "Scheme GQL result violates signing signal schema"))
    (.o kind: 'lambda-episteme.exchange.signing-signal-result
        query-source-identity: (.ref result 'query-source-identity)
        rows: selected-rows
        scheme-executed?: #t
        provenance-verified?: #f
        action-authority?: #f)))
