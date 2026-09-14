(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export staging)
(define-gitops-profile staging OpenGitOpsV1Profile staging push "develop"
  (integration-test security-review) automatic production)
