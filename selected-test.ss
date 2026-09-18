;;; -*- Gerbil -*-
;;; Observable native gxtest entrypoint for one explicitly selected test.

(import :std/test
        (only-in "testing-observer.ss" run-observed-test))

(export lambda-episteme-selected-test)

(def lambda-episteme-selected-test
  (test-suite "Lambda Episteme selected test"
    (test-case "run the selected test through the POO testing interface"
      (let (test-path (getenv "LAMBDA_EPISTEME_TEST_PATH" #f))
        (unless test-path
          (error "LAMBDA_EPISTEME_TEST_PATH is required"))
        (run-observed-test test-path)))))
