import SigningTrustChain.SignerEffectReplay

/-!
A finite synthetic replay of two instruction-contamination mechanisms. A
Cedar policy decision enters through `release`; signing, on-chain effects,
and independent observation are separate steps. The public exchange notices
do not identify the hidden ingress of a particular transaction.
-/

namespace LambdaEpisteme.ExchangeIncidentReplay

open LambdaEpisteme.ExchangeSigning
open LambdaEpisteme.ExchangeSignerEffectReplay

inductive Ingress where
  | backendRecord | backendApi | queue | addressMap | signingInterface
  deriving BEq, Repr

structure Replay where
  ingress : Ingress
  attempt : Attempt
  host : HostState := {}
  signed : Option SignedInstruction := none
  walletControlled : Bool := false
  directOutflowUsd : Option Nat := none
  indirectOutflowUsd : Option Nat := none
  observedOutflowUsd : Option Nat := none

def signAt (root : String) (requireIndependent : Bool) (replay : Replay) : Replay :=
  let (host, signed) := release requireIndependent root replay.host replay.attempt
  { replay with host, signed }

def applyTransfer (usd : Nat) (replay : Replay) : Replay :=
  match replay.signed with
  | some instruction =>
    if instruction.operation == "transfer" && !replay.host.frozen then
      { replay with directOutflowUsd := some usd }
    else replay
  | none => replay

def applyAdminChange (replay : Replay) : Replay :=
  match replay.signed with
  | some instruction =>
    if instruction.operation == "admin-change" && !replay.host.frozen then
      { replay with walletControlled := true }
    else replay
  | none => replay

def freeze (replay : Replay) : Replay :=
  { replay with host := { replay.host with frozen := true } }

-- A signer-local freeze cannot revoke control already committed on-chain.
def drainControlledWallet (usd : Nat) (replay : Replay) : Replay :=
  if replay.walletControlled then
    { replay with indirectOutflowUsd := some usd }
  else replay

def observeOutflow (replay : Replay) : Replay :=
  match replay.directOutflowUsd, replay.indirectOutflowUsd with
  | some usd, none => { replay with observedOutflowUsd := some usd }
  | none, some usd => { replay with observedOutflowUsd := some usd }
  | _, _ => replay

def observedDivergentOutflowUsd (replay : Replay) : Option Nat :=
  if replay.signed.isSome &&
      (replay.attempt.candidateBytesId != replay.attempt.actualUserIntentBytesId ||
       replay.attempt.facts.candidateOperation != replay.attempt.actualUserIntentOperation)
  then replay.observedOutflowUsd
  else none

def directInputAt (ingress : Ingress) : Replay :=
  { ingress, attempt := contaminatedAttempt }

def directInput : Replay := directInputAt .backendRecord

def directWeakAt (ingress : Ingress) : Replay :=
  observeOutflow
    (applyTransfer 75000 (signAt "Integrated" false (directInputAt ingress)))

def directWeak : Replay := directWeakAt .backendRecord

def directBound : Replay :=
  observeOutflow (applyTransfer 75000 (signAt "Integrated" true directInput))

def interfaceAdminAttempt : Attempt :=
  { candidateBytesId := "admin-change"
    actualUserIntentBytesId := "routine-transfer"
    actualUserIntentOperation := "transfer"
    facts := singleSourceAdminForgery
    intent := ⟨.intentOwner, "routine-transfer", "transfer", true⟩
    risk := backendWitness "admin-change"
    ledger := backendWitness "admin-change"
    display := backendWitness "admin-change"
    nonce := 79 }

def adminInput : Replay :=
  { ingress := .signingInterface, attempt := interfaceAdminAttempt }

def adminWeak : Replay :=
  observeOutflow
    (drainControlledWallet 120000
      (freeze (applyAdminChange (signAt "Integrated" false adminInput))))

def adminBound : Replay :=
  observeOutflow
    (drainControlledWallet 120000
      (freeze (applyAdminChange (signAt "Integrated" true adminInput))))

def adminFrozenBeforeSign : Replay :=
  applyAdminChange (signAt "Integrated" false (freeze adminInput))

-- A distinct proposed ingress can have the same public terminal observation.
def backendAdminInput : Replay :=
  { adminInput with ingress := .backendApi }

def backendAdminWeak : Replay :=
  observeOutflow
    (drainControlledWallet 120000
      (applyAdminChange (signAt "Integrated" false backendAdminInput)))

def publicUnauthorizedOutflow (replay : Replay) : Bool :=
  (observedDivergentOutflowUsd replay).isSome

theorem directWeakReachesObservedOutflow :
    observedDivergentOutflowUsd directWeak = some 75000 := by native_decide

theorem directBoundCutsBeforeSigning :
    directBound.signed = none ∧ directBound.observedOutflowUsd = none := by
  native_decide

theorem adminWeakChangesControlBeforeDrain :
    adminWeak.walletControlled = true ∧ adminWeak.host.frozen = true ∧
    observedDivergentOutflowUsd adminWeak = some 120000 := by native_decide

theorem adminBoundCutsBeforeControlChange :
    adminBound.signed = none ∧ adminBound.walletControlled = false ∧
    adminBound.observedOutflowUsd = none := by native_decide

theorem freezeBeforeAdminSignatureCutsControlChange :
    adminFrozenBeforeSign.walletControlled = false := by native_decide

theorem publicOutflowDoesNotIdentifyIngress :
    publicUnauthorizedOutflow adminWeak = true ∧
    publicUnauthorizedOutflow backendAdminWeak = true ∧
    adminWeak.ingress != backendAdminWeak.ingress := by native_decide

theorem directIngressRoutesSharePublicObservation :
    [.backendRecord, .backendApi, .queue, .addressMap].all
      (fun ingress => publicUnauthorizedOutflow (directWeakAt ingress)) = true := by
  native_decide

end LambdaEpisteme.ExchangeIncidentReplay
