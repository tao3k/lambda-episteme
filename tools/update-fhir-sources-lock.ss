#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref)
        (only-in :std/misc/path path-expand)
        (only-in :std/misc/ports read-file-u8vector)
        (only-in :poo-flow/src/feature-system/source-lock-feature
                 sources-lock-freeze
                 write-sources-lock-module)
        :poo-flow/lambda-episteme/modules/healthcare/standards/fhir/sources)

(def arguments (cddr (command-line)))
(def root (if (pair? arguments) (car (reverse arguments)) "."))

(def (observe-phase phase . fields)
  (display "[fhir-source-lock] phase=")
  (display phase)
  (for-each
   (lambda (field)
     (display " ")
     (display (car field))
     (display "=")
     (display (cdr field)))
   fields)
  (newline)
  (force-output))

(def (read-source path)
  (observe-phase 'source-read-start (cons 'path path))
  (let (payload (read-file-u8vector (path-expand path root)))
    (observe-phase 'source-read-complete
                   (cons 'path path)
                   (cons 'byteCount (u8vector-length payload)))
    payload))

(observe-phase 'freeze-start (cons 'sourceCount (length FHIRSources)))

(def lock
  (sources-lock-freeze
   "lambda-episteme/healthcare/fhir/sources"
   "hl7.fhir.r4.core@4.0.1+hl7.fhir.au.base@5.0.0+hl7.fhir.au.core@1.0.0"
   FHIRSources
   read-source
   '((authority . hl7-international+hl7-australia)
     (standard-family . fhir)
     (packages . ("hl7.fhir.r4.core@4.0.1"
                  "hl7.fhir.au.base@5.0.0"
                  "hl7.fhir.au.core@1.0.0")))))

(observe-phase 'freeze-complete
               (cons 'entryCount (.ref lock 'entry-count))
               (cons 'byteCount (.ref lock 'byte-count)))

(observe-phase 'write-start)
(call-with-output-file
 (path-expand
  "modules/healthcare/standards/fhir/source.lock.ss" root)
 (lambda (port)
   (write-sources-lock-module port 'FHIRSourcesLock lock)))
(observe-phase 'write-complete)
