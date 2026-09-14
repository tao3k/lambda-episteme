;;; -*- Gerbil -*-
;;; Thin one-pattern projection to the ordinary native profile constructor.
(import :clan/poo/object
        :clan/poo/mop
        :poo-flow/lambda-episteme/modules/gitops/types
        :poo-flow/lambda-episteme/modules/gitops/objects)
(export define-gitops-profile)
(defrule (define-gitops-profile name base environment-value event-value
                                target-ref-value required-checks-value
                                reconciliation-value next-profile-value)
  (define-type (name @ base)
    name: 'name
    environment: 'environment-value
    event: 'event-value
    target-ref: target-ref-value
    required-checks: 'required-checks-value
    reconciliation: 'reconciliation-value
    next-profile: 'next-profile-value
    .matches?:
    (lambda (change)
      (and (gitops-change? change)
           (eq? (.ref change 'event) 'event-value)
           (equal? (.ref change 'target-ref) target-ref-value)))))
