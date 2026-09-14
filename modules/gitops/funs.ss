;;; -*- Gerbil -*-
;;; Pure evaluator plus its checked default method bundle.
(import (only-in :clan/poo/object .ref .slot?)
        (only-in :clan/poo/mop .new validate)
        (only-in :std/srfi/1 every filter find)
        (only-in :poo-flow/src/core/funcs
                 poo-flow-make-value-index poo-flow-value-index-put!
                 poo-flow-value-index-ref)
        :poo-flow/src/module-system/poo-clos/interface
        :poo-flow/lambda-episteme/modules/gitops/types
        :poo-flow/lambda-episteme/modules/gitops/objects)
(export GitOpsDefaultEvaluationMethod GitOpsDefaultEvaluationMethods
        gitops-evaluate-default)

(def (composition-gitops-profiles composition)
  (filter gitops-profile? (.ref composition 'profiles)))
(def (composition-standard-names composition)
  (map (lambda (profile) (.ref profile 'name))
       (filter (lambda (profile)
                 (and (.slot? profile 'role)
                      (eq? (.ref profile 'role) 'standard)))
               (.ref composition 'profiles))))
(def (check-index checks)
  (let (index (poo-flow-make-value-index))
    (for-each
     (lambda (check)
       (validate GitOpsCheck check)
       (let-values (((present? previous)
                     (poo-flow-value-index-ref index (.ref check 'name))))
         (when present? (error "duplicate GitOps check" (.ref check 'name)))
         (poo-flow-value-index-put! index (.ref check 'name) check)))
     checks)
    index))
(def (gitops-profile-decision profile standards change checks)
  (let* ((required (.ref profile 'required-checks))
         (index (check-index checks))
         (missing '()) (failed '()) (stale '()))
    (for-each
     (lambda (name)
       (let-values (((present? check) (poo-flow-value-index-ref index name)))
         (cond ((not present?) (set! missing (cons name missing)))
               ((or (not (equal? (.ref check 'repository) (.ref change 'repository)))
                    (not (equal? (.ref check 'revision) (.ref change 'revision))))
                (set! stale (cons name stale)))
               ((not (eq? (.ref check 'conclusion) 'success))
                (set! failed (cons name failed))))))
     (append required standards))
    (let (accepted? (and (null? missing) (null? failed) (null? stale)))
      (validate GitOpsDecision
        (.new GitOpsDecision
          repository: (.ref change 'repository) revision: (.ref change 'revision)
          profile: (.ref profile 'name) accepted: accepted?
          next-profile: (.ref profile 'next-profile)
          environment: (.ref profile 'environment)
          required-checks: required standards: standards
          missing-checks: (reverse missing) failed-checks: (reverse failed)
          stale-checks: (reverse stale)
          reasons: (append (if (null? missing) '() '(required-check-missing))
                           (if (null? failed) '() '(required-check-failed))
                           (if (null? stale) '() '(check-revision-mismatch))))))))
(def (gitops-unmatched-decision change)
  (validate GitOpsDecision
    (.new GitOpsDecision
      repository: (.ref change 'repository) revision: (.ref change 'revision)
      profile: 'unmatched accepted: #f next-profile: 'none environment: 'none
      required-checks: '() standards: '() missing-checks: '()
      failed-checks: '() stale-checks: '()
      reasons: '(no-gitops-profile-matches-change))))
(def (gitops-evaluate-default composition change checks)
  (validate GitOpsChange change)
  (unless (and (list? checks) (every gitops-check? checks))
    (error "invalid GitOps checks" checks))
  (let (profile
        (find (lambda (candidate)
                (gitops-profile-matches? candidate change))
              (composition-gitops-profiles composition)))
    (if profile
      (gitops-profile-decision
       profile (composition-standard-names composition) change checks)
        (gitops-unmatched-decision change))))

(def GitOpsDefaultEvaluationMethod
  (poo-clos-method
   'gitops/default-evaluation
   (list (poo-clos-class-specializer GitOpsEvaluator)
         (poo-clos-any-specializer) (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _evaluator composition change checks)
     (gitops-evaluate-default composition change checks))))
(.defmethod-bundle GitOpsDefaultEvaluationMethods
  GitOpsEvaluationProtocol GitOpsDefaultEvaluationMethod)
(poo-clos-compose-method-bundle
 GitOpsEvaluationGeneric GitOpsDefaultEvaluationMethods)
