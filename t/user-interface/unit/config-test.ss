;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .ref)
        (only-in :agentic-ai-lab/modules/workflow/scenario/case agentic-ai-lab-scenario-case?)
        (only-in :agentic-ai-lab/modules/workflow/scenario/accessors
                 agentic-ai-lab-scenario-case-name
                 agentic-ai-lab-scenario-case-profiles)
        :agentic-ai-lab/lambda-episteme/user-interface/config)

(export config-test)

(def config-test
  (test-suite "Lambda Episteme direct User Composition"
    (test-case "config discovers and composes common and vertical Profiles"
      (check-equal? (agentic-ai-lab-scenario-case? healthcare-australia) #t)
      (check-equal? (agentic-ai-lab-scenario-case-name healthcare-australia)
                    'healthcare-australia)
      (let (profiles (agentic-ai-lab-scenario-case-profiles healthcare-australia))
        (check-equal? (length profiles) 4)
        (check-equal?
         (map (lambda (profile) (.ref profile 'identity)) profiles)
         '("lambda-episteme/ontology/evidence"
           "lambda-episteme/ontology/privacy"
           "lambda-episteme/ontology/healthcare/base"
           "lambda-episteme/ontology/healthcare/regions/australia"))))))
