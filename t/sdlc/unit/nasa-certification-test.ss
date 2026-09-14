(import :std/test :std/error
        (only-in :clan/poo/object .o .ref)
        :poo-flow/src/module-system/contribution/verification
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-policy
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-certification)

(export nasa-certification-test)

(def (fixture-phase name)
  (displayln "[lambda-episteme-test] phase=fixture-ready module=sdlc test=nasa-certification fixture=" name)
  (force-output))

(def project (sdlc-project "flight-certification" "baseline-7" "software" #t))
(fixture-phase 'project)
(def matrix-digest (make-string 64 #\a))

(def (admitted-gate scope-value)
  (let (policy
        (nasa-baseline-policy
         (if (eq? scope-value 'project) "project-baseline" "institution-baseline")
         scope: scope-value))
    (.o stage: (.ref policy 'identity)
        status: 'stage-admitted
        assessment-scope: scope-value
        requirements: (.ref policy 'requirements)
        admitted?: #t
        reported-failures: '()
        release-authorized?: #f)))

(def project-gate (admitted-gate 'project))
(fixture-phase 'project-gate)
(def institution-gate (admitted-gate 'institution))
(fixture-phase 'institution-gate)
(def dossier
  (nasa-compliance-dossier
   "dossier-7" project 'a matrix-digest project-gate institution-gate))
(fixture-phase 'dossier)
(def compliant-decision
  (nasa-certification-decision
   "decision-7" dossier 'responsible-nasa-official
   "authorized-reviewer" "records/rmm-approval-7" 'compliant))
(fixture-phase 'decision)

(def (adapter)
  (nasa-certification-verification-adapter
   "test-nasa-authority"
   (lambda (request now until)
     (and (eq? (.ref request 'purpose) 'certification-decision)
          (equal? (.ref (.ref (.ref request 'facts) 'dossier)
                        'mapping-matrix-digest)
                  matrix-digest)
          (= now 10) (= until 20)))))

(def nasa-certification-test
  (test-suite
   "NASA compliance dossier and authority certification boundary"
   (test-case
    "a complete 100 plus 30 requirement dossier remains uncertified"
    (check-equal? (.ref dossier 'complete?) #t)
    (check-equal? (length (.ref project-gate 'requirements)) 100)
    (check-equal? (length (.ref institution-gate 'requirements)) 30)
    (let* ((a (adapter))
           (review (nasa-certification-review
                    dossier compliant-decision a '() 11)))
      (check-equal? (.ref review 'status) 'authority-verification-required)
      (check-equal? (.ref review 'compliance) 'not-evaluated)
      (check-equal? (.ref review 'certification) 'not-certified)
      (check-equal? (.ref review 'release-authorized?) #f)))
   (test-case
    "only the configured authority receipt certifies the exact dossier"
    (let* ((a (adapter))
           (request (nasa-certification-verification-request
                     dossier compliant-decision))
           (receipt (poo-flow-verify a request 10 20))
           (review (nasa-certification-review
                    dossier compliant-decision a (list receipt) 11)))
      (check-equal? (.ref review 'status)
                    'compliant-by-verified-authority)
      (check-equal? (.ref review 'compliance) 'compliant)
      (check-equal? (.ref review 'certification) 'authority-verified)
      (check-equal? (.ref review 'release-authorized?) #f)
      (check-equal?
       (.ref (nasa-certification-review
              dossier compliant-decision a (list (.o (:: @ receipt))) 11)
             'certification)
       'not-certified)
      (check-equal?
       (.ref (nasa-certification-review
              dossier compliant-decision a (list receipt) 20)
             'certification)
       'not-certified)))
   (test-case
    "an authenticated noncompliance decision remains distinct"
    (let* ((a (adapter))
           (decision
            (nasa-certification-decision
             "decision-rejected" dossier 'responsible-nasa-official
             "authorized-reviewer" "records/rmm-rejection-7" 'noncompliant))
           (request (nasa-certification-verification-request dossier decision))
           (receipt (poo-flow-verify a request 10 20))
           (review (nasa-certification-review dossier decision a (list receipt) 11)))
      (check-equal? (.ref review 'status)
                    'noncompliant-by-verified-authority)
      (check-equal? (.ref review 'compliance) 'noncompliant)
      (check-equal? (.ref review 'release-authorized?) #f)))
   (test-case
    "incomplete or malformed baselines cannot become an eligible dossier"
    (let* ((short-gate
            (.o (:: @ project-gate)
                requirements: (cdr (.ref project-gate 'requirements))))
           (incomplete
            (nasa-compliance-dossier
             "incomplete" project 'a matrix-digest short-gate institution-gate)))
      (check-equal? (.ref incomplete 'complete?) #f)
      (check-equal?
       (.ref (nasa-certification-review
              incomplete
              (nasa-certification-decision
               "no" incomplete 'responsible-nasa-official "reviewer" "record" 'compliant)
              (adapter) '() 11)
             'status)
       'dossier-incomplete))
    (check-exception
     (nasa-compliance-dossier
      "bad" project 'a "not-a-digest" project-gate institution-gate)
     Error?)
    (check-exception
     (nasa-certification-verification-request
      dossier (.o (:: @ compliant-decision) dossier: "another"))
     Error?))))
