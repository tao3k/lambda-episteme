;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .all-slots .ref .slot? object?)
        :std/list/list
        (only-in :poo-flow/src/graph/types poo-flow-graph?)
        (only-in :poo-flow/src/modules/authorization/types
                 poo-flow-authorization-capability?)
        (only-in :poo-flow/src/modules/temporal-causality/types
                 poo-flow-causal-event?
                 poo-flow-causal-trajectory-contract?
                 poo-flow-causal-trajectory-assessment?
                 poo-flow-structural-impact-receipt?)
        (only-in :poo-flow/src/modules/governance/types
                 poo-flow-governance-assessment?
                 poo-flow-governance-profile?
                 poo-flow-governance-source?
                 poo-flow-governance-threat?)
        (only-in :poo-flow/src/modules/query/types
                 poo-flow-query?))

(export ontology-concept?
        ontology-relation?
        ontology-rule?
        ontology-query?
        ontology-vocabulary?
        ontology-semantic-environment?
        ontology-source?
        ontology-profile?
        ontology-scenario?
        ontology-case?
        ontology-case-composition-receipt?
        ontology-case-evaluation-receipt?
        ontology-reasoning-impact?)

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

(def (ontology-query? value)
  (and (poo-flow-query? value)
       (ontology-has-slots?
        value '(kind identity version source expected-source-content-id
                     graph-kind))
       (ontology-source? (.ref value 'source))
       (string? (.ref value 'expected-source-content-id))
       (memq (.ref value 'graph-kind)
             '(ontology-reasoning causal-event-graph))))

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
  (and (poo-flow-governance-source? value)
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
  (and (poo-flow-governance-profile? value)
       (ontology-has-slots?
        value
        '(name profile-scope scenario profile-imports concept-declarations
               relation-declarations source-declarations rule-declarations
               query-declarations conflict-declarations threat-declarations
               capability-declarations imports ontology terms rules queries conflicts
               capabilities))
       (symbol? (.ref value 'name))
       (memq (.ref value 'profile-scope) '(common scenario))
       (if (eq? (.ref value 'profile-scope) 'common)
         (not (.ref value 'scenario))
         (symbol? (.ref value 'scenario)))
       (every object?
              (list (.ref value 'profile-imports)
                    (.ref value 'concept-declarations)
                    (.ref value 'relation-declarations)
                    (.ref value 'source-declarations)
                    (.ref value 'rule-declarations)
                    (.ref value 'query-declarations)
                    (.ref value 'conflict-declarations)
                    (.ref value 'threat-declarations)
                    (.ref value 'capability-declarations)))
       (list? (.ref value 'imports))
       (ontology-vocabulary? (.ref value 'ontology))
       (equal? (.ref value 'terms)
               (map (lambda (concept) (.ref concept 'identity))
                    (.ref (.ref value 'ontology) 'concepts)))
       (every ontology-source? (.ref value 'source-assets))
       (every poo-flow-authorization-capability? (.ref value 'capabilities))
       (every poo-flow-governance-threat?
              (map (lambda (slot)
                     (.ref (.ref value 'threat-declarations) slot))
                   (.all-slots (.ref value 'threat-declarations))))
       (every ontology-rule? (.ref value 'rules))
       (list? (.ref value 'terms))
       (list? (.ref value 'rules))
       (list? (.ref value 'queries))
       (every ontology-query? (.ref value 'queries))
       (list? (.ref value 'conflicts))))

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
        '(kind case-id scenario profile-selection source-declarations
               authorization-declarations event-declarations
               trajectory-declarations compositions sources authorizations
               events trajectories graph))
       (eq? (.ref value 'kind) 'lambda-episteme.ontology-case)
       (symbol? (.ref value 'case-id))
       (ontology-scenario? (.ref value 'scenario))
       (object? (.ref value 'profile-selection))
       (object? (.ref value 'source-declarations))
       (object? (.ref value 'authorization-declarations))
       (object? (.ref value 'event-declarations))
       (object? (.ref value 'trajectory-declarations))
       (list? (.ref value 'compositions))
       (pair? (.ref value 'compositions))
       (list? (.ref value 'sources))
       (list? (.ref value 'authorizations))
       (every object? (.ref value 'authorizations))
       (list? (.ref value 'events))
       (every poo-flow-causal-event? (.ref value 'events))
       (list? (.ref value 'trajectories))
       (every poo-flow-causal-trajectory-contract?
              (.ref value 'trajectories))
       (poo-flow-graph? (.ref value 'graph))))

(def (ontology-case-composition-receipt? value)
  (and (ontology-has-slots?
        value
        '(kind accepted? case case-id scenario compositions profiles sources events
               trajectories trajectory-assessments trajectory-handoff-ready?
               environment governance-assessments governance-handoff-ready?
               projection diagnostics runtime-executed?))
       (eq? (.ref value 'kind)
            'lambda-episteme.ontology-case-composition-receipt)
       (boolean? (.ref value 'accepted?))
       (ontology-case? (.ref value 'case))
       (symbol? (.ref value 'case-id))
       (symbol? (.ref value 'scenario))
       (list? (.ref value 'compositions))
       (list? (.ref value 'profiles))
       (list? (.ref value 'sources))
       (list? (.ref value 'events))
       (every poo-flow-causal-event? (.ref value 'events))
       (list? (.ref value 'trajectories))
       (every poo-flow-causal-trajectory-contract?
              (.ref value 'trajectories))
       (list? (.ref value 'trajectory-assessments))
       (every poo-flow-causal-trajectory-assessment?
              (.ref value 'trajectory-assessments))
       (boolean? (.ref value 'trajectory-handoff-ready?))
       (eq? (.ref value 'trajectory-handoff-ready?)
            (every (lambda (assessment)
                     (.ref assessment 'accepted?))
                   (.ref value 'trajectory-assessments)))
       (ontology-semantic-environment? (.ref value 'environment))
       (list? (.ref value 'governance-assessments))
       (every poo-flow-governance-assessment?
              (.ref value 'governance-assessments))
       (boolean? (.ref value 'governance-handoff-ready?))
       (eq? (.ref value 'governance-handoff-ready?)
            (and (.ref value 'trajectory-handoff-ready?)
                 (pair? (.ref value 'governance-assessments))
                 (every (lambda (assessment)
                          (.ref assessment 'handoff-ready?))
                        (.ref value 'governance-assessments))))
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

(def (ontology-reasoning-impact? value)
  (and (ontology-has-slots?
        value
        '(kind domain-kind target-node-id target-entity-kind
               dependency-node-ids impacted-case-ids))
       (poo-flow-structural-impact-receipt? value)
       (eq? (.ref value 'domain-kind)
            'lambda-episteme.ontology-reasoning-impact)
       (string? (.ref value 'target-node-id))
       (symbol? (.ref value 'target-entity-kind))
       (list? (.ref value 'dependency-node-ids))
       (list? (.ref value 'impacted-case-ids))
       (every symbol? (.ref value 'impacted-case-ids))))
