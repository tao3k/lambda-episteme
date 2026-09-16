(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export dev)
(define-gitops-profile dev OpenGitOpsV1Profile
  environment: 'dev
  event: 'pull-request
  target-ref: "develop"
  required-checks: '(commit-policy build unit-test)
  reconciliation: 'automatic
  next-profile: 'staging)
