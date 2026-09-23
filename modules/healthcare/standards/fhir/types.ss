;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: bounded, inert FHIR constraint values.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        :std/list/list
        (only-in :poo-flow/src/modules/standards/types
                 poo-flow-standard-digest?
                 poo-flow-standard-text?))

(export +poo-flow-fhir-constraint-kind+
        +poo-flow-fhir-capability-kind+
        PooFlowFhirConstraint
        PooFlowFhirCapability
        poo-flow-fhir-capability?
        poo-flow-fhir-constraint?)

(def +poo-flow-fhir-constraint-kind+ 'poo-flow.fhir-constraint.v1)
(def +poo-flow-fhir-capability-kind+ 'poo-flow.fhir-capability.v1)

(def (poo-flow-fhir-capability-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +poo-flow-fhir-capability-kind+)
       (poo-flow-standard-text? (.ref value 'identity))
       (symbol? (.ref value 'capability))
       (memq (.ref value 'state)
             '(native-bounded syntax-qualified reference-qualified
                              not-evaluated))
       (poo-flow-standard-text? (.ref value 'owner))
       (and (list? (.ref value 'evidence-digests))
            (every poo-flow-standard-digest?
                   (.ref value 'evidence-digests)))
       (poo-flow-standard-text? (.ref value 'detail))))

(define-type (PooFlowFhirCapability @ Type.)
  .element?: poo-flow-fhir-capability-shape?)

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

(def (poo-flow-fhir-capability? value)
  (element? PooFlowFhirCapability value))

(def (poo-flow-fhir-constraint? value)
  (element? PooFlowFhirConstraint value))
