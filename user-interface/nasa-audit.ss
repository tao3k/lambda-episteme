;;; Independent synthetic audit case: complete source scope, incomplete evidence.
(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/interface
        :lambda-episteme/modules/sdlc/standards/nasa-review)
(export nasa-audit-example)
(def (nasa-audit-example)
  (let* ((project (sdlc-project "demo-flight" "baseline-7" "avionics" #t))
         (context (.o safety-critical?: #t health-medical?: #f ivv-required?: #t
                       ivv-performed?: #t reaching-kdp-a?: #t category-1?: #t))
         (packet (nasa-tailoring-packet "tailoring-1" project "SWE-141"
                    "synthetic exercise" "loss of independent review"
                    "independent review retained pending decision" "risk-register/R1" "matrix/M1"))
         (attestation (nasa-authority-attestation "record-1" packet 'hq-osma
                         "synthetic-signer" "records/signature-1" 'approved)))
    (.o assessment: (nasa-assess-project 'a project context
                     (list (nasa-criterion-evidence "planning-1" project "SWE-013" "SWE-013/p1" "synthetic-reviewer" 'pass)))
        safety: (nasa-safety-review project
                  (list (nasa-safety-component "controller" project #t 99 16)))
        tailoring: (nasa-tailoring-review project 'a context packet (list attestation))
        release-authorized?: #f)))
