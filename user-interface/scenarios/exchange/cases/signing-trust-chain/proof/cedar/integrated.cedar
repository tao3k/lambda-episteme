// Generated from Lean-POO. Cedar assigns new IDs when parsing this text.
// POO policy ID: backend-sign-approval
permit(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  ((context.backendApproved) && ((context.candidateDigest) == (context.intentDigest))) && ((context.candidateOperation) == (context.intentOperation))
};

// POO policy ID: independent-ledger-veto
forbid(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  (!(context.ledgerReserved)) || (!((context.candidateDigest) == (context.ledgerDigest)))
};

// POO policy ID: independent-risk-veto
forbid(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  (!(context.riskApproved)) || (!((context.candidateDigest) == (context.riskDigest)))
};

// POO policy ID: signer-byte-and-epoch-veto
forbid(
  principal == Signer::"signer-a",
  action == Action::"sign-transfer",
  resource
) when {
  ((!((context.candidateDigest) == (context.displayDigest))) || ((!(context.nonceFresh)) || (!((context.walletEpoch) == (resource.epoch))))) || (((context.candidateOperation) == "admin-change") && (!(context.adminApproved)))
};
