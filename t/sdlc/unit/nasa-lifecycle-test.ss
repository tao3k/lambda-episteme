(import :std/test :std/error
        (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/contribution/verification
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-coverage
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-review
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-lifecycle
        (only-in :std/srfi/1 every filter append-map))
(include "../support/inventories.ss")
(def project (sdlc-project "test-flight" "r1" "software" #t))
(def context (.o safety-critical?: #f health-medical?: #f reaching-kdp-a?: #f category-1?: #f))
(def digest (make-string 64 #\a))
(def policy (nasa-stage-policy "planning" '("SWE-013")))
(def record (nasa-verifiable-evidence
             (nasa-criterion-evidence "planning" project "SWE-013" "SWE-013/p1" "test-reviewer" 'pass) digest))
;; A deliberately bounded test double, not a signature/content implementation.
(def (test-verifier value now until)
  (and (equal? (.ref value 'subject) "test-flight")
       (equal? (.ref value 'revision) "r1") (= now 10) (= until 20)
       (case (.ref value 'purpose)
         ((classification-and-context) (eq? (.ref (.ref value 'facts) 'software-class) 'a))
         ((structured-inventory) (equal? (.ref (.ref (.ref value 'facts) 'inventory-value) 'artifact-digest) digest))
         ((criterion-content) (and (equal? (.ref (.ref value 'facts) 'artifact-digest) digest)
                                   (equal? (.ref (.ref value 'facts) 'producer) "test-reviewer")))
         ((tailoring-decision) (equal? (.ref (.ref (.ref value 'facts) 'packet) 'identity) "waiver-test"))
         (else #f))))
(def (adapter) (nasa-verification-adapter "test-only" test-verifier))
(def (context-receipt a) (poo-flow-verify a (nasa-context-request project 'a context) 10 20))
(def (evidence-receipt a) (poo-flow-verify a (nasa-evidence-request record) 10 20))
(def (gate a receipts records (now 11)) (nasa-stage-gate policy project 'a context records a receipts now))
(export nasa-lifecycle-test)
(def nasa-lifecycle-test
  (test-suite "NASA verified lifecycle admission"
  (test-case "all source requirements have complete implementation modes and honest authority boundaries"
    (let ((rows (nasa-implementation-matrix))
          (summary (nasa-implementation-summary)))
      (check-equal? (length rows) 130)
      (for-each (lambda (mode count)
                  (check-equal? (length (filter (lambda (r) (eq? (.ref r 'applicability) mode)) rows)) count))
                '(conditional unconditional institutional) '(19 81 30))
      (check-equal? (every (lambda (r) (eq? (.ref r 'implementation-status) 'implemented)) rows) #t)
      (check-equal? (every (lambda (r) (eq? (.ref r 'compliance-status) 'not-evaluated)) rows) #t)
      (check-equal? (every (lambda (r)
                             (if (memq (.ref r 'stage-inventory-check)
                                       '(required not-applicable)) #t #f))
                           rows) #t)
      (check-equal? (.ref summary 'implemented-count) 130)
      (check-equal? (.ref summary 'implementation-gap-identities) '())
      (check-equal? (.ref summary 'implementation-complete?) #t)
      (check-equal? (.ref summary 'certification) 'not-claimed)
      (check-equal? (nasa-rule-mode "SWE-023") 'conditional)
      (check-equal? (nasa-rule-mode "SWE-013") 'unconditional)
      (check-equal? (nasa-rule-mode "SWE-002") 'institutional)
      (check-exception (nasa-rule-mode "SWE-999") Error?)))
  (test-case "baseline policies explicitly separate all project and institutional duties"
    (check-equal? (length (.ref (nasa-baseline-policy "project") 'requirements)) 100)
    (check-equal? (length (.ref (nasa-baseline-policy "institution" scope: 'institution) 'requirements)) 30)
    (check-exception (nasa-stage-policy "mixed" '("SWE-013" "SWE-002")) Error?)
    (check-exception (nasa-stage-policy "wrong-owner" '("SWE-013") scope: 'institution) Error?)
    (let* ((a (adapter))
           (e (nasa-verifiable-evidence (nasa-criterion-evidence "institution" project "SWE-002" "SWE-002/p1" "test-reviewer" 'pass) digest))
           (receipt (poo-flow-verify a (nasa-evidence-request e) 10 20)))
      (check-equal? (.ref (nasa-stage-gate (nasa-stage-policy "institution" '("SWE-002") scope: 'institution)
                                         project 'a context (list e) a (list (context-receipt a) receipt) 11) 'admitted?) #t)))
  (test-case "claimed pass is insufficient and context is independently verified"
    (let* ((a (adapter)) (c (context-receipt a)) (e (evidence-receipt a)))
      (check-equal? (.ref (gate a '() (list record)) 'status) 'context-verification-required)
      (check-equal? (.ref (gate a (list c) (list record)) 'status) 'content-verification-required)
      (check-equal? (.ref (gate a (list c e) (list record)) 'admitted?) #t)
      (check-equal? (.ref (gate a (list c e) (list record)) 'release-authorized?) #f)
      (check-equal? (.ref (gate a (list c (.o (:: @ e))) (list record)) 'admitted?) #f)
      (check-equal? (.ref (gate a (list c e) (list record) 20) 'admitted?) #f)
      (check-equal? (.ref (gate a (list c e) (list (.o (:: @ record) artifact-digest: (make-string 64 #\b)))) 'admitted?) #f)
      (check-equal? (.ref (gate a (list c e) (list (.o (:: @ record) source-digest: "stale"))) 'admitted?) #f)
      (check-equal? (.ref (nasa-stage-gate policy project 'a (.o (:: @ context) safety-critical?: #t) (list record) a (list c e) 11) 'admitted?) #f)
      (check-equal? (.ref (gate a (list c e) (list record (.o (:: @ record) identity: "failure" outcome: 'fail))) 'status) 'requirements-blocked)
      (poo-flow-revoke-verification! a e)
      (check-equal? (.ref (gate a (list c e) (list record)) 'admitted?) #f)))
  (test-case "all 130 requirements traverse the verifier in their separate baselines"
    (let (all-context
           (.o safety-critical?: #t mission-critical?: #t ivv-required?: #t ivv-performed?: #t
               reaching-kdp-a?: #t category-1?: #t category-2?: #f payload-risk-a-or-b?: #t
               mdaa-selected-ivv?: #t approved-tailoring-exists?: #t reused-component?: #t
               auto-generated-code?: #t nasa-class-d-payload?: #f communications-capable?: #t
               flight-qualification-tools?: #t loaded-behavior-inputs?: #t
               embedded-reused-component?: #t joint-audit?: #t health-medical?: #f))
      (for-each
       (lambda (owner)
         (let* ((a (adapter)) (p (nasa-baseline-policy "baseline" scope: owner))
                (records (append-map
                          (lambda (id)
                            (map (lambda (criterion)
                                   (nasa-verifiable-evidence
                                    (nasa-criterion-evidence (.ref criterion 'identity) project id (.ref criterion 'identity) "test-reviewer" 'pass) digest))
                                 (nasa-requirement-criteria id))) (.ref p 'requirements)))
                (c (poo-flow-verify a (nasa-context-request project 'a all-context) 10 20))
                (inventory-values (if (eq? owner 'project) (test-inventories project 'a digest) '()))
                (receipts (append (list c)
                                  (map (lambda (e) (poo-flow-verify a (nasa-evidence-request e) 10 20)) records)
                                  (map (lambda (i) (poo-flow-verify a (nasa-inventory-request i 'a) 10 20)) inventory-values))))
           (check-equal? (.ref (nasa-stage-gate p project 'a all-context records a receipts 11 inventories: inventory-values) 'status) 'stage-admitted)
           (check-equal? (.ref (nasa-stage-gate p project 'a all-context (cdr records) a receipts 11 inventories: inventory-values) 'admitted?) #f)
           (poo-flow-revoke-verification! a (cadr receipts))
           (check-equal? (.ref (nasa-stage-gate p project 'a all-context records a receipts 11 inventories: inventory-values) 'admitted?) #f)))
       '(project institution))))
  (test-case "a later stage cannot substitute its own evidence for earlier obligations"
    (let* ((a (adapter)) (later (nasa-stage-policy "later" '("SWE-015")))
           (records (map (lambda (c) (nasa-verifiable-evidence
                                      (nasa-criterion-evidence (.ref c 'identity) project "SWE-015" (.ref c 'identity) "test-reviewer" 'pass) digest))
                         (nasa-requirement-criteria "SWE-015")))
           (receipts (cons (context-receipt a) (map (lambda (e) (poo-flow-verify a (nasa-evidence-request e) 10 20)) records)))
           (forged (.o (:: @ (nasa-lifecycle-start project)) stage: "planning")))
      (check-equal? (.ref (nasa-stage-gate later project 'a context records a receipts 11) 'admitted?) #t)
      (check-equal? (.ref (nasa-transition forged (list policy later) "later" project 'a context records a receipts 11) 'advanced?) #f)))
  (test-case "transitions recheck cumulative obligations and revision rebases invalidate proofs"
    (let* ((a (adapter)) (receipts (list (context-receipt a) (evidence-receipt a)))
           (second (nasa-stage-policy "review" '("SWE-013")))
           (policies (list policy second)) (start (nasa-lifecycle-start project))
           (first (nasa-transition start policies "planning" project 'a context (list record) a receipts 11)))
      (check-equal? (.ref first 'advanced?) #t)
      (check-exception (nasa-transition start policies "review" project 'a context (list record) a receipts 11) Error?)
      (check-equal? (.ref (nasa-transition (.ref first 'state) policies "review" project 'a context '() a receipts 11) 'advanced?) #f)
      (check-equal? (.ref (nasa-transition (.ref first 'state) policies "review" project 'a context (list record) a receipts 11) 'advanced?) #t)
      (let* ((next (.o (:: @ project) revision: "r2"))
             (rebased (nasa-lifecycle-rebase (.ref first 'state) next)))
        (check-equal? (.ref rebased 'stage) "unstarted")
        (check-equal? (.ref (nasa-transition rebased policies "planning" next 'a context (list record) a receipts 11) 'advanced?) #f))
      (check-exception (nasa-lifecycle-rebase start project) Error?)))
  (test-case "tailoring requires verified authority and cannot suppress a reported failure"
    (let* ((a (adapter)) (p (nasa-stage-policy "tailored" '("SWE-141")))
           (packet (nasa-tailoring-packet "waiver-test" project "SWE-141" "test" "risk" "mitigation" "risk/R" "matrix/M"))
           (attestation (nasa-authority-attestation "signature" packet 'hq-osma "test-signer" "record/R" 'approved))
           (submission (nasa-tailoring-verification-request project 'a context packet (list attestation)))
           (c (context-receipt a)) (approval (poo-flow-verify a submission 10 20)))
      (check-equal? (.ref (nasa-stage-gate p project 'a context '() a (list c) 11 tailorings: (list submission)) 'admitted?) #f)
      (check-equal? (.ref (nasa-stage-gate p project 'a context '() a (list c approval) 11 tailorings: (list submission)) 'admitted?) #t)
      (check-equal? (.ref (nasa-stage-gate p project 'a context
                            (list (nasa-criterion-evidence "failed-ivv" project "SWE-141" "SWE-141/p1" "reviewer" 'fail))
                            a (list c approval) 11 tailorings: (list submission)) 'admitted?) #f)
      (check-exception (nasa-tailoring-verification-request project 'a context packet '()) Error?)
      (check-exception (nasa-tailoring-verification-request project 'a context packet (list (.o (:: @ attestation) decision: 'rejected))) Error?)
      (poo-flow-revoke-verification! a approval)
      (check-equal? (.ref (nasa-stage-gate p project 'a context '() a (list c approval) 11 tailorings: (list submission)) 'admitted?) #f)))))
