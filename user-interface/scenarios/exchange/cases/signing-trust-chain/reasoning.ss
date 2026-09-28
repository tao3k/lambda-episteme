;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Industry-owned rules. POO Flow pins the Ascent kernel; this module only
;;; separates observed links from proposed links in one signing-chain Case.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        (only-in :std/list/list every)
        (only-in :gerbil-ascent/program/interface
                 ascent gerbil-ascent-evaluate-program))

(export ExchangeSigningRouteCase.
        exchange-signing-route-candidates)

(def ExchangeSigningRouteCase.
  (.o kind: 'lambda-episteme.exchange.signing-route-case
      observed-edges: '()
      proposed-edges: '()
      surfaces: '()
      targets: '()))

(def (edge? row)
  (and (list? row) (= (length row) 3)
       (symbol? (car row)) (symbol? (cadr row))
       (symbol? (caddr row))))

(def (unary? row)
  (and (list? row) (= (length row) 1) (symbol? (car row))))

(def (exchange-signing-case? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind observed-edges proposed-edges surfaces targets))
       (eq? (.ref value 'kind)
            'lambda-episteme.exchange.signing-route-case)
       (every edge? (.ref value 'observed-edges))
       (every edge? (.ref value 'proposed-edges))
       (every unary? (.ref value 'surfaces))
       (every unary? (.ref value 'targets))))

(def (exchange-signing-route-candidates case-value)
  (unless (exchange-signing-case? case-value)
    (error "invalid Exchange signing route Case" case-value))
  (let* ((observed-rows (.ref case-value 'observed-edges))
         (proposed-rows (.ref case-value 'proposed-edges))
         (surface-rows (.ref case-value 'surfaces))
         (target-rows (.ref case-value 'targets))
         (result
          (gerbil-ascent-evaluate-program
           (ascent
            (relation observed (from to source) observed-rows)
            (relation proposed (from to source) proposed-rows)
            (relation surface (node) surface-rows)
            (relation target (node) target-rows)
            (relation possible-link (from to))
            (relation possible-reach (from to))
            (relation observed-reach (from to))
            (relation possible-candidate (surface target))
            (relation observed-candidate (surface target))
            ((possible-link x y) <-- (observed x y source))
            ((possible-link x y) <-- (proposed x y source))
            ((possible-reach x y) <-- (possible-link x y))
            ((possible-reach x z) <-- (possible-reach x y)
             (possible-link y z))
            ((observed-reach x y) <-- (observed x y source))
            ((observed-reach x z) <-- (observed-reach x y)
             (observed y z source))
            ((possible-candidate x z) <-- (surface x)
             (possible-reach x z) (target z))
            ((observed-candidate x z) <-- (surface x)
             (observed-reach x z) (target z))
            (bounds 64 256 512))))
         (rows-of (.ref result 'rows-of)))
    (.o kind: 'lambda-episteme.exchange.signing-route-candidates
        possible-candidates: (rows-of 'possible-candidate)
        observed-candidates: (rows-of 'observed-candidate)
        observed-edges: observed-rows
        proposed-edges: proposed-rows
        admitted?: #f
        action-authority?: #f)))
