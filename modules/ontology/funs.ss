;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .cc .o .ref object?)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map every filter find)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph-edge-from poo-flow-graph-edge-kind
                 poo-flow-graph-edge-to poo-flow-graph-edges
                 poo-flow-graph-node-id poo-flow-graph-node-payload
                 poo-flow-graph-nodes)
        (only-in :poo-flow/src/module-system/profile-composition/interface
                 poo-flow-composition?
                 poo-flow-composition-object/profiles
                 poo-flow-composition-profiles)
        (only-in :poo-flow/src/modules/governance/funs
                 poo-flow-governance-evaluate)
        (only-in :poo-flow/lambda-episteme/modules/ontology/types
                 ontology-case? ontology-case-composition-receipt?
                 ontology-profile? ontology-source?)
        (only-in :poo-flow/lambda-episteme/modules/ontology/objects
                 ontology-profile-project ontology-rule-evaluate
                 ontology-scenario-admits-profile?))

(export ontology-compose-case
        ontology-evaluate-case
        ontology-remove-case-profile
        ontology-case-diagnostic-codes
        ontology-evaluation-diagnostic-codes)

(def (ontology-diagnostic code-value path-value detail-value)
  (.o kind: 'lambda-episteme.ontology-diagnostic
      code: code-value path: path-value detail: detail-value))

(def (ontology-case-diagnostic-codes receipt)
  (map (lambda (diagnostic) (.ref diagnostic 'code))
       (.ref receipt 'diagnostics)))

(def (ontology-index-profiles profiles)
  (let ((index (make-hash-table))
        (ordered '())
        (diagnostics '()))
    (for-each
     (lambda (profile)
       (if (not (ontology-profile? profile))
         (set! diagnostics
               (cons (ontology-diagnostic
                      'invalid-profile '(profiles) profile)
                     diagnostics))
         (let* ((identity (.ref profile 'identity))
                (existing (hash-get index identity)))
           (cond
            ((not existing)
             (hash-put! index identity profile)
             (set! ordered (cons profile ordered)))
            ((not (eq? existing profile))
             (set! diagnostics
                   (cons (ontology-diagnostic
                          'duplicate-profile-identity
                          (list 'profiles identity)
                          profile)
                         diagnostics)))))))
     profiles)
    (values index (reverse ordered) (reverse diagnostics))))

(def (ontology-profile-import-diagnostics profile index)
  (append-map
   (lambda (imported)
     (let* ((identity (.ref imported 'identity))
            (selected (hash-get index identity))
            (profile-scope (.ref profile 'profile-scope))
            (import-scope (.ref imported 'profile-scope)))
       (append
        (if selected
          (if (eq? selected imported)
            '()
            (list
             (ontology-diagnostic
              'profile-import-identity-mismatch
              (list 'profiles (.ref profile 'identity) 'imports identity)
              imported)))
          (list
           (ontology-diagnostic
            'missing-profile-import
            (list 'profiles (.ref profile 'identity) 'imports identity)
            imported)))
        (cond
         ((and (eq? profile-scope 'common)
               (eq? import-scope 'scenario))
          (list
           (ontology-diagnostic
            'common-profile-imports-scenario-profile
            (list 'profiles (.ref profile 'identity) 'imports identity)
            (.ref imported 'scenario))))
         ((and (eq? profile-scope 'scenario)
               (eq? import-scope 'scenario)
               (not (eq? (.ref profile 'scenario)
                         (.ref imported 'scenario))))
          (list
           (ontology-diagnostic
            'cross-scenario-profile-import
            (list 'profiles (.ref profile 'identity) 'imports identity)
            (.ref imported 'scenario))))
         (else '())))))
   (.ref profile 'imports)))

(def (ontology-profile-source-diagnostics profile)
  (append-map
   (lambda (source)
     (let ((profile-scope (.ref profile 'profile-scope))
           (source-scope (.ref source 'source-scope)))
       (cond
        ((eq? source-scope 'case)
         (list
          (ontology-diagnostic
           'profile-imports-case-source
           (list 'profiles (.ref profile 'identity) 'sources)
           (.ref source 'identity))))
        ((and (eq? profile-scope 'common)
              (not (eq? source-scope 'common)))
         (list
          (ontology-diagnostic
           'common-profile-imports-scenario-source
           (list 'profiles (.ref profile 'identity) 'sources)
           (.ref source 'identity))))
        ((and (eq? profile-scope 'scenario)
              (eq? source-scope 'scenario)
              (not (eq? (.ref profile 'scenario)
                        (.ref source 'scenario))))
         (list
          (ontology-diagnostic
           'profile-imports-cross-scenario-source
           (list 'profiles (.ref profile 'identity) 'sources)
           (.ref source 'identity))))
        (else '()))))
   (.ref profile 'source-assets)))

(def (ontology-profile-conflict-diagnostics profile index)
  (append-map
   (lambda (identity)
     (if (hash-get index identity)
       (list
        (ontology-diagnostic
         'selected-profile-conflict
         (list 'profiles (.ref profile 'identity) 'conflicts identity)
         identity))
       '()))
   (.ref profile 'conflicts)))

;;; The semantic closure is indexed once per Case.  This is the native POO
;;; replacement for reparsing RDF graphs: every declaration and reference is
;;; admitted with O(1) expected lookup after the two identity indexes exist.
(def (ontology-semantic-environment profiles)
  (let ((concept-index (make-hash-table))
        (relation-index (make-hash-table))
        (rule-index (make-hash-table))
        (rules '())
        (diagnostics '()))
    (for-each
     (lambda (profile)
       (let (vocabulary (.ref profile 'ontology))
         (for-each
          (lambda (concept)
            (let ((identity (.ref concept 'identity)))
              (if (hash-get concept-index identity)
                (set! diagnostics
                      (cons (ontology-diagnostic
                             'duplicate-concept-identity
                             (list 'profiles (.ref profile 'identity)
                                   'ontology 'concepts identity)
                             identity)
                            diagnostics))
                (hash-put! concept-index identity concept))))
          (.ref vocabulary 'concepts))
         (for-each
          (lambda (relation)
            (let ((identity (.ref relation 'identity)))
              (if (hash-get relation-index identity)
                (set! diagnostics
                      (cons (ontology-diagnostic
                             'duplicate-relation-identity
                             (list 'profiles (.ref profile 'identity)
                                   'ontology 'relations identity)
                             identity)
                            diagnostics))
                (hash-put! relation-index identity relation))))
          (.ref vocabulary 'relations))
         (for-each
          (lambda (rule)
            (let (identity (.ref rule 'identity))
              (if (hash-get rule-index identity)
                (set! diagnostics
                      (cons (ontology-diagnostic
                             'duplicate-rule-identity
                             (list 'profiles (.ref profile 'identity)
                                   'rules identity)
                             identity)
                            diagnostics))
                (begin
                  (hash-put! rule-index identity rule)
                  (set! rules (cons rule rules))))))
          (.ref profile 'rules))))
     profiles)
    (for-each
     (lambda (profile)
       (let (vocabulary (.ref profile 'ontology))
         (for-each
          (lambda (concept)
            (for-each
             (lambda (parent)
               (unless (hash-get concept-index parent)
                 (set! diagnostics
                       (cons (ontology-diagnostic
                              'unresolved-concept-parent
                              (list 'profiles (.ref profile 'identity)
                                    'ontology 'concepts
                                    (.ref concept 'identity) 'parents)
                              parent)
                             diagnostics))))
             (.ref concept 'parents)))
          (.ref vocabulary 'concepts))
         (for-each
          (lambda (relation)
            (for-each
             (lambda (endpoint)
               (let ((role (car endpoint)) (identity (cdr endpoint)))
                 (unless (hash-get concept-index identity)
                   (set! diagnostics
                         (cons (ontology-diagnostic
                                'unresolved-relation-endpoint
                                (list 'profiles (.ref profile 'identity)
                                      'ontology 'relations
                                      (.ref relation 'identity) role)
                                identity)
                               diagnostics)))))
             (list (cons 'domain (.ref relation 'domain))
                   (cons 'range (.ref relation 'range)))))
          (.ref vocabulary 'relations))))
     profiles)
    (let ((environment-concept-index concept-index)
          (environment-relation-index relation-index)
          (environment-rules (reverse rules))
          (environment-diagnostics (reverse diagnostics)))
      (.o kind: 'lambda-episteme.ontology-semantic-environment
          concept-index: environment-concept-index
          relation-index: environment-relation-index
          rules: environment-rules
          diagnostics: environment-diagnostics))))

(def (ontology-order-profiles profiles index)
  (let ((states (make-hash-table))
        (ordered '())
        (diagnostics '()))
    (def (visit profile)
      (let* ((identity (.ref profile 'identity))
             (state (hash-get states identity)))
        (cond
         ((eq? state 'visited) (void))
         ((eq? state 'visiting)
          (set! diagnostics
                (cons
                 (ontology-diagnostic
                  'cyclic-profile-import
                  (list 'profiles identity 'imports)
                  identity)
                 diagnostics)))
         (else
          (hash-put! states identity 'visiting)
          (for-each
           (lambda (imported)
             (let (selected (hash-get index (.ref imported 'identity)))
               (when (and selected (eq? selected imported))
                 (visit selected))))
           (.ref profile 'imports))
          (hash-put! states identity 'visited)
          (set! ordered (cons profile ordered))))))
    (for-each visit profiles)
    (values (reverse ordered) (reverse diagnostics))))

(def (ontology-case-source-diagnostics case-id scenario sources)
  (append-map
   (lambda (source)
     (cond
      ((not (ontology-source? source))
       (list
        (ontology-diagnostic
         'invalid-case-source (list 'cases case-id 'sources) source)))
      ((not (eq? (.ref source 'source-scope) 'case))
       (list
        (ontology-diagnostic
         'case-source-has-non-case-scope
         (list 'cases case-id 'sources)
         (.ref source 'identity))))
      ((or (not (eq? (.ref source 'scenario) scenario))
           (not (eq? (.ref source 'case-id) case-id)))
       (list
        (ontology-diagnostic
         'case-source-owner-mismatch
         (list 'cases case-id 'sources)
         (.ref source 'identity))))
      (else '())))
   sources))

(def (ontology-profile-projection profile)
  (ontology-profile-project profile profile))

;; Build the reverse dependency graph once, then visit each selected Profile
;; and import edge at most once while collecting every removal blocker.
(def (ontology-profile-removal-blockers profiles identity)
  (let ((reverse-imports (make-hash-table))
        (visited (make-hash-table))
        (ordered '()))
    (for-each
     (lambda (profile)
       (for-each
        (lambda (imported)
          (let* ((import-identity (.ref imported 'identity))
                 (dependents
                  (or (hash-get reverse-imports import-identity) '())))
            (hash-put! reverse-imports import-identity
                       (cons profile dependents))))
        (.ref profile 'imports)))
     profiles)
    (def (visit imported-identity)
      (for-each
       (lambda (dependent)
         (let (dependent-identity (.ref dependent 'identity))
           (unless (hash-get visited dependent-identity)
             (hash-put! visited dependent-identity #t)
             (set! ordered (cons dependent ordered))
             (visit dependent-identity))))
       (reverse (or (hash-get reverse-imports imported-identity) '()))))
    (visit identity)
    (reverse ordered)))

(def (ontology-rejected-removal-receipt receipt code detail)
  (let ((receipt-case (.ref receipt 'case))
        (receipt-case-id (.ref receipt 'case-id))
        (receipt-scenario (.ref receipt 'scenario))
        (receipt-compositions (.ref receipt 'compositions))
        (receipt-diagnostic
         (ontology-diagnostic
          code
          (list 'cases (.ref receipt 'case-id) 'profiles)
          detail)))
    (.o kind: 'lambda-episteme.ontology-case-composition-receipt
        accepted?: #f
        case: receipt-case
        case-id: receipt-case-id
        scenario: receipt-scenario
        compositions: receipt-compositions
        profiles: '()
        sources: '()
        environment: (.ref receipt 'environment)
        governance-assessments: '()
        governance-handoff-ready?: #f
        projection: '()
        diagnostics: (list receipt-diagnostic)
        runtime-executed?: #f)))

(def (ontology-remove-case-profile receipt identity)
  (unless (ontology-case-composition-receipt? receipt)
    (error "invalid ontology Case composition receipt" receipt))
  (let* ((selected-profiles (.ref receipt 'profiles))
         (selected
          (find (lambda (profile)
                  (equal? (.ref profile 'identity) identity))
                selected-profiles)))
    (if (not selected)
      (ontology-rejected-removal-receipt
       receipt 'profile-not-selected identity)
      (let (blockers
            (ontology-profile-removal-blockers selected-profiles identity))
        (if (pair? blockers)
          (ontology-rejected-removal-receipt
           receipt
           'profile-removal-blocked
           (sort
            (map (lambda (profile) (.ref profile 'identity)) blockers)
            string<?))
          (let ((remaining
                 (filter
                  (lambda (profile)
                    (not (equal? (.ref profile 'identity) identity)))
                  selected-profiles)))
            (ontology-compose-case
             (.cc (.ref receipt 'case)
                  compositions:
                  (list
                   (poo-flow-composition-object/profiles
                    'ontology-profile-removal '() remaining '()))
                  sources: (.ref receipt 'sources)))))))))

(def (ontology-compose-case case-value)
  (unless (ontology-case? case-value)
    (error "invalid ontology Case" case-value))
  (ontology-compose-case-value case-value))

(def (ontology-compose-case-value case-value)
  (let* ((case-id (.ref case-value 'case-id))
         (scenario-definition (.ref case-value 'scenario))
         (scenario (.ref scenario-definition 'identity))
         (compositions (.ref case-value 'compositions))
         (case-sources (.ref case-value 'sources)))
    (let* ((input-diagnostics
          (append
           (if (and (list? compositions) (pair? compositions)
                    (every poo-flow-composition? compositions))
             '()
             (list (ontology-diagnostic
                    'invalid-case-compositions '(compositions)
                    compositions)))
           (if (list? case-sources) '()
             (list (ontology-diagnostic
                    'invalid-case-sources '(sources) case-sources)))))
         (profile-values
          (if (null? input-diagnostics)
            (append-map poo-flow-composition-profiles compositions)
            '())))
    (let-values (((profile-index selected-profiles index-diagnostics)
                  (ontology-index-profiles profile-values)))
      (let-values (((profiles cycle-diagnostics)
                    (ontology-order-profiles selected-profiles profile-index)))
        (let* ((semantic-environment
                (ontology-semantic-environment profiles))
               (profile-diagnostics
                (append
                 (append-map
                  (lambda (profile)
                    (append
                     (if (ontology-scenario-admits-profile?
                          scenario-definition profile)
                       '()
                       (list
                        (ontology-diagnostic
                         'profile-outside-case-scenario
                         (list 'cases case-id 'profiles)
                         (.ref profile 'identity))))
                     (ontology-profile-import-diagnostics profile profile-index)
                     (ontology-profile-source-diagnostics profile)
                     (ontology-profile-conflict-diagnostics profile profile-index)))
                  profiles)
                 cycle-diagnostics
                 (.ref semantic-environment 'diagnostics)))
             (source-diagnostics
              (if (list? case-sources)
                (ontology-case-source-diagnostics
                 case-id scenario case-sources)
                '()))
             (pre-governance-diagnostics
              (append input-diagnostics index-diagnostics
                      profile-diagnostics source-diagnostics))
             (governance-assessments
              (if (null? pre-governance-diagnostics)
                (map (lambda (profile)
                       (poo-flow-governance-evaluate profile case-value))
                     profiles)
                '()))
             (governance-diagnostics
              (append-map
               (lambda (assessment)
                 (if (.ref assessment 'handoff-ready?)
                   '()
                   (list
                    (ontology-diagnostic
                     'governance-handoff-blocked
                     (list 'cases case-id 'governance
                           (.ref assessment 'profile-identity))
                     (.ref assessment 'unresolved-threats)))))
               governance-assessments))
             (diagnostics
              (append pre-governance-diagnostics governance-diagnostics))
             (accepted? (null? diagnostics))
             ;; `.o` evaluates slot expressions in the object's slot scope.
             ;; Keep receipt values under distinct lexical names so a slot such
             ;; as `compositions` cannot recursively resolve itself.
             (receipt-accepted? accepted?)
             (receipt-case case-value)
             (receipt-case-id case-id)
             (receipt-scenario scenario)
             (receipt-compositions
              (if (list? compositions) compositions '()))
             (receipt-profiles (if accepted? profiles '()))
             (receipt-sources
              (if (and accepted? (list? case-sources)) case-sources '()))
             (receipt-environment semantic-environment)
             (receipt-governance-assessments governance-assessments)
             (receipt-governance-handoff-ready?
              (and (pair? governance-assessments)
                   (every (lambda (assessment)
                            (.ref assessment 'handoff-ready?))
                          governance-assessments)))
             (receipt-projection
              (if accepted?
                (map ontology-profile-projection profiles)
                '()))
             (receipt-diagnostics diagnostics))
          (.o kind: 'lambda-episteme.ontology-case-composition-receipt
              accepted?: receipt-accepted?
              case: receipt-case
              case-id: receipt-case-id
              scenario: receipt-scenario
              compositions: receipt-compositions
              profiles: receipt-profiles
              sources: receipt-sources
              environment: receipt-environment
              governance-assessments: receipt-governance-assessments
              governance-handoff-ready?: receipt-governance-handoff-ready?
              projection: receipt-projection
              diagnostics: receipt-diagnostics
              runtime-executed?: #f)))))))

(def (ontology-evaluation-diagnostic-codes receipt)
  (map (lambda (diagnostic) (.ref diagnostic 'code))
       (.ref receipt 'diagnostics)))

(def (ontology-graph-diagnostics environment graph)
  (let ((node-index (make-hash-table))
        (diagnostics '())
        (concept-index (.ref environment 'concept-index))
        (relation-index (.ref environment 'relation-index)))
    (for-each
     (lambda (node)
       (let (identity (poo-flow-graph-node-id node))
         (if (hash-get node-index identity)
           (set! diagnostics
                 (cons (ontology-diagnostic
                        'duplicate-graph-node (list 'graph 'nodes identity) node)
                       diagnostics))
           (hash-put! node-index identity node))
         (unless (hash-get concept-index (poo-flow-graph-node-payload node))
           (set! diagnostics
                 (cons (ontology-diagnostic
                        'unknown-node-concept
                        (list 'graph 'nodes identity 'payload)
                        (poo-flow-graph-node-payload node))
                       diagnostics)))))
     (poo-flow-graph-nodes graph))
    (for-each
     (lambda (edge)
       (let ((relation (poo-flow-graph-edge-kind edge))
             (source (poo-flow-graph-edge-from edge))
             (target (poo-flow-graph-edge-to edge)))
         (unless (hash-get relation-index relation)
           (set! diagnostics
                 (cons (ontology-diagnostic
                        'unknown-edge-relation
                        (list 'graph 'edges source target 'edge-kind)
                        relation)
                       diagnostics)))
         (for-each
          (lambda (endpoint)
            (unless (hash-get node-index (cdr endpoint))
              (set! diagnostics
                    (cons (ontology-diagnostic
                           'unknown-edge-endpoint
                           (list 'graph 'edges source target (car endpoint))
                           (cdr endpoint))
                          diagnostics))))
          (list (cons 'source source) (cons 'target target)))))
     (poo-flow-graph-edges graph))
    (reverse diagnostics)))

(def (ontology-evaluate-case composition-receipt)
  (unless (ontology-case-composition-receipt? composition-receipt)
    (error "invalid ontology composition receipt" composition-receipt))
  (let* ((graph (.ref (.ref composition-receipt 'case) 'graph))
         (environment (.ref composition-receipt 'environment))
         (composition-diagnostics
          (if (.ref composition-receipt 'accepted?)
            '()
            (list (ontology-diagnostic
                   'composition-rejected '(composition)
                   (ontology-case-diagnostic-codes composition-receipt)))))
         (graph-diagnostics
          (if (null? composition-diagnostics)
            (ontology-graph-diagnostics environment graph)
            '()))
         (rule-diagnostics
          (if (and (null? composition-diagnostics)
                   (null? graph-diagnostics))
            (append-map
             (lambda (rule) (ontology-rule-evaluate rule rule graph))
             (.ref environment 'rules))
            '()))
         (diagnostics
          (append composition-diagnostics graph-diagnostics rule-diagnostics))
         (evaluation-accepted? (null? diagnostics))
         (evaluation-composition composition-receipt)
         (evaluation-graph graph)
         (evaluation-diagnostics diagnostics))
    (.o kind: 'lambda-episteme.ontology-case-evaluation-receipt
        accepted?: evaluation-accepted?
        composition: evaluation-composition
        graph: evaluation-graph
        diagnostics: evaluation-diagnostics
        runtime-executed?: #t)))
