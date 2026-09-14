;;; Pure review preparation over explicitly supplied facts; no graph execution
;;; or authority authentication. A ready packet is never a compliance decision.
(import (only-in :clan/poo/object .o .ref .slot?)
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/funs
        (only-in :std/srfi/1 every filter any delete-duplicates))
(export sdlc-project sdlc-obligation sdlc-evidence sdlc-tailoring-request
        sdlc-review)

(def (same? left right slots)
  (every (lambda (slot) (equal? (.ref left slot) (.ref right slot))) slots))
(def (sdlc-review profile project obligation evidence requests)
  (unless (and (sdlc-profile? profile) (sdlc-project? project)
               (sdlc-obligation? obligation)
               (list? evidence) (every sdlc-evidence? evidence)
               (list? requests) (every sdlc-tailoring-request? requests))
    (error "invalid SDLC review facts"))
  (let ((ids (map (lambda (e) (.ref e 'identity)) evidence)))
    (unless (= (length ids) (length (delete-duplicates ids equal?)))
      (error "ambiguous SDLC evidence identity")))
  (let* ((known? (any (lambda (standard)
                       (and (equal? (.ref standard 'identity) (.ref obligation 'standard))
                            (any (lambda (r)
                                   (and (.slot? r 'identity)
                                        (equal? (.ref r 'identity) (.ref obligation 'requirement))))
                                 (.ref standard 'requirements))))
                     (.ref profile 'standards)))
         (related (filter (lambda (e) (and (same? e project '(subject scope))
                                           (same? e obligation '(standard requirement)))) evidence))
         (current (filter (lambda (e) (same? e project '(revision))) related))
         (tailored? (any (lambda (r) (and (same? r project '(subject revision))
                                         (same? r obligation '(standard requirement)))) requests))
         (status-value
          (cond ((not known?) 'unmapped-obligation)
                ((not (eq? (.ref obligation 'applicability) 'applicable)) 'applicability-review-required)
                ((any (lambda (e) (eq? (.ref e 'outcome) 'fail)) current) 'reported-failure)
                (tailored? 'tailoring-review-required)
                ((pair? current) 'evidence-present)
                ((pair? related) 'stale-evidence)
                ((.ref project 'complete?) 'missing-evidence)
                (else 'unknown))))
    (.o kind: 'sdlc.review-packet status: status-value
        subject: (.ref project 'subject) revision: (.ref project 'revision)
        standard: (.ref obligation 'standard) requirement: (.ref obligation 'requirement)
        evidence-identities: (map (lambda (e) (.ref e 'identity)) current)
        compliance: 'not-evaluated authority: 'not-verified runtime-executed?: #f)))
