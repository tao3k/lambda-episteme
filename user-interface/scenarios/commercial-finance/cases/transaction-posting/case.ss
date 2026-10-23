;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (rename-in
         (only-in :yuanxu/graph/types
                  graph agentic-ai-lab-graph-edge agentic-ai-lab-graph-node)
         (graph Graph))
        (only-in :agentic-ai-lab/lambda-episteme/modules/ontology/interface
                 OntologyCase)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/commercial-finance/profiles/base
                 CommercialFinanceBaseProfile)
        (only-in :agentic-ai-lab/lambda-episteme/user-interface/scenarios/commercial-finance/scenario
                 CommercialFinanceScenario))

(export TransactionPostingCase)

(.def (TransactionPostingCase @ OntologyCase)
  (case-id 'transaction-posting)
  (scenario CommercialFinanceScenario)
  (profile-selection =>.+
   (.o commercial-finance:
       (.o evidence: EvidenceProfile
           privacy: PrivacyProfile
           base: CommercialFinanceBaseProfile)))
  (graph
   (.o (:: @ Graph)
       graph-id: 'transaction-posting
       node-declarations:
       (.o customer-1: (agentic-ai-lab-graph-node 'customer-1 'Customer)
           account-1: (agentic-ai-lab-graph-node 'account-1 'FinancialAccount)
           transaction-1:
           (agentic-ai-lab-graph-node 'transaction-1 'Transaction))
       edge-declarations:
       (.o customer-owns-account:
           (agentic-ai-lab-graph-edge 'customer-1 'account-1 'ownsAccount)
           account-posts-transaction:
           (agentic-ai-lab-graph-edge
            'account-1 'transaction-1 'postsTransaction)))))
