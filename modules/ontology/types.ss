;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .ref .slot? object?)
        (only-in :std/srfi/1 every)
        (only-in :poo-flow/src/graph/types poo-flow-graph?)
        (only-in :poo-flow/lambda-episteme/governance/objects
                 governance-profile? source-asset?))

(export ontology-concept?
        ontology-relation?
        ontology-rule?
        ontology-vocabulary?
        ontology-semantic-environment?
        ontology-source?
        ontology-profile?
        ontology-scenario?
        ontology-case?
        ontology-case-composition-receipt?
        ontology-case-evaluation-receipt?)

(def (ontology-has-slots? value slots)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot)) slots)))

(def (ontology-concept? value)
  (and (ontology-has-slots?
        value '(kind identity parents constraints .project))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-concept)
       (symbol? (.ref value 'identity))
       (list? (.ref value 'parents))
       (every symbol? (.ref value 'parents))
       (list? (.ref value 'constraints))
       (procedure? (.ref value '.project))))

(def (ontology-relation? value)
  (and (ontology-has-slots?
        value '(kind identity domain range constraints .project))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-relation)
       (symbol? (.ref value 'identity))
       (symbol? (.ref value 'domain))
       (symbol? (.ref value 'range))
       (list? (.ref value 'constraints))
       (procedure? (.ref value '.project))))

(def (ontology-rule? value)
  (and (ontology-has-slots?
        value '(kind identity .evaluate .project))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-rule)
       (symbol? (.ref value 'identity))
       (procedure? (.ref value '.evaluate))
       (procedure? (.ref value '.project))))

(def (ontology-vocabulary? value)
  (and (ontology-has-slots? value '(kind concepts relations))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-vocabulary)
       (list? (.ref value 'concepts))
       (every ontology-concept? (.ref value 'concepts))
       (list? (.ref value 'relations))
       (every ontology-relation? (.ref value 'relations))))

(def (ontology-semantic-environment? value)
  (and (ontology-has-slots?
        value '(kind concept-index relation-index rules diagnostics))
       (eq? (.ref value 'kind)
            'lambda-episteme.ontology-semantic-environment)
       (hash-table? (.ref value 'concept-index))
       (hash-table? (.ref value 'relation-index))
       (list? (.ref value 'rules))
       (every ontology-rule? (.ref value 'rules))
       (list? (.ref value 'diagnostics))))

(def (ontology-source? value)
  (and (source-asset? value)
       (ontology-has-slots? value '(kind source-scope scenario case-id))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-source)
       (memq (.ref value 'source-scope) '(common scenario case))
       (case (.ref value 'source-scope)
         ((common)
          (and (not (.ref value 'scenario))
               (not (.ref value 'case-id))))
         ((scenario)
          (and (symbol? (.ref value 'scenario))
               (not (.ref value 'case-id))))
         ((case)
          (and (symbol? (.ref value 'scenario))
               (symbol? (.ref value 'case-id))))
         (else #f))))

(def (ontology-profile-shape? value)
  (and (governance-profile? value)
       (ontology-has-slots?
        value
        '(name profile-scope scenario .import .add-concept .add-relation
               .add-source .add-rule .add-query .add-conflict
               imports ontology terms rules queries conflicts))
       (symbol? (.ref value 'name))
       (memq (.ref value 'profile-scope) '(common scenario))
       (if (eq? (.ref value 'profile-scope) 'common)
         (not (.ref value 'scenario))
         (symbol? (.ref value 'scenario)))
       (every object?
              (list (.ref value '.import)
                    (.ref value '.add-concept)
                    (.ref value '.add-relation)
                    (.ref value '.add-source)
                    (.ref value '.add-rule)
                    (.ref value '.add-query)
                    (.ref value '.add-conflict)))
       (list? (.ref value 'imports))
       (ontology-vocabulary? (.ref value 'ontology))
       (equal? (.ref value 'terms)
               (map (lambda (concept) (.ref concept 'identity))
                    (.ref (.ref value 'ontology) 'concepts)))
       (every ontology-source? (.ref value 'source-assets))
       (every ontology-rule? (.ref value 'rules))
       (every list?
              (list (.ref value 'terms)
                    (.ref value 'rules)
                    (.ref value 'queries)
                    (.ref value 'conflicts)))))

(def (ontology-profile? value)
  (and (ontology-profile-shape? value)
       (every ontology-profile-shape? (.ref value 'imports))))

(def (ontology-scenario? value)
  (and (ontology-has-slots?
        value '(kind identity owner revision base-profile .admit-profile?))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-scenario)
       (symbol? (.ref value 'identity))
       (string? (.ref value 'owner))
       (string? (.ref value 'revision))
       (procedure? (.ref value '.admit-profile?))
       (ontology-profile? (.ref value 'base-profile))
       (eq? (.ref (.ref value 'base-profile) 'scenario)
            (.ref value 'identity))))

(def (ontology-case? value)
  (and (ontology-has-slots?
        value
        '(kind case-id scenario .use-composition .add-source
               compositions sources graph))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-case)
       (symbol? (.ref value 'case-id))
       (ontology-scenario? (.ref value 'scenario))
       (object? (.ref value '.use-composition))
       (object? (.ref value '.add-source))
       (list? (.ref value 'compositions))
       (pair? (.ref value 'compositions))
       (list? (.ref value 'sources))
       (poo-flow-graph? (.ref value 'graph))))

(def (ontology-case-composition-receipt? value)
  (and (ontology-has-slots?
        value
        '(kind accepted? case case-id scenario compositions profiles sources
               environment projection diagnostics runtime-executed?))
       (eq? (.ref value 'kind)
            'lambda-episteme.ontology-case-composition-receipt)
       (boolean? (.ref value 'accepted?))
       (ontology-case? (.ref value 'case))
       (symbol? (.ref value 'case-id))
       (symbol? (.ref value 'scenario))
       (list? (.ref value 'compositions))
       (list? (.ref value 'profiles))
       (list? (.ref value 'sources))
       (ontology-semantic-environment? (.ref value 'environment))
       (list? (.ref value 'projection))
       (list? (.ref value 'diagnostics))
       (eq? (.ref value 'runtime-executed?) #f)))

(def (ontology-case-evaluation-receipt? value)
  (and (ontology-has-slots?
        value '(kind accepted? composition graph diagnostics runtime-executed?))
       (eq? (.ref value 'kind)
            'lambda-episteme.ontology-case-evaluation-receipt)
       (boolean? (.ref value 'accepted?))
       (ontology-case-composition-receipt? (.ref value 'composition))
       (poo-flow-graph? (.ref value 'graph))
       (list? (.ref value 'diagnostics))
       (eq? (.ref value 'runtime-executed?) #t)))
