;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :clan/poo/mop define-type Type. element?)
        (only-in :agentic-ai-lab/modules/standards/types
                 agentic-ai-lab-standards-module?))

(export +lambda-healthcare-module-kind+
        AgenticAILabHealthcareModule
        lambda-healthcare-module?)

(def +lambda-healthcare-module-kind+ 'lambda-episteme.healthcare-module.v1)

(def (lambda-healthcare-module-shape? value)
  (and (object? value)
       (.slot? value 'kind)
       (.slot? value 'identity)
       (.slot? value 'standards)
       (eq? (.ref value 'kind) +lambda-healthcare-module-kind+)
       (string? (.ref value 'identity))
       (agentic-ai-lab-standards-module? (.ref value 'standards))))

(define-type (AgenticAILabHealthcareModule @ Type.)
  .element?: lambda-healthcare-module-shape?)

(def (lambda-healthcare-module? value)
  (element? AgenticAILabHealthcareModule value))
