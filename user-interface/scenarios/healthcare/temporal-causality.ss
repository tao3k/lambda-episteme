;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Healthcare owns the clinical provenance defaults; Cases only declare facts.
(import (only-in :poo-flow/modules/temporal-causality/interface
                 poo-flow-causal-event poo-flow-temporal-observation))

(export healthcare-clinical-event)

(def (healthcare-clinical-event
      subject identity event-kind logical-position payload-identity
      causal-parent-identities modality committed?)
  (poo-flow-causal-event
   identity subject event-kind
   (poo-flow-temporal-observation
    (string-append identity "/time")
    'logical-version logical-position "healthcare/clinical-ledger")
   payload-identity causal-parent-identities modality committed?))
