import SigningTrustChain.SigningBoundary

/-!
An abstract signer Host. A `SignedTransfer` records that the modeled signer
would sign these exact symbolic bytes; it is not a cryptographic signature or
an on-chain transaction. The upstream incident's internal path is unknown.
-/

namespace LambdaEpisteme.ExchangeSignerEffectReplay

open LambdaEpisteme.ExchangeSigning

inductive Issuer where
  | backend | intentOwner | riskOwner | ledgerOwner | signerDisplay
  deriving BEq, Repr

structure Witness where
  issuer : Issuer
  bytesId : String
  authenticated : Bool
  deriving Repr

structure Attempt where
  candidateBytesId : String
  actualUserIntentBytesId : String
  facts : Facts
  intent : Witness
  risk : Witness
  ledger : Witness
  display : Witness
  nonce : Nat

structure HostState where
  consumedNonces : List Nat := []
  walletEpoch : Int64 := 7
  frozen : Bool := false
  deriving Repr

structure SignedTransfer where
  bytesId : String
  nonce : Nat
  deriving Repr

def witnessMatches (issuer : Issuer) (bytesId : String) (witness : Witness) : Bool :=
  witness.authenticated && witness.issuer == issuer && witness.bytesId == bytesId

def independentBinding (state : HostState) (attempt : Attempt) : Bool :=
  witnessMatches .intentOwner attempt.candidateBytesId attempt.intent &&
  witnessMatches .riskOwner attempt.candidateBytesId attempt.risk &&
  witnessMatches .ledgerOwner attempt.candidateBytesId attempt.ledger &&
  witnessMatches .signerDisplay attempt.candidateBytesId attempt.display &&
  attempt.facts.nonceFresh && attempt.facts.walletEpoch == state.walletEpoch

def release (requireIndependent : Bool) (root : String)
    (state : HostState) (attempt : Attempt) : HostState × Option SignedTransfer :=
  if authorized root hotWallet attempt.facts &&
      !state.frozen &&
      (!requireIndependent || independentBinding state attempt) &&
      !(state.consumedNonces.contains attempt.nonce) then
    ({ consumedNonces := attempt.nonce :: state.consumedNonces },
      some ⟨attempt.candidateBytesId, attempt.nonce⟩)
  else (state, none)

def wouldSign (releaseResult : HostState × Option SignedTransfer) : Bool :=
  releaseResult.2.isSome

def unauthorizedSigningEffect (attempt : Attempt)
    (releaseResult : HostState × Option SignedTransfer) : Bool :=
  wouldSign releaseResult &&
  attempt.candidateBytesId != attempt.actualUserIntentBytesId

def backendWitness (bytesId : String) : Witness :=
  ⟨.backend, bytesId, true⟩

def contaminatedAttempt : Attempt :=
  { candidateBytesId := "attacker-transfer"
    actualUserIntentBytesId := "user-transfer"
    facts := singleSourceForgery
    intent := backendWitness "attacker-transfer"
    risk := backendWitness "attacker-transfer"
    ledger := backendWitness "attacker-transfer"
    display := backendWitness "attacker-transfer"
    nonce := 77 }

def independentFacts : Facts :=
  { candidateDigest := "user-transfer", intentDigest := "user-transfer",
    riskDigest := "user-transfer", ledgerDigest := "user-transfer",
    displayDigest := "user-transfer" }

def independentAttempt : Attempt :=
  { candidateBytesId := "user-transfer"
    actualUserIntentBytesId := "user-transfer"
    facts := independentFacts
    intent := ⟨.intentOwner, "user-transfer", true⟩
    risk := ⟨.riskOwner, "user-transfer", true⟩
    ledger := ⟨.ledgerOwner, "user-transfer", true⟩
    display := ⟨.signerDisplay, "user-transfer", true⟩
    nonce := 78 }

def forgedIssuerLabels : Attempt :=
  { contaminatedAttempt with
    intent := ⟨.intentOwner, "attacker-transfer", false⟩
    risk := ⟨.riskOwner, "attacker-transfer", false⟩
    ledger := ⟨.ledgerOwner, "attacker-transfer", false⟩
    display := ⟨.signerDisplay, "attacker-transfer", false⟩ }

def emptyHost : HostState := {}

theorem compromisedBackendCanTriggerWeakSigner :
    unauthorizedSigningEffect contaminatedAttempt
      (release false "Integrated" emptyHost contaminatedAttempt) = true := by
  native_decide

theorem independentSignerRejectsSameCedarAllow :
    authorized "Integrated" hotWallet contaminatedAttempt.facts = true ∧
    wouldSign
      (release true "Integrated" emptyHost contaminatedAttempt) = false := by
  native_decide

theorem forgedIssuerLabelsDoNotAuthenticate :
    authorized "Integrated" hotWallet forgedIssuerLabels.facts = true ∧
    wouldSign
      (release true "Integrated" emptyHost forgedIssuerLabels) = false := by
  native_decide

theorem freezeStopsWeakSigner :
    wouldSign
      (release false "Incident" emptyHost contaminatedAttempt) = false := by
  native_decide

theorem prematureRecoveryReopensWeakSigner :
    unauthorizedSigningEffect contaminatedAttempt
      (release false "Recovered" emptyHost contaminatedAttempt) = true := by
  native_decide

theorem signerLocalFreezeStopsStalePolicyRoot :
    wouldSign
      (release false "Integrated" { frozen := true }
        contaminatedAttempt) = false := by
  native_decide

theorem independentTransferSignsOnce :
    let first := release true "Integrated" emptyHost independentAttempt
    wouldSign first = true ∧
    wouldSign
      (release true "Integrated" first.1 independentAttempt) = false := by
  native_decide

end LambdaEpisteme.ExchangeSignerEffectReplay
