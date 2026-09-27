import CedarPooSpec.Revision
import CedarPooSpec.PolicyJson
import CedarPooSpec.CompoundAuthorization

/-!
A signer must authorize the transaction bytes it will sign, using witnesses
obtained outside the transaction-construction backend. The published exchange
incidents motivate the interface; all identities, digests, and controls here
are illustrative rather than a reconstruction of either production system.
-/

namespace LambdaEpisteme.ExchangeSigning

open Cedar.Spec Cedar.Data Cedar.Validation CedarPooSpec.PolicyModules

def signerType : EntityType := ⟨"Signer", []⟩
def walletType : EntityType := ⟨"Wallet", []⟩
def actionType : EntityType := ⟨"Action", []⟩
def signer : EntityUID := ⟨signerType, "signer-a"⟩
def hotWallet : EntityUID := ⟨walletType, "hot-affected"⟩
def otherWallet : EntityUID := ⟨walletType, "hot-unaffected"⟩
def sign : EntityUID := ⟨actionType, "sign-transfer"⟩

def emptyEntry : EntitySchemaEntry := .standard ⟨Set.empty, Map.empty, none⟩
def walletEntry : EntitySchemaEntry := .standard ⟨Set.empty, Map.make [
  ("affected", .required (.bool .anyBool)),
  ("epoch", .required .int)], none⟩
def contextType : RecordType := Map.make [
  ("backendApproved", .required (.bool .anyBool)),
  ("candidateDigest", .required .string),
  ("intentDigest", .required .string),
  ("riskDigest", .required .string),
  ("ledgerDigest", .required .string),
  ("displayDigest", .required .string),
  ("candidateOperation", .required .string),
  ("intentOperation", .required .string),
  ("adminApproved", .required (.bool .anyBool)),
  ("riskApproved", .required (.bool .anyBool)),
  ("ledgerReserved", .required (.bool .anyBool)),
  ("nonceFresh", .required (.bool .anyBool)),
  ("walletEpoch", .required .int)]
def actionEntry : ActionSchemaEntry :=
  ⟨Set.make [signerType], Set.make [walletType], Set.empty, contextType⟩
def schema : Schema :=
  ⟨Map.make [(signerType, emptyEntry), (walletType, walletEntry)],
    Map.make [(sign, actionEntry)]⟩

def emptyData : EntityData :=
  { attrs := Map.empty, ancestors := Set.empty, tags := Map.empty }
def walletData (affected : Bool) : EntityData :=
  { attrs := Map.make [
      ("affected", .prim (.bool affected)),
      ("epoch", .prim (.int 7))],
    ancestors := Set.empty, tags := Map.empty }
def entities : Entities := Map.make [
  (signer, emptyData), (hotWallet, walletData true),
  (otherWallet, walletData false),
  (sign, actionSchemaEntryToEntityData actionEntry)]

def ctx (name : String) : Expr := .getAttr (.var .context) name
def walletFact (name : String) : Expr := .getAttr (.var .resource) name
def eqCtx (left right : String) : Expr :=
  .binaryApp .eq (ctx left) (ctx right)
def policy (id : String) (effect : Effect) (body : Expr) : Policy :=
  { id, effect,
    principalScope := .principalScope (.eq signer),
    actionScope := .actionScope (.eq sign),
    resourceScope := .resourceScope .any,
    condition := [{ kind := .when, body }] }

def backendPermit : Policy :=
  policy "backend-sign-approval" .permit (ctx "backendApproved")
def intentCondition : Expr :=
  .and (.and (ctx "backendApproved")
      (eqCtx "candidateDigest" "intentDigest"))
    (eqCtx "candidateOperation" "intentOperation")
def intentBoundPermit : Policy :=
  { backendPermit with condition := [{ kind := .when, body := intentCondition }] }
def riskVeto : Policy :=
  policy "independent-risk-veto" .forbid
    (.or (.unaryApp .not (ctx "riskApproved"))
      (.unaryApp .not (eqCtx "candidateDigest" "riskDigest")))
def ledgerVeto : Policy :=
  policy "independent-ledger-veto" .forbid
    (.or (.unaryApp .not (ctx "ledgerReserved"))
      (.unaryApp .not (eqCtx "candidateDigest" "ledgerDigest")))
def signerVeto : Policy :=
  policy "signer-byte-and-epoch-veto" .forbid
    (.or
      (.or (.unaryApp .not (eqCtx "candidateDigest" "displayDigest"))
        (.or (.unaryApp .not (ctx "nonceFresh"))
          (.unaryApp .not
            (.binaryApp .eq (ctx "walletEpoch") (walletFact "epoch")))))
      (.and
        (.binaryApp .eq (ctx "candidateOperation")
          (.lit (.string "admin-change")))
        (.unaryApp .not (ctx "adminApproved"))))
def incidentFreeze : Policy :=
  policy "affected-wallet-freeze" .forbid (walletFact "affected")

def model : Model := { modules := [
  { name := "Backend", edits := [.extend backendPermit] },
  { name := "Intent", parentOrders := [["Backend"]],
    edits := [.overlay intentBoundPermit] },
  { name := "Risk", parentOrders := [["Backend"]],
    edits := [.extend riskVeto] },
  { name := "Ledger", parentOrders := [["Backend"]],
    edits := [.extend ledgerVeto] },
  { name := "Signer", parentOrders := [["Backend"]],
    edits := [.extend signerVeto] },
  { name := "Integrated", parentOrders := [["Intent", "Risk", "Ledger", "Signer"]] },
  { name := "Incident", parentOrders := [["Integrated"]],
    edits := [.extend incidentFreeze] },
  { name := "Recovered", parentOrders := [["Incident"]],
    edits := [.remove incidentFreeze.id] }] }

structure Facts where
  backendApproved : Bool := true
  candidateDigest : String := "transfer-a"
  intentDigest : String := "transfer-a"
  riskDigest : String := "transfer-a"
  ledgerDigest : String := "transfer-a"
  displayDigest : String := "transfer-a"
  candidateOperation : String := "transfer"
  intentOperation : String := "transfer"
  adminApproved : Bool := false
  riskApproved : Bool := true
  ledgerReserved : Bool := true
  nonceFresh : Bool := true
  walletEpoch : Int64 := 7

def context (facts : Facts) : Map String Value := Map.make [
  ("backendApproved", .prim (.bool facts.backendApproved)),
  ("candidateDigest", .prim (.string facts.candidateDigest)),
  ("intentDigest", .prim (.string facts.intentDigest)),
  ("riskDigest", .prim (.string facts.riskDigest)),
  ("ledgerDigest", .prim (.string facts.ledgerDigest)),
  ("displayDigest", .prim (.string facts.displayDigest)),
  ("candidateOperation", .prim (.string facts.candidateOperation)),
  ("intentOperation", .prim (.string facts.intentOperation)),
  ("adminApproved", .prim (.bool facts.adminApproved)),
  ("riskApproved", .prim (.bool facts.riskApproved)),
  ("ledgerReserved", .prim (.bool facts.ledgerReserved)),
  ("nonceFresh", .prim (.bool facts.nonceFresh)),
  ("walletEpoch", .prim (.int facts.walletEpoch))]
def request (wallet : EntityUID) (facts : Facts) : Request :=
  ⟨signer, sign, wallet, context facts⟩
def authorized (root : String) (wallet : EntityUID) (facts : Facts) : Bool :=
  match CedarPooSpec.CompoundAuthorization.authorizeLayers model
      [(root, request wallet facts)] entities with
  | .error _ => false
  | .ok receipts => CedarPooSpec.CompoundAuthorization.layersAllowed receipts

def backendForgery : Facts :=
  { candidateDigest := "attacker-transfer" }
def interfaceSwap : Facts :=
  { candidateDigest := "attacker-transfer", intentDigest := "attacker-transfer",
    riskDigest := "attacker-transfer", ledgerDigest := "attacker-transfer" }
def singleSourceForgery : Facts :=
  { candidateDigest := "attacker-transfer", intentDigest := "attacker-transfer",
    riskDigest := "attacker-transfer", ledgerDigest := "attacker-transfer",
    displayDigest := "attacker-transfer" }

def disguisedAdminChange : Facts :=
  { candidateDigest := "admin-change", intentDigest := "routine-transfer",
    riskDigest := "admin-change", ledgerDigest := "admin-change",
    displayDigest := "routine-transfer", candidateOperation := "admin-change" }

def singleSourceAdminForgery : Facts :=
  { candidateDigest := "admin-change", intentDigest := "admin-change",
    riskDigest := "admin-change", ledgerDigest := "admin-change",
    displayDigest := "admin-change", candidateOperation := "admin-change",
    intentOperation := "admin-change", adminApproved := true }

def cases : List (String × String × EntityUID × Facts × Bool) := [
  ("legacy-backend-forgery", "Backend", hotWallet, backendForgery, true),
  ("intent-rejects-forgery", "Intent", hotWallet, backendForgery, false),
  ("risk-rejects-forgery", "Risk", hotWallet, backendForgery, false),
  ("ledger-rejects-forgery", "Ledger", hotWallet, backendForgery, false),
  ("signer-rejects-byte-mismatch", "Signer", hotWallet, backendForgery, false),
  ("integrated-valid-transfer", "Integrated", hotWallet, {}, true),
  ("integrated-backend-forgery", "Integrated", hotWallet, backendForgery, false),
  ("integrated-interface-swap", "Integrated", hotWallet, interfaceSwap, false),
  ("integrated-risk-refusal", "Integrated", hotWallet,
    { riskApproved := false }, false),
  ("integrated-no-ledger-reservation", "Integrated", hotWallet,
    { ledgerReserved := false }, false),
  ("integrated-replayed-nonce", "Integrated", hotWallet,
    { nonceFresh := false }, false),
  ("integrated-rotated-wallet", "Integrated", hotWallet,
    { walletEpoch := 6 }, false),
  ("incident-freezes-affected-wallet", "Incident", hotWallet, {}, false),
  ("incident-keeps-other-wallet", "Incident", otherWallet, {}, true),
  ("recovery-restores-affected-wallet", "Recovered", hotWallet, {}, true),
  ("all-claims-from-one-source-still-allow", "Integrated", hotWallet,
    singleSourceForgery, true),
  ("incident-freeze-blocks-single-source-forgery", "Incident", hotWallet,
    singleSourceForgery, false),
  ("premature-recovery-reopens-single-source-forgery", "Recovered", hotWallet,
    singleSourceForgery, true),
  ("integrated-disguised-admin-change", "Integrated", hotWallet,
    disguisedAdminChange, false),
  ("all-admin-claims-from-one-source-still-allow", "Integrated", hotWallet,
    singleSourceAdminForgery, true),
  ("incident-freeze-blocks-admin-forgery", "Incident", hotWallet,
    singleSourceAdminForgery, false)]

def casesExact : Bool := cases.all fun (_, root, wallet, facts, expected) =>
  authorized root wallet facts == expected
theorem casesExactFully : casesExact = true := by native_decide
theorem backendForgeryBlockedByComposition :
    authorized "Backend" hotWallet backendForgery = true ∧
    authorized "Integrated" hotWallet backendForgery = false := by native_decide
theorem interfaceSwapBlockedBySignerBranch :
    authorized "Intent" hotWallet interfaceSwap = true ∧
    authorized "Integrated" hotWallet interfaceSwap = false := by native_decide
theorem commonSourceForgeryStillAllows :
    authorized "Integrated" hotWallet singleSourceForgery = true := by native_decide
theorem incidentFreezeBlocksCommonSourceForgery :
    authorized "Incident" hotWallet singleSourceForgery = false := by native_decide
theorem prematureRecoveryReopensCommonSourceForgery :
    authorized "Recovered" hotWallet singleSourceForgery = true := by native_decide
theorem disguisedAdminChangeBlocked :
    authorized "Integrated" hotWallet disguisedAdminChange = false := by native_decide
theorem commonSourceAdminForgeryStillAllows :
    authorized "Integrated" hotWallet singleSourceAdminForgery = true := by native_decide
theorem incidentFreezeBlocksAdminForgery :
    authorized "Incident" hotWallet singleSourceAdminForgery = false := by native_decide

def rootsValidated : Bool :=
  ["Backend", "Intent", "Risk", "Ledger", "Signer", "Integrated",
    "Incident", "Recovered"].all fun root =>
      (CedarPooSpec.PolicyJson.publish model root schema).isOk
theorem rootsValidatedFully : rootsValidated = true := by native_decide

def freezeRevision : Revision :=
  (model.compileRevision "Integrated" "Incident").toOption.get (by native_decide)
theorem freezeLocal :
    freezeRevision.changedPolicyIds = [incidentFreeze.id] ∧
    freezeRevision.freshPolicies = [incidentFreeze] := by native_decide
def recoveryRevision : Revision :=
  (model.compileRevision "Incident" "Recovered").toOption.get (by native_decide)
theorem recoveryLocal :
    recoveryRevision.changedPolicyIds = [incidentFreeze.id] ∧
    recoveryRevision.freshPolicies = [] := by native_decide
theorem recoveryRestoresIntegrated :
    (model.compile "Recovered" == model.compile "Integrated") = true := by native_decide

end LambdaEpisteme.ExchangeSigning
