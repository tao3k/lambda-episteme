;;; -*- Gerbil -*-
;;; Atomic fixture root for t/governance/...
(import :poo-flow/modules/governance/interface
        :poo-flow/lambda-episteme/modules/diataxis/interface
        :poo-flow/lambda-episteme/modules/decision-kind/interface)
(export governance-test-fixtures-loaded?)
(def governance-test-fixtures-loaded? #t)
