;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 OntologyProfile ontology-concept ontology-relation
                 ontology-required-relation-rule)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile))

(export CommercialFinanceBaseProfile)

(.def (CommercialFinanceBaseProfile @ OntologyProfile)
  (identity "lambda-episteme/ontology/commercial-finance/base")
  (name 'commercial-finance-base)
  (profile-scope 'scenario)
  (scenario 'commercial-finance)
  (profile-imports =>.+ (.o evidence: EvidenceProfile privacy: PrivacyProfile))
  (concept-declarations =>.+
   (.o customer: (ontology-concept 'Customer '(Actor) '(purpose-limited))
       financial-account:
       (ontology-concept 'FinancialAccount '(BaseEntity) '())
       transaction:
       (ontology-concept 'Transaction '(Action) '(balanced-posting))
       loan: (ontology-concept 'Loan '(BaseEntity) '())
       collateral: (ontology-concept 'Collateral '(BaseEntity) '())))
  (relation-declarations =>.+
   (.o owns-account:
       (ontology-relation 'ownsAccount 'Customer 'FinancialAccount '())
       posts-transaction:
       (ontology-relation
        'postsTransaction 'FinancialAccount 'Transaction '(posting-required))
       secured-by: (ontology-relation 'securedBy 'Loan 'Collateral '())))
  (policies (.o account-posting: 'required
                customer-data: 'purpose-limited))
  (rule-declarations =>.+
   (.o transaction-posting:
       (ontology-required-relation-rule
        'transaction-must-post-to-account
        'Transaction 'postsTransaction 'target)))
  (query-declarations =>.+ (.o)))
