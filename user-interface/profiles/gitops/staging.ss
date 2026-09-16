(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export staging)
(define-gitops-profile staging OpenGitOpsV1Profile
  environment: 'staging
  event: 'push
  target-ref: "develop"
  required-checks: '(integration-test security-review)
  reconciliation: 'automatic
  next-profile: 'production)
