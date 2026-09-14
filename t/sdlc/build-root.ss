;;; -*- Gerbil -*-
;;; Atomic fixture root for t/sdlc/...
(import :poo-flow/lambda-episteme/t/sdlc/support/inventories
        :poo-flow/lambda-episteme/user-interface/config
        :poo-flow/lambda-episteme/user-interface/scenarios/github-gitops
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-certification)
(export sdlc-test-fixtures-loaded?)
(def sdlc-test-fixtures-loaded? #t)
