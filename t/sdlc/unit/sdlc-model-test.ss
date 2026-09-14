(import :std/test :std/error
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/lambda-episteme/modules/sdlc/interface)
(def project (sdlc-project "flight" "r2" "software" #t))
(def evidence (sdlc-evidence "ev" "flight" "r2" "software" "nasa" "SWE-052" "test" 'pass))
(export sdlc-model-test)
(def sdlc-model-test
  (test-suite "SDLC CLOS model contracts"
  (test-case "multiple inheritance binds evidence to identity, clause and snapshot"
    (check-equal? (sdlc-evidence? evidence) #t)
    (check-equal? (sdlc-bound-fact? evidence) #t)
    (check-equal? (sdlc-evidence? (.o (:: @ evidence) revision: "")) #f)
    (check-equal? (sdlc-evidence? (.o (:: @ evidence) requirement: #f)) #f)
    (check-equal? (sdlc-evidence? (.o (:: @ evidence) identity: "")) #f)
    (check-equal? (sdlc-evidence? (.o (:: @ evidence) outcome: 'approved)) #f))
  (test-case "a matching kind and fields do not grant model identity"
    (check-equal? (sdlc-project? (.o kind: 'sdlc.project subject: "flight"
                                  revision: "r2" scope: "software" complete?: #t)) #f)
    (check-equal? (sdlc-project? (.o (:: @ project) complete?: 'yes)) #f))
  (test-case "constructors and derived values share one contract"
    (check-exception (sdlc-project "flight" "" "software" #t) Error?)
    (check-exception (sdlc-obligation "nasa" "SWE-052" 'approved) Error?)
    (check-equal? (sdlc-project? (.o (:: @ project) revision: "r3")) #t)
    (check-equal? (.ref project 'revision) "r2"))))
