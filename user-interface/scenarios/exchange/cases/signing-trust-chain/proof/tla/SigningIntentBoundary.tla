---- MODULE SigningIntentBoundary ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals

(*
Finite mechanism model, not an attribution of Bitget's undisclosed ingress.
The interface-admin branch follows the publicly reported Bybit attack shape.
Effects and their independent observation are separate transitions. Once an
admin change gives an attacker control, a signer-local freeze cannot undo it.
Definitions stay on single physical lines for the native Gerbil TLA+ parser.
*)

VARIABLES phase, entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot

vars == << phase, entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>

Phases == {"Start", "Prepared", "Signed", "Controlled", "Outflow"}
DirectEntries == {"backend-record", "internal-api", "queue-producer", "address-map"}
Entries == {"none", "legitimate", "backend-admin", "interface-admin"} \cup DirectEntries
Operations == {"none", "transfer", "admin-change"}
PolicyRoots == {"Integrated", "Incident", "Recovered"}
IndependentWitnesses == intentIndependent /\ riskIndependent /\ ledgerIndependent /\ displayTrusted
UnauthorizedEffect == (directOutflow \/ indirectOutflow) /\ (~bytesMatch \/ ~operationMatch)

Init == phase = "Start" /\ entry = "none" /\ operation = "none" /\ bytesMatch = FALSE /\ operationMatch = FALSE /\ claimsAppearValid = FALSE /\ intentIndependent = FALSE /\ riskIndependent = FALSE /\ ledgerIndependent = FALSE /\ displayTrusted = FALSE /\ nonceUsed = FALSE /\ signed = FALSE /\ walletControlled = FALSE /\ directOutflow = FALSE /\ indirectOutflow = FALSE /\ receiptObserved = FALSE /\ frozen = FALSE /\ policyRoot = "Integrated"

PrepareLegitimate == phase = "Start" /\ phase' = "Prepared" /\ entry' = "legitimate" /\ operation' = "transfer" /\ bytesMatch' = TRUE /\ operationMatch' = TRUE /\ claimsAppearValid' = TRUE /\ intentIndependent' = TRUE /\ riskIndependent' = TRUE /\ ledgerIndependent' = TRUE /\ displayTrusted' = TRUE /\ UNCHANGED << nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>
PrepareDirect(e) == e \in DirectEntries /\ phase = "Start" /\ phase' = "Prepared" /\ entry' = e /\ operation' = "transfer" /\ bytesMatch' = FALSE /\ operationMatch' = TRUE /\ claimsAppearValid' = TRUE /\ intentIndependent' = FALSE /\ riskIndependent' = FALSE /\ ledgerIndependent' = FALSE /\ displayTrusted' = TRUE /\ UNCHANGED << nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>
PrepareBackendTransfer == PrepareDirect("backend-record")
PrepareApiReplay == PrepareDirect("internal-api")
PrepareQueueInjection == PrepareDirect("queue-producer")
PrepareAddressMapSubstitution == PrepareDirect("address-map")
PrepareBackendAdmin == phase = "Start" /\ phase' = "Prepared" /\ entry' = "backend-admin" /\ operation' = "admin-change" /\ bytesMatch' = FALSE /\ operationMatch' = FALSE /\ claimsAppearValid' = TRUE /\ intentIndependent' = FALSE /\ riskIndependent' = FALSE /\ ledgerIndependent' = FALSE /\ displayTrusted' = FALSE /\ UNCHANGED << nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>
PrepareInterfaceAdmin == phase = "Start" /\ phase' = "Prepared" /\ entry' = "interface-admin" /\ operation' = "admin-change" /\ bytesMatch' = FALSE /\ operationMatch' = FALSE /\ claimsAppearValid' = TRUE /\ intentIndependent' = TRUE /\ riskIndependent' = TRUE /\ ledgerIndependent' = TRUE /\ displayTrusted' = FALSE /\ UNCHANGED << nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>

WeakSign == phase = "Prepared" /\ claimsAppearValid /\ ~frozen /\ policyRoot # "Incident" /\ ~nonceUsed /\ phase' = "Signed" /\ signed' = TRUE /\ nonceUsed' = TRUE /\ UNCHANGED << entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>
WeakSignRecovered == policyRoot = "Recovered" /\ WeakSign
BoundSign == phase = "Prepared" /\ claimsAppearValid /\ IndependentWitnesses /\ bytesMatch /\ operationMatch /\ ~frozen /\ policyRoot # "Incident" /\ ~nonceUsed /\ phase' = "Signed" /\ signed' = TRUE /\ nonceUsed' = TRUE /\ UNCHANGED << entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, walletControlled, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>

ApplyTransfer == phase = "Signed" /\ signed /\ operation = "transfer" /\ ~frozen /\ phase' = "Outflow" /\ directOutflow' = TRUE /\ UNCHANGED << entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, indirectOutflow, receiptObserved, frozen, policyRoot >>
ApplyAdminChange == phase = "Signed" /\ signed /\ operation = "admin-change" /\ ~frozen /\ phase' = "Controlled" /\ walletControlled' = TRUE /\ UNCHANGED << entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, directOutflow, indirectOutflow, receiptObserved, frozen, policyRoot >>
DrainControlledWallet == phase = "Controlled" /\ walletControlled /\ phase' = "Outflow" /\ indirectOutflow' = TRUE /\ UNCHANGED << entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, receiptObserved, frozen, policyRoot >>
DrainAfterFreeze == frozen /\ DrainControlledWallet
ObserveOutflow == phase = "Outflow" /\ ~receiptObserved /\ receiptObserved' = TRUE /\ UNCHANGED << phase, entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, frozen, policyRoot >>

Freeze == ~frozen /\ frozen' = TRUE /\ policyRoot' = "Incident" /\ UNCHANGED << phase, entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved >>
FreezeAfterControl == phase = "Controlled" /\ Freeze
PrematureRecover == frozen /\ frozen' = FALSE /\ policyRoot' = "Recovered" /\ UNCHANGED << phase, entry, operation, bytesMatch, operationMatch, claimsAppearValid, intentIndependent, riskIndependent, ledgerIndependent, displayTrusted, nonceUsed, signed, walletControlled, directOutflow, indirectOutflow, receiptObserved >>

DirectAttackNext == PrepareBackendTransfer \/ PrepareApiReplay \/ PrepareQueueInjection \/ PrepareAddressMapSubstitution \/ WeakSign \/ ApplyTransfer \/ ObserveOutflow \/ Freeze \/ PrematureRecover
AdminAttackNext == PrepareBackendAdmin \/ PrepareInterfaceAdmin \/ WeakSign \/ ApplyAdminChange \/ DrainControlledWallet \/ ObserveOutflow \/ Freeze \/ PrematureRecover
InterfaceAttackNext == PrepareInterfaceAdmin \/ WeakSign \/ ApplyAdminChange \/ DrainControlledWallet \/ ObserveOutflow
FrozenAdminNext == PrepareInterfaceAdmin \/ WeakSign \/ ApplyAdminChange \/ FreezeAfterControl \/ DrainAfterFreeze \/ ObserveOutflow
RecoveredDirectNext == PrepareBackendTransfer \/ Freeze \/ PrematureRecover \/ WeakSignRecovered \/ ApplyTransfer \/ ObserveOutflow
DefendedNext == PrepareLegitimate \/ PrepareBackendTransfer \/ PrepareApiReplay \/ PrepareQueueInjection \/ PrepareAddressMapSubstitution \/ PrepareBackendAdmin \/ PrepareInterfaceAdmin \/ BoundSign \/ ApplyTransfer \/ ApplyAdminChange \/ DrainControlledWallet \/ ObserveOutflow \/ Freeze \/ PrematureRecover
DirectAttackSpec == Init /\ [][DirectAttackNext]_vars
AdminAttackSpec == Init /\ [][AdminAttackNext]_vars
InterfaceAttackSpec == Init /\ [][InterfaceAttackNext]_vars
FrozenAdminSpec == Init /\ [][FrozenAdminNext]_vars
RecoveredDirectSpec == Init /\ [][RecoveredDirectNext]_vars
DefendedSpec == Init /\ [][DefendedNext]_vars

TypeInvariant == phase \in Phases /\ entry \in Entries /\ operation \in Operations /\ policyRoot \in PolicyRoots /\ bytesMatch \in BOOLEAN /\ operationMatch \in BOOLEAN /\ claimsAppearValid \in BOOLEAN /\ intentIndependent \in BOOLEAN /\ riskIndependent \in BOOLEAN /\ ledgerIndependent \in BOOLEAN /\ displayTrusted \in BOOLEAN /\ nonceUsed \in BOOLEAN /\ signed \in BOOLEAN /\ walletControlled \in BOOLEAN /\ directOutflow \in BOOLEAN /\ indirectOutflow \in BOOLEAN /\ receiptObserved \in BOOLEAN /\ frozen \in BOOLEAN
SignedNonceConsumed == signed => nonceUsed
NoUnboundSign == signed => (IndependentWitnesses /\ bytesMatch /\ operationMatch)
NoUnauthorizedEffect == ~UnauthorizedEffect
ReceiptRequiresEffect == receiptObserved => (directOutflow \/ indirectOutflow)
ControlRequiresAdminSignature == walletControlled => (signed /\ operation = "admin-change" /\ nonceUsed)
ObservedLossCandidate == receiptObserved /\ UnauthorizedEffect
NoObservedLossCandidate == ~ObservedLossCandidate

====
