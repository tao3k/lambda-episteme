;;; NPR 7150.2D project/institution baseline policy construction.
(import (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/contribution/model
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        (only-in :std/srfi/1 filter))

(export nasa-stage-policy nasa-baseline-policy)

(def (nasa-stage-policy id requirements-value scope: (scope-value 'project))
  (let (result
        (poo-flow-check-model
         SdlcStagePolicy
         (.o (:: @ (poo-flow-model-prototype SdlcStagePolicy))
             identity: id assessment-scope: scope-value
             requirements: requirements-value)))
    (when (equal? id "unstarted")
      (error "reserved lifecycle stage"))
    (for-each
     (lambda (requirement-id)
       (nasa-requirement-by-id requirement-id)
       (unless (eq? (eq? (nasa-rule-mode requirement-id) 'institutional)
                    (eq? scope-value 'institution))
         (error "NASA stage mixes project and institutional duties"
                requirement-id)))
     requirements-value)
    result))

(def (nasa-baseline-policy id scope: (scope-value 'project))
  (nasa-stage-policy
   id
   (map (lambda (row) (.ref row 'identity))
        (filter
         (lambda (row)
           (eq? (eq? (nasa-rule-mode (.ref row 'identity)) 'institutional)
                (eq? scope-value 'institution)))
         nasa-requirement-catalog))
   scope: scope-value))
