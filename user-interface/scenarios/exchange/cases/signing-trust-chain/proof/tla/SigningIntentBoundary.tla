---- MODULE SigningIntentBoundary ----
\* SPDX-FileCopyrightText: 2026 tao3k team and Contributors
\*
\* SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

EXTENDS Naturals, TLC

(*
Abstract threat model for two instruction-contamination entry points.
Backend and interface are hypotheses, not findings about Bitget. The signer
effect is symbolic. Definitions remain on one physical line for the native
Gerbil TLA+ parser contract. Parsing does not prove the invariants.
*)

VARIABLES phase, entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, signed, broadcast, frozen, nonceUsed

vars == << phase, entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, signed, broadcast, frozen, nonceUsed >>

Phases == {"Start", "Prepared", "Signed", "Broadcast", "Frozen"}
Entries == {"none", "legitimate", "backend", "interface"}
IndependentWitnesses == intentIndependent /\ riskIndependent /\ ledgerIndependent /\ displayMatchesBytes
Init == phase = "Start" /\ entry = "none" /\ candidateAccepted = FALSE /\ intentIndependent = FALSE /\ riskIndependent = FALSE /\ ledgerIndependent = FALSE /\ displayMatchesBytes = FALSE /\ signed = FALSE /\ broadcast = FALSE /\ frozen = FALSE /\ nonceUsed = FALSE
PrepareLegitimate == phase = "Start" /\ phase' = "Prepared" /\ entry' = "legitimate" /\ candidateAccepted' = TRUE /\ intentIndependent' = TRUE /\ riskIndependent' = TRUE /\ ledgerIndependent' = TRUE /\ displayMatchesBytes' = TRUE /\ UNCHANGED << signed, broadcast, frozen, nonceUsed >>
CompromiseBackend == phase = "Start" /\ phase' = "Prepared" /\ entry' = "backend" /\ candidateAccepted' = TRUE /\ intentIndependent' = FALSE /\ riskIndependent' = FALSE /\ ledgerIndependent' = FALSE /\ displayMatchesBytes' = TRUE /\ UNCHANGED << signed, broadcast, frozen, nonceUsed >>
CompromiseInterface == phase = "Start" /\ phase' = "Prepared" /\ entry' = "interface" /\ candidateAccepted' = TRUE /\ intentIndependent' = TRUE /\ riskIndependent' = TRUE /\ ledgerIndependent' = TRUE /\ displayMatchesBytes' = FALSE /\ UNCHANGED << signed, broadcast, frozen, nonceUsed >>
WeakSign == phase = "Prepared" /\ candidateAccepted /\ ~frozen /\ ~nonceUsed /\ phase' = "Signed" /\ signed' = TRUE /\ nonceUsed' = TRUE /\ UNCHANGED << entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, broadcast, frozen >>
BoundSign == phase = "Prepared" /\ candidateAccepted /\ IndependentWitnesses /\ ~frozen /\ ~nonceUsed /\ phase' = "Signed" /\ signed' = TRUE /\ nonceUsed' = TRUE /\ UNCHANGED << entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, broadcast, frozen >>
Broadcast == phase = "Signed" /\ signed /\ ~frozen /\ phase' = "Broadcast" /\ broadcast' = TRUE /\ UNCHANGED << entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, signed, frozen, nonceUsed >>
Freeze == ~frozen /\ phase' = "Frozen" /\ frozen' = TRUE /\ UNCHANGED << entry, candidateAccepted, intentIndependent, riskIndependent, ledgerIndependent, displayMatchesBytes, signed, broadcast, nonceUsed >>
AttackNext == PrepareLegitimate \/ CompromiseBackend \/ CompromiseInterface \/ WeakSign \/ Broadcast \/ Freeze
DefendedNext == PrepareLegitimate \/ CompromiseBackend \/ CompromiseInterface \/ BoundSign \/ Broadcast \/ Freeze
AttackSpec == Init /\ [][AttackNext]_vars
DefendedSpec == Init /\ [][DefendedNext]_vars
TypeInvariant == phase \in Phases /\ entry \in Entries /\ candidateAccepted \in BOOLEAN /\ intentIndependent \in BOOLEAN /\ riskIndependent \in BOOLEAN /\ ledgerIndependent \in BOOLEAN /\ displayMatchesBytes \in BOOLEAN /\ signed \in BOOLEAN /\ broadcast \in BOOLEAN /\ frozen \in BOOLEAN /\ nonceUsed \in BOOLEAN
NoUnboundSign == signed => IndependentWitnesses
NoUnboundBroadcast == broadcast => IndependentWitnesses
SignedNonceConsumed == signed => nonceUsed

====
