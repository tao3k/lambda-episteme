(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-review
        :lambda-episteme/user-interface/nasa-audit)
(export nasa-audit-test)
(def nasa-audit-test
  (test-suite "NASA audit and tailoring record binding"
  (test-case "complex review exposes the evidence and safety gaps"
    (let (audit (nasa-audit-example))
      (check-equal? (length (.ref (.ref audit 'assessment) 'requirements)) 130)
      (check-equal? (.ref (car (.ref (.ref audit 'safety) 'components)) 'coverage) 'coverage-gap)
      (check-equal? (.ref (.ref audit 'tailoring) 'status) 'authority-verification-required)
      (check-equal? (.ref audit 'release-authorized?) #f)))
  (test-case "claimed signatures cannot approve themselves or another request"
    (let* ((project (sdlc-project "flight" "r1" "scope" #t))
           (context (.o health-medical?: #f))
           (packet (nasa-tailoring-packet "r" project "SWE-141" "rationale" "risk" "mitigation" "acceptance" "matrix"))
           (record (nasa-authority-attestation "a" packet 'hq-osma "signer" "record" 'approved))
           (review (lambda (records) (nasa-tailoring-review project 'a context packet records))))
      (check-equal? (.ref (review '()) 'status) 'missing-authority-records)
      (check-equal? (.ref (review (list (.o (:: @ record) request: "other"))) 'status) 'missing-authority-records)
      (check-equal? (.ref (review (list (.o (:: @ record) revision: "old"))) 'status) 'missing-authority-records)
      (check-equal? (.ref (review (list (.o (:: @ record) authority: 'project-manager))) 'status) 'missing-authority-records)
      (check-equal? (.ref (review (list record (.o (:: @ record) identity: "rejected" decision: 'rejected))) 'status) 'reported-rejection)
      (check-equal? (.ref (review (list record)) 'approved?) #f)
      (check-exception (review (list record record)) Error?)
      (check-exception (nasa-tailoring-review (.o (:: @ project) revision: "r2") 'a context packet (list record)) Error?)))))
