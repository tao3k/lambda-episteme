;;; Pure lifecycle decisions consume receipts from an explicit trusted boundary.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        :poo-flow/src/module-system/contribution/model
        :poo-flow/src/module-system/contribution/verification
        :poo-flow/lambda-episteme/modules/sdlc/types
        (only-in :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-policy
                 nasa-stage-policy
                 nasa-baseline-policy)
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-review
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-structured
        (only-in :std/srfi/1 every any filter find delete-duplicates append-map take))
(export nasa-stage-policy nasa-baseline-policy nasa-context-request nasa-evidence-request
        nasa-verifiable-evidence nasa-verification-adapter nasa-stage-gate nasa-inventory-request
        nasa-lifecycle-start nasa-lifecycle-rebase nasa-transition)
(def context-keys
  '(safety-critical? mission-critical? ivv-required? ivv-performed?
    reaching-kdp-a? category-1? category-2? payload-risk-a-or-b?
    mdaa-selected-ivv? approved-tailoring-exists? reused-component?
    auto-generated-code? nasa-class-d-payload? communications-capable?
    flight-qualification-tools? loaded-behavior-inputs? embedded-reused-component?
    joint-audit? health-medical?))
(def (slots value names) (map (lambda (name) (.ref value name)) names))
(def (bound? value project)
  (equal? (slots value '(subject revision scope)) (slots project '(subject revision scope))))
(def (sha256? value)
  (and (string? value) (= (string-length value) 64)
       (every (lambda (c) (or (char<=? #\0 c #\9) (char<=? #\a c #\f))) (string->list value))))
(def (nasa-verifiable-evidence evidence digest-value)
  (unless (and (sdlc-criterion-evidence? evidence) (sha256? digest-value))
    (error "verifiable NASA evidence requires a SHA-256 artifact digest"))
  (.o (:: @ evidence) artifact-digest: digest-value))
(def (request project purpose-value facts-value)
  (poo-flow-check-model SdlcVerificationRequest
    (.o (:: @ (poo-flow-model-prototype SdlcVerificationRequest))
        subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
        purpose: purpose-value facts: facts-value)))
(def (nasa-context-request project class-value context-value)
  (unless (and (sdlc-project? project) (object? context-value) (memq class-value '(a b c d e f)))
    (error "invalid NASA context request"))
  (request project 'classification-and-context
    (.o software-class: class-value complete?: (.ref project 'complete?) context: context-value)))
(def (nasa-evidence-request evidence)
  (unless (and (sdlc-criterion-evidence? evidence) (.slot? evidence 'artifact-digest)
               (sha256? (.ref evidence 'artifact-digest)))
    (error "NASA evidence is not bound to artifact bytes"))
  (request evidence 'criterion-content evidence))
(def (nasa-inventory-request inventory class-value)
  (unless (and (or (sdlc-trace-inventory? inventory) (sdlc-safety-inventory? inventory))
               (memq class-value '(a b c d e f))) (error "invalid NASA inventory request"))
  (request inventory 'structured-inventory (.o software-class: class-value inventory-value: inventory)))
(def (request-snapshot value)
  (unless (sdlc-verification-request? value) (error "invalid NASA verification request"))
  (let* ((facts-value (.ref value 'facts))
         (payload
          (case (.ref value 'purpose)
            ((structured-inventory)
             (let (inventory (.ref facts-value 'inventory-value))
               (unless (and (bound? inventory value) (memq (.ref facts-value 'software-class) '(a b c d e f)))
                 (error "malformed inventory verification request"))
               (list (.ref facts-value 'software-class) (nasa-inventory-snapshot inventory))))
            ((criterion-content)
             (unless (and (sdlc-criterion-evidence? facts-value) (bound? facts-value value)
                          (.slot? facts-value 'artifact-digest) (sha256? (.ref facts-value 'artifact-digest)))
               (error "malformed criterion verification request"))
             (slots facts-value '(identity standard requirement criterion source-digest producer outcome artifact-digest)))
            ((tailoring-decision)
             (let ((packet (.ref facts-value 'packet)) (records (.ref facts-value 'records)))
               (unless (and (sdlc-tailoring-packet? packet) (bound? packet value)
                            (list? records) (every sdlc-authority-attestation? records))
                 (error "malformed tailoring verification request"))
               (list (slots packet '(identity standard requirement rationale risk mitigations risk-acceptance archived-matrix))
                     (map (lambda (record)
                            (slots record '(identity subject revision scope standard requirement request authority signer record decision))) records)
                     (request-snapshot (.ref facts-value 'context-request)))))
            ((classification-and-context)
             (let (context-value (.ref facts-value 'context))
               (list (.ref facts-value 'software-class) (.ref facts-value 'complete?)
                 (map (lambda (key)
                        (let (v (if (.slot? context-value key) (.ref context-value key) 'unknown))
                          (unless (or (boolean? v) (eq? v 'unknown)) (error "invalid NASA context value" key))
                          (list key v))) context-keys)))))))
    (call-with-output-string
      (lambda (port)
        (write (list 'nasa-verification-v1 (.ref value 'purpose)
                     (slots value '(subject revision scope)) payload
                     (slots nasa-catalog-source-digests '(chapter2 chapter3 chapter4 chapter5 chapter6 appendix-c))) port)))))
(def (nasa-verification-adapter id operation)
  (poo-flow-verification-adapter id operation request-snapshot))
(def (verified? admission value)
  (poo-flow-verification-admission-valid? admission value))
(def (nasa-stage-gate policy project class-value context evidence adapter receipts now
                         tailorings: (tailoring-values '()) inventories: (inventory-values '()))
  (unless (and (sdlc-stage-policy? policy) (list? receipts) (list? tailoring-values)
               (list? inventory-values)
               (every (lambda (i) (or (sdlc-trace-inventory? i) (sdlc-safety-inventory? i))) inventory-values)
               (exact-integer? now) (>= now 0)) (error "invalid stage gate inputs"))
  (let* ((report ((if (eq? (.ref policy 'assessment-scope) 'institution) nasa-assess-institution nasa-assess-project) class-value project context evidence))
         (admission (poo-flow-verification-admission adapter receipts now))
         (selected (map (lambda (id)
                          (or (find (lambda (r) (equal? (.ref r 'requirement) id)) (.ref report 'requirements))
                              (error "unknown stage requirement" id))) (.ref policy 'requirements)))
         (context-ok? (verified? admission (nasa-context-request project class-value context)))
         (failed (filter (lambda (e)
                           (and (bound? e project) (eq? (.ref e 'outcome) 'fail)
                                (member (.ref e 'requirement) (.ref policy 'requirements))
                                (equal? (.ref e 'source-digest)
                                        (.ref (car (nasa-requirement-criteria (.ref e 'requirement))) 'source-digest)))) evidence))
         (unverified
          (append-map
           (lambda (row)
             (if (eq? (.ref row 'status) 'evidence-present)
               (filter
                (lambda (criterion)
                  (not (any
                        (lambda (e)
                          (and (bound? e project) (equal? (.ref e 'criterion) criterion)
                               (equal? (.ref e 'source-digest)
                                       (.ref (car (.ref row 'criteria)) 'source-digest))
                               (eq? (.ref e 'outcome) 'pass) (.slot? e 'artifact-digest)
                               (sha256? (.ref e 'artifact-digest))
                               (verified? admission (nasa-evidence-request e)))) evidence)))
                (map (lambda (c) (.ref c 'identity)) (.ref row 'criteria))) '())) selected))
         (relieved?
          (lambda (row)
            (and
             (memq (.ref row 'status)
                   '(condition-not-triggered missing-evidence unknown))
             (any
              (lambda (submission)
                (and
                 (sdlc-verification-request? submission)
                 (eq? (.ref submission 'purpose) 'tailoring-decision)
                 (let* ((facts (.ref submission 'facts))
                        (packet (.ref facts 'packet)))
                   (and
                    (equal? (.ref packet 'requirement)
                            (.ref row 'requirement))
                    (bound? packet project)
                    (verified?
                     admission
                     (nasa-tailoring-verification-request
                      project class-value context packet
                      (.ref facts 'records)))))))
              tailoring-values))))
         (blocked (filter (lambda (r) (and (not (memq (.ref r 'status) '(evidence-present not-invoked)))
                                          (not (relieved? r)))) selected))
         (structured-values
          (map (lambda (row)
                 (let* ((id (.ref row 'requirement))
                        (candidates (filter (lambda (i) (nasa-inventory-for? i id)) inventory-values)))
                   (if (not (= (length candidates) 1))
                     (.o requirement: id status: 'inventory-required passed?: #f)
                     (let* ((inventory (car candidates))
                            (review (nasa-structured-review project class-value id inventory))
                            (receipt-ok? (verified? admission (nasa-inventory-request inventory class-value))))
                       (.o (:: @ review) verified?: receipt-ok?
                           passed?: (and (.ref review 'passed?) receipt-ok?)
                           status: (if (.ref review 'passed?)
                                     (if receipt-ok? 'structured-checks-passed 'inventory-verification-required)
                                     (.ref review 'status)))))))
               (filter (lambda (r) (and (nasa-structured-requirement? (.ref r 'requirement))
                                        (eq? (.ref r 'status) 'evidence-present))) selected)))
         (status-value (cond ((not context-ok?) 'context-verification-required)
                             ((not (.ref project 'complete?)) 'incomplete-scope)
                             ((pair? failed) 'requirements-blocked)
                             ((pair? blocked) 'requirements-blocked)
                             ((pair? unverified) 'content-verification-required)
                             ((not (every (lambda (r) (.ref r 'passed?)) structured-values)) 'structured-verification-required)
                             (else 'stage-admitted))))
    (.o stage: (.ref policy 'identity) status: status-value
        assessment-scope: (.ref policy 'assessment-scope) requirements: (.ref policy 'requirements)
        unverified-criteria: unverified blocked-requirements: blocked
        structured-reviews: structured-values
        reported-failures: failed
        admitted?: (eq? status-value 'stage-admitted) release-authorized?: #f)))
(def (make-state project stage-value)
  (poo-flow-check-model SdlcLifecycleState
    (.o (:: @ (poo-flow-model-prototype SdlcLifecycleState))
        subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
        stage: stage-value)))
(def (nasa-lifecycle-start project)
  (unless (sdlc-project? project) (error "invalid lifecycle snapshot"))
  (make-state project "unstarted"))
(def (nasa-lifecycle-rebase previous project)
  (unless (and (sdlc-lifecycle-state? previous) (sdlc-project? project)
               (equal? (.ref previous 'subject) (.ref project 'subject))
               (equal? (.ref previous 'scope) (.ref project 'scope))
               (not (equal? (.ref previous 'revision) (.ref project 'revision))))
    (error "rebase requires a new revision in the same subject and scope"))
  (make-state project "unstarted"))
(def (nasa-transition previous policies target project class-value context evidence adapter receipts now
                         tailorings: (tailoring-values '()) inventories: (inventory-values '()))
  (unless (and (sdlc-lifecycle-state? previous) (sdlc-project? project) (bound? previous project)
               (list? policies) (pair? policies) (every sdlc-stage-policy? policies))
    (error "invalid lifecycle transition"))
  (let* ((names (map (lambda (p) (.ref p 'identity)) policies))
         (index (let loop ((names names) (n 0))
                  (cond ((null? names) (error "unknown target stage" target))
                        ((equal? (car names) target) n) (else (loop (cdr names) (+ n 1)))))))
    (unless (every (lambda (p) (eq? (.ref p 'assessment-scope) (.ref (car policies) 'assessment-scope))) policies)
      (error "lifecycle cannot mix project and institutional policies"))
    (unless (= (length names) (length (delete-duplicates names equal?))) (error "duplicate lifecycle stage"))
    (unless (equal? (.ref previous 'stage) (if (= index 0) "unstarted" (list-ref names (- index 1))))
      (error "transition skips a configured stage"))
    ;; Recheck all preceding obligations too: a stale or forged stage label
    ;; cannot bypass earlier evidence requirements. Receipts are checked now.
    (let* ((requirements (delete-duplicates (append-map (lambda (p) (.ref p 'requirements)) (take policies (+ index 1))) equal?))
           (gate-value (nasa-stage-gate (nasa-stage-policy target requirements scope: (.ref (car policies) 'assessment-scope)) project class-value context evidence adapter receipts now tailorings: tailoring-values inventories: inventory-values)))
      (.o gate: gate-value advanced?: (.ref gate-value 'admitted?)
          state: (if (.ref gate-value 'admitted?) (make-state project target) previous)
          release-authorized?: #f))))


(export nasa-tailoring-verification-request)
(def (nasa-tailoring-verification-request project class-value context packet-value record-values)
  (let (review (nasa-tailoring-review project class-value context packet-value record-values))
    (unless (eq? (.ref review 'status) 'authority-verification-required)
      (error "tailoring records are not ready for authority verification" (.ref review 'status)))
    (request project 'tailoring-decision
      (.o packet: packet-value records: record-values
          context-request: (nasa-context-request project class-value context)))))
