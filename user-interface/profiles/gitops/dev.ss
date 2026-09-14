(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export dev)
(define-gitops-profile dev OpenGitOpsV1Profile dev pull-request "develop"
  (commit-policy build unit-test) automatic staging)
