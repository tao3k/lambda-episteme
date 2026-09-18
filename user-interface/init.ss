;;; -*- Gerbil -*-
;;; Doom-like Lambda entry: enable Modules and flags only.

(import :poo-flow/src/user-interface/init-declaration-syntax)

(poo-flow!
 :workflow
 (funflow
  (+cicd
   (checks +parallel +typed-receipts)
   (release +manual-gate)
   (runtime +manifest-handoff)))
 :custom
 (ontology))
