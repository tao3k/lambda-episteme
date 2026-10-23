;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Healthcare owns the clinical provenance defaults; Cases only declare facts.
(import (only-in :agentic-ai-lab/modules/temporal-causality/interface
                 agentic-ai-lab-causal-event agentic-ai-lab-temporal-observation))

(export healthcare-clinical-event)

(def (healthcare-clinical-event
      subject identity event-kind logical-position payload-identity
      causal-parent-identities modality committed?)
  (agentic-ai-lab-causal-event
   identity subject event-kind
   (agentic-ai-lab-temporal-observation
    (string-append identity "/time")
    'logical-version logical-position "healthcare/clinical-ledger")
   payload-identity causal-parent-identities modality committed?))
