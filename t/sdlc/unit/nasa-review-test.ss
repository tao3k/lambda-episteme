(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        :lambda-episteme/modules/sdlc/standards/nasa-review
        (only-in :std/srfi/1 every find))
(def project (sdlc-project "flight" "r1" "software" #t))
(def known-context
  (.o safety-critical?: #f mission-critical?: #f ivv-required?: #f ivv-performed?: #f
      reaching-kdp-a?: #f category-1?: #f category-2?: #f payload-risk-a-or-b?: #f
      mdaa-selected-ivv?: #f approved-tailoring-exists?: #f reused-component?: #f
      auto-generated-code?: #f nasa-class-d-payload?: #f communications-capable?: #f
      flight-qualification-tools?: #f loaded-behavior-inputs?: #f
      embedded-reused-component?: #f joint-audit?: #f health-medical?: #f))
(def (status id context)
  (.ref (nasa-applicability id 'a context) 'status))
(def (assess evidence (p project)) (nasa-assess-project 'a p known-context evidence))
(def (row report id)
  (find (lambda (r) (equal? (.ref r 'requirement) id)) (.ref report 'requirements)))
(def evidence (nasa-criterion-evidence "e1" project "SWE-013" "SWE-013/p1" "reviewer" 'pass))
(export nasa-review-test)
(def nasa-review-test
  (test-suite "NASA full source review and conditional rules"
  (test-case "every index row has authoritative paragraphs, including continuations"
    (check-equal? (length nasa-requirement-catalog) 130)
    (check-equal? (apply + (map (lambda (r) (length (.ref r 'source-parts))) nasa-requirement-catalog)) 255)
    (check-equal? (length (nasa-requirement-criteria "SWE-027")) 7)
    (check-equal? (length (nasa-requirement-criteria "SWE-141")) 4)
    (check-equal? (length (nasa-requirement-criteria "SWE-086")) 1)
    (check-equal? (every (lambda (r) (eq? (.ref r 'text-coverage) 'normative-paragraphs)) nasa-requirement-catalog) #t))
  (test-case "fully supplied context leaves no unsupported project-condition branch"
    (for-each (lambda (class)
      (check-equal? (length (nasa-project-obligations class known-context)) 130)
      (check-equal? (every (lambda (r) (not (eq? (.ref r 'status) 'context-review-required)))
                           (nasa-project-obligations class known-context)) #t)) '(a b c d e f)))
  (test-case "required IVV and performed IVV have distinct source triggers"
    (check-equal? (status "SWE-131" (.o ivv-required?: #t ivv-performed?: #f)) 'applicable)
    (check-equal? (status "SWE-178" (.o ivv-required?: #t ivv-performed?: #f)) 'condition-not-triggered)
    (check-equal? (status "SWE-131" (.o ivv-performed?: #t)) 'context-review-required)
    (check-equal? (status "SWE-141" (.o reaching-kdp-a?: #t category-1?: #t)) 'applicable)
    (check-equal? (status "SWE-141" (.o reaching-kdp-a?: #f category-1?: #t)) 'condition-not-triggered)
    (check-equal? (status "SWE-143" (.o category-1?: #f category-2?: #t payload-risk-a-or-b?: #t)) 'applicable))
  (test-case "specific acquisition, generation and payload conditions are not guessed"
    (check-equal? (status "SWE-027" (.o reused-component?: #t)) 'applicable)
    (check-equal? (status "SWE-146" (.o auto-generated-code?: #f)) 'condition-not-triggered)
    (check-equal? (.ref (nasa-applicability "SWE-032" 'b (.o nasa-class-d-payload?: #t)) 'status) 'condition-not-triggered)
    (check-equal? (status "SWE-157" (.o)) 'context-review-required)
    (check-exception (status "SWE-157" (.o communications-capable?: 'yes)) Error?))
  (test-case "every requirement gets a review row and cannot authorize release"
    (check-equal? (length (.ref (assess '()) 'requirements)) 130)
    (check-equal? (.ref (row (assess '()) "SWE-013") 'status) 'missing-evidence)
    (check-equal? (.ref (row (assess '() (.o (:: @ project) complete?: #f)) "SWE-013") 'status) 'unknown)
    (check-equal? (.ref (row (assess (list evidence)) "SWE-013") 'status) 'evidence-present)
    (check-equal? (.ref (assess (list evidence)) 'release-authorized?) #f))
  (test-case "institutional owners use a separate complete review scope"
    (let* ((record (nasa-criterion-evidence "institution" project "SWE-002" "SWE-002/p1" "oce-reviewer" 'pass))
           (report (nasa-assess-institution 'a project known-context (list record))))
      (check-equal? (length (.ref report 'requirements)) 30)
      (check-equal? (.ref (row report "SWE-002") 'status) 'evidence-present)
      (check-equal? (.ref (row (assess (list record)) "SWE-002") 'status) 'institutional-review-required)
      (check-equal? (.ref (row (nasa-assess-institution 'f project known-context '()) "SWE-091") 'status) 'condition-not-triggered)))
  (test-case "source digest, project and baseline are checked independently"
    (check-equal? (.ref (row (assess (list (.o (:: @ evidence) revision: "old"))) "SWE-013") 'status) 'stale-evidence)
    (check-equal? (.ref (row (assess (list (.o (:: @ evidence) source-digest: "old"))) "SWE-013") 'status) 'stale-evidence)
    (check-equal? (.ref (row (assess (list (.o (:: @ evidence) subject: "foreign"))) "SWE-013") 'status) 'missing-evidence)
    (check-equal? (.ref (row (assess (list evidence (.o (:: @ evidence) identity: "failed" outcome: 'fail))) "SWE-013") 'status) 'reported-failure)
    (check-exception (assess (list evidence evidence)) Error?)
    (check-exception (assess (list (.o (:: @ evidence) criterion: "SWE-013/p999"))) Error?))
  (test-case "introductory evidence cannot discharge unreviewed subparagraphs"
    (let* ((context (.o (:: @ known-context) reused-component?: #t))
           (criteria (nasa-requirement-criteria "SWE-027"))
           (records (map (lambda (c) (nasa-criterion-evidence
                                      (.ref c 'identity) project "SWE-027"
                                      (.ref c 'identity) "synthetic-reviewer" 'pass)) criteria))
           (partial (row (nasa-assess-project 'a project context (list (car records))) "SWE-027"))
           (complete (row (nasa-assess-project 'a project context records) "SWE-027")))
      (check-equal? (.ref partial 'status) 'missing-evidence)
      (check-equal? (length (.ref partial 'missing-criteria)) 6)
      (check-equal? (.ref complete 'status) 'evidence-present)))
  (test-case "tailoring routes all required authorities without inventing approval"
    (check-equal? (.ref (nasa-tailoring-requirements "SWE-141" 'a known-context) 'required-authorities) '(hq-osma))
    (check-equal? (.ref (nasa-tailoring-requirements "SWE-157" 'a (.o health-medical?: #t)) 'required-authorities)
                  '(center-eta center-cio saiso-or-designated-ciso chmo))
    (check-equal? (.ref (nasa-tailoring-requirements "SWE-156" 'f known-context) 'required-authorities) '(cio saiso-or-designated-ciso))
    (check-equal? (.ref (nasa-tailoring-requirements "SWE-013" 'a (.o)) 'context-review-required?) #t)
    (check-equal? (.ref (nasa-tailoring-requirements "SWE-013" 'a known-context) 'approved?) #f))
  (test-case "numerical safety checks preserve unknown and waiver boundaries"
    (let* ((good (nasa-safety-component "good" project #t 100 15))
           (bad (nasa-safety-component "bad" project #t 99 16))
           (unknown (nasa-safety-component "unknown" project #t 'unknown 'unknown))
           (results (.ref (nasa-safety-review project (list good bad unknown)) 'components)))
      (check-equal? (map (lambda (r) (.ref r 'coverage)) results) '(threshold-met coverage-gap unknown))
      (check-equal? (map (lambda (r) (.ref r 'complexity)) results) '(threshold-met waiver-review-required unknown))
      (check-equal? (.ref (nasa-safety-review project '()) 'inventory) 'review-required)
      (check-equal? (.ref (nasa-safety-review (.o (:: @ project) complete?: #f) (list good)) 'inventory) 'partial)
      (check-exception (nasa-safety-component "bad" project #t 101 1) Error?)
      (check-exception (nasa-safety-review project (list good good)) Error?)))))
