(import :poo-flow/lambda-episteme/modules/gitops/interface)
(export production)
(define-gitops-profile production OpenGitOpsV1Profile
  environment: 'production
  event: 'workflow-dispatch
  target-ref: "production"
  required-checks: '(release-authority signed-provenance)
  reconciliation: 'protected
  next-profile: 'complete)
