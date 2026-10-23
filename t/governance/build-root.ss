;;; -*- Gerbil -*-
;;; Atomic fixture root for t/governance/...
(import :agentic-ai-lab/modules/governance/interface
        :agentic-ai-lab/lambda-episteme/modules/diataxis/interface
        :agentic-ai-lab/lambda-episteme/modules/decision-kind/interface)
(export governance-test-fixtures-loaded?)
(def governance-test-fixtures-loaded? #t)
