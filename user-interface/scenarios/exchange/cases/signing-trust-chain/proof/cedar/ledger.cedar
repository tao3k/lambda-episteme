// Generated from Lean-POO. Cedar assigns new IDs when parsing this text.
// POO policy ID: backend-sign-approval
permit(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  context.backendApproved
};

// POO policy ID: independent-ledger-veto
forbid(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  (!(context.ledgerReserved)) || (!((context.candidateDigest) == (context.ledgerDigest)))
};
