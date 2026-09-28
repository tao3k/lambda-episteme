import SigningTrustChain.SigningValidatedExport

def main (args : List String) : IO Unit := do
  let manifest ← match args with
    | ["validated"] =>
      match LambdaEpisteme.ExchangeSigningValidatedExport.manifest with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    | ["plain"] =>
      match LambdaEpisteme.ExchangeSigningExport.manifest with
      | .ok value => pure value
      | .error message => throw (IO.userError message)
    | _ => throw (IO.userError "expected plain or validated")
  IO.println manifest.compress
