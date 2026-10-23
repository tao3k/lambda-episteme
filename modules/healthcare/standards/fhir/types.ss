;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare boundary: bounded, inert FHIR constraint values.
(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        :std/list/list
        (only-in :agentic-ai-lab/modules/standards/types
                 agentic-ai-lab-standard-digest?
                 agentic-ai-lab-standard-text?))

(export +agentic-ai-lab-fhir-constraint-kind+
        +agentic-ai-lab-fhir-capability-kind+
        AgenticAILabFhirConstraint
        AgenticAILabFhirCapability
        agentic-ai-lab-fhir-capability?
        agentic-ai-lab-fhir-constraint?)

(def +agentic-ai-lab-fhir-constraint-kind+ 'agentic-ai-lab.fhir-constraint.v1)
(def +agentic-ai-lab-fhir-capability-kind+ 'agentic-ai-lab.fhir-capability.v1)

(def (agentic-ai-lab-fhir-capability-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +agentic-ai-lab-fhir-capability-kind+)
       (agentic-ai-lab-standard-text? (.ref value 'identity))
       (symbol? (.ref value 'capability))
       (memq (.ref value 'state)
             '(native-bounded syntax-qualified reference-qualified
                              not-evaluated))
       (agentic-ai-lab-standard-text? (.ref value 'owner))
       (and (list? (.ref value 'evidence-digests))
            (every agentic-ai-lab-standard-digest?
                   (.ref value 'evidence-digests)))
       (agentic-ai-lab-standard-text? (.ref value 'detail))))

(define-type (AgenticAILabFhirCapability @ Type.)
  .element?: agentic-ai-lab-fhir-capability-shape?)

(def (agentic-ai-lab-fhir-constraint-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (eq? (.ref value 'kind) +agentic-ai-lab-fhir-constraint-kind+)
       (.slot? value 'identity)
       (agentic-ai-lab-standard-text? (.ref value 'identity))
       (.slot? value 'constraint-kind)
       (symbol? (.ref value 'constraint-kind))
       (.slot? value 'path)
       (list? (.ref value 'path))
       (.slot? value 'expected)
       (.slot? value 'support-state)
       (memq (.ref value 'support-state) '(supported unsupported))))

(define-type (AgenticAILabFhirConstraint @ Type.)
  .element?: agentic-ai-lab-fhir-constraint-shape?)

(def (agentic-ai-lab-fhir-capability? value)
  (element? AgenticAILabFhirCapability value))

(def (agentic-ai-lab-fhir-constraint? value)
  (element? AgenticAILabFhirConstraint value))
