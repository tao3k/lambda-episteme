import SigningTrustChain.SigningBoundary

/-!
An abstract signer Host. A `SignedInstruction` records that the modeled signer
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
  operation : String
  authenticated : Bool
  deriving Repr

structure Attempt where
  candidateBytesId : String
  actualUserIntentBytesId : String
  actualUserIntentOperation : String := "transfer"
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

structure SignedInstruction where
  bytesId : String
  operation : String
  nonce : Nat
  deriving Repr

def witnessMatches (issuer : Issuer) (bytesId operation : String)
    (witness : Witness) : Bool :=
  witness.authenticated && witness.issuer == issuer &&
  witness.bytesId == bytesId && witness.operation == operation

def independentBinding (state : HostState) (attempt : Attempt) : Bool :=
  witnessMatches .intentOwner attempt.candidateBytesId
    attempt.facts.candidateOperation attempt.intent &&
  witnessMatches .riskOwner attempt.candidateBytesId
    attempt.facts.candidateOperation attempt.risk &&
  witnessMatches .ledgerOwner attempt.candidateBytesId
    attempt.facts.candidateOperation attempt.ledger &&
  witnessMatches .signerDisplay attempt.candidateBytesId
    attempt.facts.candidateOperation attempt.display &&
  attempt.facts.nonceFresh && attempt.facts.walletEpoch == state.walletEpoch

def release (requireIndependent : Bool) (root : String)
    (state : HostState) (attempt : Attempt) : HostState × Option SignedInstruction :=
  if authorized root hotWallet attempt.facts &&
      !state.frozen &&
      (!requireIndependent || independentBinding state attempt) &&
      !(state.consumedNonces.contains attempt.nonce) then
    ({ consumedNonces := attempt.nonce :: state.consumedNonces },
      some ⟨attempt.candidateBytesId, attempt.facts.candidateOperation,
        attempt.nonce⟩)
  else (state, none)

def wouldSign (releaseResult : HostState × Option SignedInstruction) : Bool :=
  releaseResult.2.isSome

def unauthorizedSigningEffect (attempt : Attempt)
    (releaseResult : HostState × Option SignedInstruction) : Bool :=
  wouldSign releaseResult &&
  (attempt.candidateBytesId != attempt.actualUserIntentBytesId ||
    attempt.facts.candidateOperation != attempt.actualUserIntentOperation)

def backendWitness (bytesId : String) (operation : String := "transfer") : Witness :=
  ⟨.backend, bytesId, operation, true⟩

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
    intent := ⟨.intentOwner, "user-transfer", "transfer", true⟩
    risk := ⟨.riskOwner, "user-transfer", "transfer", true⟩
    ledger := ⟨.ledgerOwner, "user-transfer", "transfer", true⟩
    display := ⟨.signerDisplay, "user-transfer", "transfer", true⟩
    nonce := 78 }

def forgedIssuerLabels : Attempt :=
  { contaminatedAttempt with
    intent := ⟨.intentOwner, "attacker-transfer", "transfer", false⟩
    risk := ⟨.riskOwner, "attacker-transfer", "transfer", false⟩
    ledger := ⟨.ledgerOwner, "attacker-transfer", "transfer", false⟩
    display := ⟨.signerDisplay, "attacker-transfer", "transfer", false⟩ }

-- The Cedar request repeats an admin operation, while the authenticated
-- intent witness still attests a transfer. A byte label alone misses this.
def operationLabelForgery : Attempt :=
  { candidateBytesId := "shared-envelope"
    actualUserIntentBytesId := "shared-envelope"
    actualUserIntentOperation := "transfer"
    facts := { singleSourceAdminForgery with
      candidateDigest := "shared-envelope"
      intentDigest := "shared-envelope"
      riskDigest := "shared-envelope"
      ledgerDigest := "shared-envelope"
      displayDigest := "shared-envelope" }
    intent := ⟨.intentOwner, "shared-envelope", "transfer", true⟩
    risk := ⟨.riskOwner, "shared-envelope", "admin-change", true⟩
    ledger := ⟨.ledgerOwner, "shared-envelope", "admin-change", true⟩
    display := ⟨.signerDisplay, "shared-envelope", "admin-change", true⟩
    nonce := 80 }

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

theorem operationWitnessCutsMetadataSubstitution :
    authorized "Integrated" hotWallet operationLabelForgery.facts = true ∧
    unauthorizedSigningEffect operationLabelForgery
      (release false "Integrated" emptyHost operationLabelForgery) = true ∧
    wouldSign
      (release true "Integrated" emptyHost operationLabelForgery) = false := by
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
