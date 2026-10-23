import SigningTrustChain.SigningBoundary

/-!
A synthetic timeline over the exact POO roots exported to Cedar. The replay
models decisions over supplied facts. It neither asserts Bitget's intrusion
path nor simulates a real signing device or atomic Host effect.
-/

namespace LambdaEpisteme.ExchangeSigningAttackReplay

open LambdaEpisteme.ExchangeSigning

structure Stage where
  name : String
  root : String
  facts : Facts
  expected : Bool

def timeline : List Stage := [
  ⟨"legitimate-transfer", "Integrated", {}, true⟩,
  ⟨"backend-only-substitution", "Backend", backendForgery, true⟩,
  ⟨"independent-controls-reject", "Integrated", backendForgery, false⟩,
  ⟨"interface-substitution-rejected", "Integrated", interfaceSwap, false⟩,
  ⟨"shared-source-claim-contamination", "Integrated", singleSourceForgery, true⟩,
  ⟨"incident-freeze", "Incident", singleSourceForgery, false⟩,
  ⟨"premature-recovery", "Recovered", singleSourceForgery, true⟩]

def decisions : List (String × Bool) :=
  timeline.map fun stage =>
    (stage.name, authorized stage.root hotWallet stage.facts)

theorem timelineExact :
    timeline.all (fun stage =>
      authorized stage.root hotWallet stage.facts == stage.expected) = true := by
  native_decide

theorem boundaryTransitions :
    decisions = [
      ("legitimate-transfer", true),
      ("backend-only-substitution", true),
      ("independent-controls-reject", false),
      ("interface-substitution-rejected", false),
      ("shared-source-claim-contamination", true),
      ("incident-freeze", false),
      ("premature-recovery", true)] := by
  native_decide

end LambdaEpisteme.ExchangeSigningAttackReplay
