;;; -*- Gerbil -*-
;;; Atomic fixture root for t/governance/...
(import :poo-flow/lambda-episteme/governance/interface
        :poo-flow/lambda-episteme/modules/diataxis/interface
        :poo-flow/lambda-episteme/modules/adr/interface
        :poo-flow/lambda-episteme/modules/decision-kind/interface)
(export governance-test-fixtures-loaded?)
(def governance-test-fixtures-loaded? #t)
