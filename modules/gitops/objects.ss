;;; -*- Gerbil -*-
;;; Profile slot dispatch is the normal extension path. CLOS owns the optional
;;; evaluator strategy axis where provider/runtime specializers may combine.
(import :clan/poo/object :clan/poo/mop
        :poo-flow/src/module-system/poo-clos/interface
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/gitops/types)
(export GitOpsEvaluator GitOpsDefaultEvaluator
        GitOpsEvaluationProtocol GitOpsEvaluationGeneric
        OpenGitOpsV1Profile GitOpsModule
        gitops-profile-matches?
        gitops-change gitops-check gitops-evaluate)

(.defgeneric (gitops-profile-matches? profile change)
  slot: .matches?)

(define-type (OpenGitOpsV1Profile @ GitOpsProfile.)
  identity: "open-gitops/v1.0.0"
  owner: 'lambda-episteme
  name: 'open-gitops-v1
  environment: 'unbound
  event: 'reconciliation
  target-ref: "unbound"
  required-checks: '()
  reconciliation: 'continuous
  next-profile: 'complete
  principles: '(declarative versioned-and-immutable pulled-automatically
                 continuously-reconciled)
  source-url: "https://opengitops.dev/"
  runtime-executed: #f)

(def GitOpsEvaluator (poo-clos-class 'gitops/evaluator))
(def GitOpsDefaultEvaluator (poo-clos-make-instance GitOpsEvaluator))
(def GitOpsEvaluationProtocol
  (poo-clos-generic-protocol 'gitops/evaluate))
(def GitOpsEvaluationGeneric
  (poo-clos-generic-function 'gitops-evaluate 4
    protocol: GitOpsEvaluationProtocol))
(def (gitops-evaluate composition change checks)
  (poo-clos-call GitOpsEvaluationGeneric GitOpsDefaultEvaluator
                 composition change checks))

(def GitOpsModule
  (make-contribution
   "lambda-episteme/gitops" "1" "lambda-episteme"
   OpenGitOpsV1Profile '(delivery-governance) '()))
(def (gitops-change provider-value event-value repository-value revision-value
                    source-ref-value target-ref-value pull-request-value)
  (.new GitOpsChange
    provider: provider-value event: event-value repository: repository-value
    revision: revision-value source-ref: source-ref-value
    target-ref: target-ref-value pull-request: pull-request-value))
(def (gitops-check name-value repository-value revision-value conclusion-value)
  (.new GitOpsCheck name: name-value repository: repository-value
        revision: revision-value conclusion: conclusion-value))
