;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        (only-in :poo-flow/src/module-system/profile-composition/interface
                 poo-flow-scenario-case?
                 poo-flow-scenario-case-name
                 poo-flow-scenario-case-profiles)
        :poo-flow/lambda-episteme/user-interface/config)

(export config-test)

(def config-test
  (test-suite "Lambda Episteme direct User Composition"
    (test-case "config discovers and composes common and vertical Profiles"
      (check-equal? (poo-flow-scenario-case? healthcare-australia) #t)
      (check-equal? (poo-flow-scenario-case-name healthcare-australia)
                    'healthcare-australia)
      (let (profiles (poo-flow-scenario-case-profiles healthcare-australia))
        (check-equal? (length profiles) 4)
        (check-equal?
         (map (lambda (profile) (.ref profile 'identity)) profiles)
         '("lambda-episteme/ontology/evidence"
           "lambda-episteme/ontology/privacy"
           "lambda-episteme/ontology/healthcare/base"
           "lambda-episteme/ontology/healthcare/regions/australia"))))))
