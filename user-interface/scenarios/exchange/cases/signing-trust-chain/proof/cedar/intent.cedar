// Generated from Lean-POO. Cedar assigns new IDs when parsing this text.
// POO policy ID: backend-sign-approval
permit(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  ((context.backendApproved) && ((context.candidateDigest) == (context.intentDigest))) && ((context.candidateOperation) == (context.intentOperation))
};
