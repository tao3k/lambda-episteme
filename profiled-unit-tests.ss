;;; -*- Gerbil -*-
;;; The public test entrypoint is itself a native gxtest suite.  The observer
;;; delegates every discovered file back to `gerbil test`, while the POO
;;; TestingInterface owns batching, resource profiles, and observability.

(import :std/test
        (only-in "testing-observer.ss" run-observed-test))

(export lambda-episteme-profiled-unit-test)

(def lambda-episteme-profiled-unit-test
  (test-suite "Lambda Episteme profiled unit tests"
    (test-case "run discovered tests through the POO testing interface"
      (run-observed-test "t"))))
