;;; Deterministic local checks over authenticated inventory projections.
(import (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/contribution/model
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/funs
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-review
        (only-in :std/srfi/1 every filter))
(export nasa-safety-inventory nasa-trace-inventory nasa-structured-requirement?
        nasa-inventory-for? nasa-inventory-snapshot nasa-structured-review)
(def (bound? value project)
  (every (lambda (s) (equal? (.ref value s) (.ref project s))) '(subject revision scope)))
(def (base class id project digest-value complete-value)
  (unless (sdlc-project? project) (error "invalid inventory project"))
  (.o (:: @ (poo-flow-model-prototype class)) identity: id
      subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
      artifact-digest: digest-value complete?: complete-value))
(def (nasa-safety-inventory id project digest-value components-value complete?: (complete-value #t))
  (poo-flow-check-model SdlcSafetyInventory
    (.o (:: @ (base SdlcSafetyInventory id project digest-value complete-value)) components: components-value)))
(def (nasa-trace-inventory id project digest-value nodes-value edges-value complete?: (complete-value #t))
  (poo-flow-check-model SdlcTraceInventory
    (.o (:: @ (base SdlcTraceInventory id project digest-value complete-value)) nodes: nodes-value edges: edges-value)))
(def (nasa-structured-requirement? id)
  (and (member id '("SWE-052" "SWE-219" "SWE-220")) #t))
(def (nasa-inventory-for? inventory id)
  (if (equal? id "SWE-052") (sdlc-trace-inventory? inventory)
      (and (member id '("SWE-219" "SWE-220")) (sdlc-safety-inventory? inventory) #t)))
(def (project-slots value names) (map (lambda (name) (.ref value name)) names))
(def (nasa-inventory-snapshot inventory)
  (unless (or (sdlc-safety-inventory? inventory) (sdlc-trace-inventory? inventory))
    (error "invalid NASA inventory"))
  (list (project-slots inventory '(identity subject revision scope artifact-digest complete?))
        (if (sdlc-safety-inventory? inventory)
          (list 'safety (map (lambda (c) (project-slots c '(identity subject revision scope safety-critical? mcdc-percent cyclomatic-complexity)))
                             (.ref inventory 'components)))
          (list 'trace (map (lambda (n) (project-slots n '(identity subject revision scope category))) (.ref inventory 'nodes))
                      (map (lambda (e) (project-slots e '(identity subject revision scope source target relation))) (.ref inventory 'edges))))))
(def (nasa-structured-review project class-value id inventory)
  (unless (and (sdlc-project? project) (memq class-value '(a b c d e f)) (nasa-inventory-for? inventory id))
    (error "invalid NASA structured review inputs"))
  (let* ((records (if (sdlc-safety-inventory? inventory) (.ref inventory 'components)
                    (append (.ref inventory 'nodes) (.ref inventory 'edges))))
         (fresh? (and (bound? inventory project) (every (lambda (r) (bound? r project)) records)))
         (complete-value (and (.ref project 'complete?) (.ref inventory 'complete?)))
         (details-value
          (if (sdlc-safety-inventory? inventory)
            (nasa-safety-review project (.ref inventory 'components))
            (map (lambda (rule) (sdlc-trace-review project rule (.ref inventory 'nodes) (.ref inventory 'edges)))
                 (nasa-trace-rules class-value))))
         (local-ok?
          (if (sdlc-safety-inventory? inventory)
            (and (eq? (.ref details-value 'inventory) 'supplied-complete)
                 (every (lambda (c) (eq? (.ref c (if (equal? id "SWE-219") 'coverage 'complexity)) 'threshold-met))
                        (.ref details-value 'components)))
            (and (pair? details-value) (every (lambda (r) (eq? (.ref r 'status) 'trace-evidence-present)) details-value))))
         (status-value (cond ((not fresh?) 'stale-inventory)
                             ((not complete-value) 'incomplete-inventory)
                             ((not local-ok?) 'structured-requirements-blocked)
                             (else 'structured-checks-passed))))
    (.o requirement: id inventory-identity: (.ref inventory 'identity) status: status-value
        details: details-value passed?: (eq? status-value 'structured-checks-passed)
        release-authorized?: #f)))
