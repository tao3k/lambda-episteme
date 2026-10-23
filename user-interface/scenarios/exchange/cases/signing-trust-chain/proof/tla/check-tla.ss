;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Use the parser-owned qualification API for both syntax and TLC evidence.
;;; A counterexample is expected evidence only when TLC names the intended
;;; invariant and every required transition; other failures fail closed.
(import (only-in :gerbil-parser/languages/tla-plus/v1/qualification
                 qualify-tla-plus-model
                 tla-plus-model-receipt-admitted
                 tla-plus-model-receipt-output
                 tla-plus-model-receipt->alist)
        (only-in :std/string/misc string-contains)
        (only-in :std/list/list every))

(def (qualification config)
  (qualify-tla-plus-model
   "SigningIntentBoundary.tla" config
   tlc: (getenv "TLC" "tlc") workers: 1))

(def (receipt-ref receipt key)
  (let (entry (assq key (tla-plus-model-receipt->alist receipt)))
    (and entry (cdr entry))))

(def (require-source receipt config)
  (unless (and (receipt-ref receipt 'syntax-accepted)
               (receipt-ref receipt 'roundtrip))
    (error "TLA+ source did not pass native parser qualification"
           config (tla-plus-model-receipt->alist receipt))))

(def (require-counterexample config transitions)
  (let (receipt (qualification config))
    (require-source receipt config)
    (let (output (tla-plus-model-receipt-output receipt))
      (unless (and (not (tla-plus-model-receipt-admitted receipt))
                   (receipt-ref receipt 'exit-status)
                   (not (zero? (receipt-ref receipt 'exit-status)))
                   (string-contains
                    output "Error: Invariant NoUnauthorizedEffect is violated.")
                   (every (lambda (transition) (string-contains output transition))
                          transitions))
        (error "TLC did not produce the required counterexample"
               config (tla-plus-model-receipt->alist receipt)))
      (displayln "TLA-COUNTEREXAMPLE-OK " config)
      (list config 'counterexample 'NoUnauthorizedEffect transitions))))

(def defended
  (let (receipt (qualification "Defended.cfg"))
    (require-source receipt "Defended.cfg")
    (unless (tla-plus-model-receipt-admitted receipt)
      (error "defended TLA+ model was not admitted"
             (tla-plus-model-receipt->alist receipt)))
    (displayln "TLA-DEFENDED-OK")
    '("Defended.cfg" defended NoUnauthorizedEffect ())))

(def qualified
  (list defended
        (require-counterexample "DirectAttack.cfg"
                                '("WeakSign" "ApplyTransfer"))
        (require-counterexample "RecordAttack.cfg"
                                '("entry = \"backend-record\"" "missingWitness = \"record-intent\"" "WeakSign" "ApplyTransfer"))
        (require-counterexample "ApiAttack.cfg"
                                '("entry = \"internal-api\"" "missingWitness = \"request-identity\"" "WeakSign" "ApplyTransfer"))
        (require-counterexample "QueueAttack.cfg"
                                '("entry = \"queue-producer\"" "missingWitness = \"producer-chain\"" "WeakSign" "ApplyTransfer"))
        (require-counterexample "AddressMapAttack.cfg"
                                '("entry = \"address-map\"" "missingWitness = \"destination-binding\"" "WeakSign" "ApplyTransfer"))
        (require-counterexample "AdminAttack.cfg"
                                '("WeakSign" "ApplyAdminChange"
                                  "DrainControlledWallet"))
        (require-counterexample "InterfaceAttack.cfg"
                                '("PrepareInterfaceAdmin" "WeakSign"
                                  "ApplyAdminChange" "DrainControlledWallet"))
        (require-counterexample "FrozenAdmin.cfg"
                                '("ApplyAdminChange" "FreezeAfterControl"
                                  "DrainAfterFreeze"))
        (require-counterexample "RecoveredDirect.cfg"
                                '("Freeze" "PrematureRecover"
                                  "WeakSignRecovered" "ApplyTransfer"))))

;;; Written only after every parser/TLC check succeeds; a failed run leaves no
;;; fresh complete receipt. The Case gate removes the previous file first.
(call-with-output-file "qualification-receipts.sexp"
  (lambda (port)
    (write qualified port)
    (newline port)))
(displayln "TLA-QUALIFICATION-OK")
