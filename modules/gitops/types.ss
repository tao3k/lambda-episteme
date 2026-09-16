;;; -*- Gerbil -*-
;;; GitOps uses gerbil-poo Class descriptors for data and a reusable Type trait
;;; for environment Profile behavior.
(import :clan/poo/object :clan/poo/mop :clan/poo/type :clan/poo/number
        :clan/poo/brace)
(export NonEmptyString GitOpsEvent GitOpsCheckConclusion
        GitOpsChange GitOpsCheck GitOpsDecision
        gitops-profile? gitops-change? gitops-check? gitops-decision?)

(define-type (NonEmptyString @ String)
  .element?: (lambda (value)
               (and (string? value) (> (string-length value) 0))))
(def GitOpsEvent
  (Enum push pull-request workflow-dispatch reconciliation))
(def GitOpsCheckConclusion
  (Enum success failure cancelled pending skipped))

(define-type (GitOpsChange @ Class.)
  slots: =>.+
  {provider: {type: Symbol}
   event: {type: GitOpsEvent}
   repository: {type: NonEmptyString}
   revision: {type: NonEmptyString}
   source-ref: {type: NonEmptyString}
   target-ref: {type: NonEmptyString}
   pull-request: {type: (Or False UInt)}})
(define-type (GitOpsCheck @ Class.)
  slots: =>.+
  {name: {type: Symbol}
   repository: {type: NonEmptyString}
   revision: {type: NonEmptyString}
   conclusion: {type: GitOpsCheckConclusion}})
(define-type (GitOpsDecision @ Class.)
  slots: =>.+
  {repository: {type: NonEmptyString}
   revision: {type: NonEmptyString}
   profile: {type: Symbol}
   accepted: {type: Bool}
   next-profile: {type: Symbol}
   environment: {type: Symbol}
   required-checks: {type: (List Symbol)}
   standards: {type: (List Symbol)}
   missing-checks: {type: (List Symbol)}
   failed-checks: {type: (List Symbol)}
   stale-checks: {type: (List Symbol)}
   reasons: {type: (List Symbol)}})

(def (gitops-profile? value)
  (and (object? value) (.slot? value 'gitops-profile?)
       (.ref value 'gitops-profile?)))
(def (gitops-change? value) (element? GitOpsChange value))
(def (gitops-check? value) (element? GitOpsCheck value))
(def (gitops-decision? value) (element? GitOpsDecision value))
