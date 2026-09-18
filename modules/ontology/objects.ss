;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .all-slots .o .ref object?)
        (only-in :clan/poo/mop .defgeneric)
        (only-in :std/misc/hash hash-get hash-put!)
        (only-in :std/srfi/1 filter)
        (only-in :poo-flow/src/graph/algorithms
                 poo-flow-graph-cycle-path)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph poo-flow-graph-edge-from
                 poo-flow-graph-edge-kind poo-flow-graph-edge-to
                 poo-flow-graph-edges poo-flow-graph-node-id
                 poo-flow-graph-node-payload poo-flow-graph-nodes)
        (only-in :poo-flow/src/module-system/profile-composition/interface
                 poo-flow-scenario-case)
        (only-in :poo-flow/src/modules/authorization/types
                 poo-flow-authorization-capability?)
        (only-in :poo-flow/src/modules/governance/objects
                 PooFlowGovernanceProfile.
                 poo-flow-governance-source
                 poo-flow-governance-threat-model)
        (only-in :poo-flow/src/utilities/functional
                 poo-flow-filter-map)
        (only-in "types.ss"
                 ontology-concept? ontology-profile? ontology-relation?
                 ontology-rule? ontology-query?
                 ontology-scenario? ontology-source? ontology-vocabulary?))

(export ontology-concept ontology-relation ontology-vocabulary
        ontology-vocabulary-concept-identities ontology-semantic-project
        ontology-required-relation-rule ontology-acyclic-relation-rule
        ontology-rule-evaluate
        ontology-query
        ontology-source OntologyProfile ontology-profile-project
        OntologyScenario ontology-scenario-admits-profile?
        OntologyCase)

;; Profile and Scenario-local behavior is ordinary gerbil-poo slot dispatch.
;; Derived values replace their method slots directly; CLOS is reserved for a
;; real cross-dispatch between independent Provider/executor and domain axes.
(.defgeneric (ontology-profile-project behavior profile)
  slot: .project)

(.defgeneric (ontology-scenario-admits-profile? scenario profile)
  slot: .admit-profile?)

(.defgeneric (ontology-semantic-project behavior semantic)
  slot: .project)

(.defgeneric (ontology-rule-evaluate behavior rule graph)
  slot: .evaluate)

(def (ontology-declaration-values declarations name)
  (unless (object? declarations)
    (error "ontology declaration slot must be a POO object" name))
  (map (lambda (slot) (.ref declarations slot))
       (.all-slots declarations)))

(def (ontology-case-composition-values declarations)
  (unless (object? declarations)
    (error "Case .use-composition must be a POO object" declarations))
  (map
   (lambda (composition-name)
     (poo-flow-scenario-case
      composition-name
      '()
      (ontology-declaration-values
       (.ref declarations composition-name)
       (list '.use-composition composition-name))
      '()
      '()))
   (.all-slots declarations)))

;; User-facing Cases are pure POO configuration objects.  The dotted slots are
;; the only declarations maintained by the user; native composition and source
;; sequences are derived lazily for the framework-owned evaluator.
(def OntologyCase
  (.o kind: 'lambda-episteme.ontology-case
      case-id: #f
      scenario: #f
      .use-composition: (.o)
      .add-source: (.o)
      .add-authorization: (.o)
      .add-event: (.o)
      .add-trajectory: (.o)
      compositions: (ontology-case-composition-values .use-composition)
      sources: (ontology-declaration-values .add-source '.add-source)
      authorizations:
      (ontology-declaration-values .add-authorization '.add-authorization)
      events: (ontology-declaration-values .add-event '.add-event)
      trajectories:
      (ontology-declaration-values .add-trajectory '.add-trajectory)
      graph: #f))

(def (ontology-rule-diagnostic rule-value code-value path-value detail-value)
  (.o kind: 'lambda-episteme.ontology-rule-diagnostic
      rule: (.ref rule-value 'identity)
      code: code-value path: path-value detail: detail-value))

;;; Constraint identities are unresolved obligations in this first slice; they
;;; do not become executable until the Rule-object milestone owns their method.
(def (ontology-concept identity-value parents-value constraints-value)
  (let (value
        (.o kind: 'lambda-episteme.ontology-concept
            identity: identity-value
            parents: parents-value
            constraints: constraints-value
            .project:
            (lambda (concept)
              (.o kind: 'concept
                  identity: (.ref concept 'identity)
                  parents: (.ref concept 'parents)
                  constraints: (.ref concept 'constraints)))))
    (unless (ontology-concept? value)
      (error "invalid ontology concept" identity-value))
    value))

(def (ontology-relation identity-value domain-value range-value
                        constraints-value)
  (let (value
        (.o kind: 'lambda-episteme.ontology-relation
            identity: identity-value
            domain: domain-value
            range: range-value
            constraints: constraints-value
            .project:
            (lambda (relation)
              (.o kind: 'relation
                  identity: (.ref relation 'identity)
                  domain: (.ref relation 'domain)
                  range: (.ref relation 'range)
                  constraints: (.ref relation 'constraints)))))
    (unless (ontology-relation? value)
      (error "invalid ontology relation" identity-value))
    value))

(def (ontology-vocabulary concepts-value relations-value)
  (let (value
        (.o kind: 'lambda-episteme.ontology-vocabulary
            concepts: concepts-value
            relations: relations-value))
    (unless (ontology-vocabulary? value)
      (error "invalid ontology vocabulary" value))
    value))

(def (ontology-vocabulary-concept-identities vocabulary)
  (map (lambda (concept) (.ref concept 'identity))
       (.ref vocabulary 'concepts)))

(def (ontology-required-relation-rule identity-value concept-value
                                      relation-value position-value)
  (unless (memq position-value '(source target))
    (error "invalid required relation position" position-value))
  (let (value
        (.o kind: 'lambda-episteme.ontology-rule
            identity: identity-value
            rule-kind: 'required-relation
            concept: concept-value relation: relation-value
            position: position-value
            .evaluate:
            (lambda (rule graph)
              (let ((nodes (poo-flow-graph-nodes graph))
                    (edges (poo-flow-graph-edges graph))
                    (relation (.ref rule 'relation))
                    (position (.ref rule 'position))
                    (covered-node-ids (make-hash-table)))
                ;; Build the selected relation/position index once.  The old
                ;; node-by-node edge scan was O(V*E) for large Case graphs.
                (for-each
                 (lambda (edge)
                   (when (eq? (poo-flow-graph-edge-kind edge) relation)
                     (hash-put!
                      covered-node-ids
                      (if (eq? position 'source)
                        (poo-flow-graph-edge-from edge)
                        (poo-flow-graph-edge-to edge))
                      #t)))
                 edges)
                (poo-flow-filter-map
                 (lambda (node)
                   (and
                    (eq? (poo-flow-graph-node-payload node)
                         (.ref rule 'concept))
                    (not (hash-get covered-node-ids
                                   (poo-flow-graph-node-id node)))
                    (ontology-rule-diagnostic
                     rule 'required-relation-missing
                     (list 'graph (poo-flow-graph-node-id node))
                     relation)))
                 nodes)))
            .project:
            (lambda (rule)
              (.o kind: 'rule identity: (.ref rule 'identity)
                  rule-kind: (.ref rule 'rule-kind)
                  concept: (.ref rule 'concept)
                  relation: (.ref rule 'relation)
                  position: (.ref rule 'position)))))
    (unless (ontology-rule? value)
      (error "invalid required relation rule" identity-value))
    value))

(def (ontology-acyclic-relation-rule identity-value relation-value)
  (let (value
        (.o kind: 'lambda-episteme.ontology-rule
            identity: identity-value
            rule-kind: 'acyclic-relation
            relation: relation-value
            .evaluate:
            (lambda (rule graph)
              (let* ((relation (.ref rule 'relation))
                     (relation-graph
                      (poo-flow-graph
                       (list 'ontology-rule relation)
                       (poo-flow-graph-nodes graph)
                       (filter
                        (lambda (edge)
                          (eq? (poo-flow-graph-edge-kind edge) relation))
                        (poo-flow-graph-edges graph))))
                     (cycle-path
                      (poo-flow-graph-cycle-path relation-graph)))
                (if cycle-path
                  (list (ontology-rule-diagnostic
                         rule 'relation-cycle '(graph) cycle-path))
                  '())))
            .project:
            (lambda (rule)
              (.o kind: 'rule identity: (.ref rule 'identity)
                  rule-kind: (.ref rule 'rule-kind)
                  relation: (.ref rule 'relation)))))
    (unless (ontology-rule? value)
      (error "invalid acyclic relation rule" identity-value))
    value))

(def (ontology-source identity-value path-value language-value scope-value
                      scenario-value case-id-value)
  (let (value
        (.o (:: @ (poo-flow-governance-source
                    identity-value path-value language-value))
            kind: 'lambda-episteme.ontology-source
            source-scope: scope-value
            scenario: scenario-value
            case-id: case-id-value))
    (unless (ontology-source? value)
      (error "invalid ontology source" identity-value))
    value))

(def (ontology-query identity-value revision-value source-value
                     expected-source-content-id-value graph-kind-value)
  (let (value
        (.o kind: 'lambda-episteme.ontology-query
            identity: identity-value
            revision: revision-value
            source: source-value
            expected-source-content-id: expected-source-content-id-value
            graph-kind: graph-kind-value))
    (unless (ontology-query? value)
      (error "invalid ontology query" identity-value))
    value))

(def OntologyScenario
  (.o kind: 'lambda-episteme.ontology-scenario
      identity: #f
      owner: "lambda-episteme"
      revision: "1"
      base-profile: #f
      .admit-profile?:
      (lambda (profile)
        (and (ontology-profile? profile)
             (or (eq? (.ref profile 'profile-scope) 'common)
                 (eq? (.ref profile 'scenario) identity))))))

(def OntologyProfile
  (.o (:: @ PooFlowGovernanceProfile.)
      identity: "lambda-episteme/ontology"
      revision: "1"
      owner: "lambda-episteme"
      name: 'ontology
      profile-scope: 'common
      scenario: #f
      .import: (.o)
      .add-concept: (.o)
      .add-relation: (.o)
      .add-source: (.o)
      .add-rule: (.o)
      .add-query: (.o)
      .add-conflict: (.o)
      .add-threat: (.o)
      .add-capability: (.o)
      imports: (ontology-declaration-values .import '.import)
      ontology:
      (ontology-vocabulary
       (ontology-declaration-values .add-concept '.add-concept)
       (ontology-declaration-values .add-relation '.add-relation))
      policies: (.o source-binding: 'explicit
                    source-scope: 'non-reversing
                    runtime-mutation: 'forbidden)
      source-assets: (ontology-declaration-values .add-source '.add-source)
      capabilities:
      (ontology-declaration-values .add-capability '.add-capability)
      terms: (ontology-vocabulary-concept-identities ontology)
      rules: (ontology-declaration-values .add-rule '.add-rule)
      queries: (ontology-declaration-values .add-query '.add-query)
      conflicts: (ontology-declaration-values .add-conflict '.add-conflict)
      threat-model:
      (poo-flow-governance-threat-model
       (string-append identity "/threat-model")
       (ontology-declaration-values .add-threat '.add-threat))
      .project:
      (lambda (profile)
        (.o identity: (.ref profile 'identity)
            name: (.ref profile 'name)
            profile-scope: (.ref profile 'profile-scope)
            scenario: (.ref profile 'scenario)
            imports: (map (lambda (value) (.ref value 'identity))
                          (.ref profile 'imports))
            sources: (map (lambda (value) (.ref value 'identity))
                          (.ref profile 'source-assets))
            capabilities:
            (map (lambda (value) (.ref value 'identity))
                 (.ref profile 'capabilities))
            ontology:
            (.o concepts:
                (map (lambda (semantic)
                       (ontology-semantic-project semantic semantic))
                     (.ref (.ref profile 'ontology) 'concepts))
                relations:
                (map (lambda (semantic)
                       (ontology-semantic-project semantic semantic))
                     (.ref (.ref profile 'ontology) 'relations)))
            terms: (.ref profile 'terms)
            rules:
            (map (lambda (rule)
                   (ontology-semantic-project rule rule))
                 (.ref profile 'rules))
            queries: (.ref profile 'queries)))))
