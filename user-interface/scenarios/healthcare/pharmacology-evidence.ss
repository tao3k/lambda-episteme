;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; The JSON file is an interchange representation.  These gerbil-poo Types
;;; own validation and the inherited `.json<-` / `.<-json` round trip.
(import (only-in :std/encoding/json JSONReadOptions read-json)
        (only-in :clan/poo/mop Class. define-type <-json)
        (only-in :clan/poo/brace @method)
        (only-in :clan/poo/type List String))

(export HealthcareDrugInteractionFact
        HealthcarePharmacologyEvidence
        healthcare-pharmacology-evidence-read-file)

(def +healthcare-pharmacology-json-read-options+
  (JSONReadOptions key-as-symbol: #f
                   array-as-vector: #f
                   object-as-hash: #t))

(define-type (HealthcareDrugInteractionFact @ Class.)
  slots: =>.+
  {subject: {type: String}
   relation: {type: String}
   object: {type: String}
   required-review: {type: String default: ""}
   source: {type: String}}
  sealed: #t)

(define-type (HealthcarePharmacologyEvidence @ Class.)
  slots: =>.+
  {identity: {type: String}
   retrieved: {type: String}
   use: {type: String}
   facts: {type: (List HealthcareDrugInteractionFact)}})

(def (healthcare-pharmacology-evidence-read-file path)
  (<-json
   HealthcarePharmacologyEvidence
   (call-with-input-file
    path
    (lambda (port)
      (read-json port +healthcare-pharmacology-json-read-options+)))))
