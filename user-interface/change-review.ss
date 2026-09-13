(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface)
(export change-project change-nodes change-edges change-review)
(def change-project (sdlc-project "flight-planner" "baseline-7" "release" #t))
(def change-nodes
  (map (lambda (entry) (sdlc-trace-node (car entry) (cdr entry) change-project))
       '(("requirement" . requirement) ("design" . design) ("code" . code)
         ("verification" . verification) ("unrelated" . verification))))
(def change-edges
  (list (sdlc-trace-edge "r-d" "implements" "requirement" "design" change-project)
        (sdlc-trace-edge "d-c" "implements" "design" "code" change-project)
        (sdlc-trace-edge "c-v" "verifies" "code" "verification" change-project)))
(def (change-review)
  (sdlc-change-impact change-project change-nodes change-edges '("requirement") '("implements" "verifies")))
