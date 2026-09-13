;;; A complete safety measurement workflow with host-owned authentication.
(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-review
        :lambda-episteme/modules/sdlc/standards/nasa-structured
        :lambda-episteme/modules/sdlc/standards/nasa-lifecycle
        (only-in :std/srfi/1 append-map))
(export nasa-safety-gate-example)
(def (nasa-safety-gate-example artifact-digest coverage complexity)
  (let* ((project (sdlc-project "example-flight" "baseline-1" "flight-software" #t))
         (context (.o safety-critical?: #t health-medical?: #f))
         (policy (nasa-stage-policy "safety-review" '("SWE-219" "SWE-220")))
         (inventory (nasa-safety-inventory "component-inventory" project artifact-digest
                      (list (nasa-safety-component "controller" project #t coverage complexity))))
         (evidence
          (append-map (lambda (id)
                        (map (lambda (c)
                               (nasa-verifiable-evidence
                                (nasa-criterion-evidence (.ref c 'identity) project id (.ref c 'identity) "example-reviewer" 'pass)
                                artifact-digest)) (nasa-requirement-criteria id))) (.ref policy 'requirements))))
    (.o verification-requests:
        (append (list (nasa-context-request project 'a context) (nasa-inventory-request inventory 'a))
                (map nasa-evidence-request evidence))
        evaluate:
        (lambda (adapter receipts now)
          (nasa-transition (nasa-lifecycle-start project) (list policy) "safety-review"
                           project 'a context evidence adapter receipts now inventories: (list inventory))))))
