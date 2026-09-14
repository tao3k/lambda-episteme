;;; -*- Gerbil -*-
;;; Final User Composition: provider + environment Profiles + SDLC Standard.
(import :poo-flow/src/user-interface/config-discovery-syntax)
(export github-gitops-sdlc)

(use-composition github-gitops-sdlc
  (modules
    (use-module funflow as github
      (profile actions))
    (use-module gitops as delivery
      (profile dev)
      (profile staging)
      (profile production))
    (use-module sdlc as sdlc
      (profile nasa-7150-2d)))
  (compose
    (profile github actions)
    (profiles delivery dev staging production)
    (profile sdlc nasa-7150-2d)))
