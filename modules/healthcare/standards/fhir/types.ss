;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: bounded, inert FHIR constraint values.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-text?))

(export +poo-flow-fhir-constraint-kind+
        PooFlowFhirConstraint
        poo-flow-fhir-constraint?)

(def +poo-flow-fhir-constraint-kind+ 'poo-flow.fhir-constraint.v1)

(def (poo-flow-fhir-constraint-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-fhir-constraint-kind+)
       (.slot? value 'identity)
       (poo-flow-standard-text? (.ref value 'identity))
       (.slot? value 'constraint-kind)
       (symbol? (.ref value 'constraint-kind))
       (.slot? value 'path)
       (list? (.ref value 'path))
       (.slot? value 'expected)
       (.slot? value 'support-state)
       (memq (.ref value 'support-state) '(supported unsupported))))

(define-type (PooFlowFhirConstraint @ Type.)
  .element?: poo-flow-fhir-constraint-shape?)

(def (poo-flow-fhir-constraint? value)
  (element? PooFlowFhirConstraint value))
