(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export production)
(define-gitops-profile production OpenGitOpsV1Profile production workflow-dispatch
  "production" (release-authority signed-provenance) protected complete)
