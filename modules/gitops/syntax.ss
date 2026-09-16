;;; -*- Gerbil -*-
;;; Thin one-pattern projection to an ordinary POO Profile declaration.
(import (only-in :clan/poo/object .def .ref)
        :poo-flow/lambda-episteme/modules/gitops/types
        :poo-flow/lambda-episteme/modules/gitops/objects)
(export define-gitops-profile)
(defrule (define-gitops-profile profile-name base
           environment: environment-value
           event: event-value
           target-ref: target-ref-value
           required-checks: required-checks-value
           reconciliation: reconciliation-value
           next-profile: next-profile-value)
  (.def (profile-name @ base)
    (name 'profile-name)
    (environment environment-value)
    (event event-value)
    (target-ref target-ref-value)
    (required-checks required-checks-value)
    (reconciliation reconciliation-value)
    (next-profile next-profile-value)
    (.matches?
     (lambda (change)
       (and (gitops-change? change)
            (eq? (.ref change 'event) event-value)
            (equal? (.ref change 'target-ref) target-ref-value))))))
