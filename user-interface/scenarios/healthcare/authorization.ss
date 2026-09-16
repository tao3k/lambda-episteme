;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Healthcare owns vertical authorization meaning. The Cedar Provider owns
;;; standard policy/schema parsing and dual-engine execution.
(import (only-in :clan/poo/object .cc .o .ref .slot? object?)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/1 every find)
        (only-in :std/text/hex hex-encode)
        (only-in :std/text/json json-object->string)
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph-edge-from poo-flow-graph-edge-kind
                 poo-flow-graph-edge-to poo-flow-graph-edges
                 poo-flow-graph-node-id poo-flow-graph-node-payload
                 poo-flow-graph-nodes)
        (only-in :poo-flow/src/modules/authorization/types
                 poo-flow-authorization-capability?)
        (only-in :poo-flow/src/modules/authorization/contracts
                 poo-flow-authorization-capability-contract
                 poo-flow-authorization-capabilities-digest)
        (only-in :poo-flow/src/modules/authorization/providers/cedar/interface
                 CedarDualEngineAuthorizationProvider
                 poo-flow-cedar-authorization-request
                 poo-flow-cedar-authority-context?
                 poo-flow-cedar-entities
                 poo-flow-cedar-governance-snapshot
                 poo-flow-cedar-policy
                 poo-flow-cedar-proof-binding?
                 poo-flow-cedar-runtime-capability
                 poo-flow-cedar-runtime-handoff?
                 poo-flow-cedar-schema)
        (only-in :poo-flow/lambda-episteme/modules/ontology/types
                 ontology-case-composition-receipt? ontology-source?)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/assurance
                 healthcare-case-assurance?
                 healthcare-case-assurance-digest)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization-projection
                 healthcare-cedar-governance-projection-canonical))

(export healthcare-medication-administration
        healthcare-medication-administration?
        healthcare-profile-origin-digest
        healthcare-profile-bundle-digest
        healthcare-authorization-capability-digest
        healthcare-authorization-subject-digest
        healthcare-case-cedar-snapshot
        healthcare-case-cedar-request)

(def +medication-policy-source+
  "healthcare/medication/authorization/policy")
(def +medication-schema-source+
  "healthcare/medication/authorization/schema")
(def +medication-revocation-source+
  "healthcare/medication/authorization/revocation")
(def +medication-profile+
  "lambda-episteme/ontology/healthcare/medication-safety")

(def (text? value)
  (and (string? value) (> (string-length value) 0)))

(def (healthcare-medication-administration provider-value patient-value
                                           encounter-value order-value
                                           reconciliation-observed-value
                                           revoked-value)
  (unless (and (every text? (list provider-value patient-value
                                  encounter-value order-value))
               (boolean? reconciliation-observed-value)
               (boolean? revoked-value))
    (error "invalid Healthcare medication authorization declaration"
           order-value))
  (.o kind: 'lambda-episteme.healthcare.medication-administration
      provider: provider-value patient: patient-value
      encounter: encounter-value order: order-value
      reconciliation-observed?: reconciliation-observed-value
      revoked?: revoked-value runtime-executed?: #f))

(def (healthcare-medication-administration? value)
  (and (object? value)
       (every (lambda (slot) (.slot? value slot))
              '(kind provider patient encounter order reconciliation-observed?
                revoked? runtime-executed?))
       (eq? (.ref value 'kind)
            'lambda-episteme.healthcare.medication-administration)
       (every text? (map (lambda (slot) (.ref value slot))
                         '(provider patient encounter order)))
       (boolean? (.ref value 'reconciliation-observed?))
       (boolean? (.ref value 'revoked?))
       (eq? (.ref value 'runtime-executed?) #f)))

(def (digest datum)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (call-with-output-string (lambda (port) (write datum port)))))))

(def (healthcare-profile-origin-digest receipt root)
  (unless (ontology-case-composition-receipt? receipt)
    (error "Healthcare origin digest requires a Case receipt" receipt))
  (digest
   (list
    'lambda-episteme.healthcare.profile-origin.v1
    (map
     (lambda (profile)
       (list
        (.ref profile 'identity)
        (.ref profile 'revision)
        (map
         (lambda (source)
           (list (.ref source 'identity)
                 (.ref source 'path)
                 (.ref source 'language)
                 (digest
                  (call-with-input-file
                   (path-expand (.ref source 'path) root)
                   read-all-as-string))))
         (.ref profile 'source-assets))))
     (.ref receipt 'profiles)))))

(def (healthcare-profile-bundle-digest receipt)
  (unless (ontology-case-composition-receipt? receipt)
    (error "Healthcare Profile digest requires a Case receipt" receipt))
  (digest
   (list
    'lambda-episteme.healthcare.profile-bundle.v1
    (map
     (lambda (profile)
       (list
        (.ref profile 'identity)
        (.ref profile 'revision)
        (map (lambda (imported) (.ref imported 'identity))
             (.ref profile 'imports))
        (map (lambda (capability)
               (list (.ref capability 'identity)
                     (.ref capability 'action)
                     (.ref capability 'event-kind)
                     (.ref capability 'risk)))
             (.ref profile 'capabilities))
        (map (lambda (threat)
               (list (.ref threat 'identity)
                     (.ref threat 'severity)
                     (.ref threat 'phase)))
             (.ref (.ref profile 'threat-model) 'threats))))
     (.ref receipt 'profiles)))))

(def (healthcare-authorization-subject-digest receipt authorization)
  (unless (and (ontology-case-composition-receipt? receipt)
               (healthcare-medication-administration? authorization))
    (error "Healthcare subject digest requires an admitted Case receipt"
           authorization))
  (let (graph (.ref (.ref receipt 'case) 'graph))
    (digest
     (list 'lambda-episteme.healthcare.authorization-subject.v1
           (.ref receipt 'case-id)
           (map (lambda (node)
                  (list (poo-flow-graph-node-id node)
                        (poo-flow-graph-node-payload node)))
                (poo-flow-graph-nodes graph))
           (map (lambda (edge)
                  (list (poo-flow-graph-edge-from edge)
                        (poo-flow-graph-edge-to edge)
                        (poo-flow-graph-edge-kind edge)))
                (poo-flow-graph-edges graph))
           (map (lambda (slot) (.ref authorization slot))
                '(provider patient encounter order reconciliation-observed?
                  revoked?))
           (healthcare-cedar-governance-projection-canonical receipt)))))

(def (record . fields)
  (let (value (make-hash-table))
    (for-each (lambda (field) (hash-put! value (car field) (cdr field))) fields)
    value))

(def (entity-ref type identity)
  (record (cons "__entity"
                (record (cons "type" type) (cons "id" identity)))))

(def (entity type identity attributes)
  (record (cons "uid" (record (cons "type" type) (cons "id" identity)))
          (cons "attrs" attributes)
          (cons "parents" '#())))

(def (healthcare-entities authorization)
  (json-object->string
   (vector
    (entity "Healthcare::Provider" (.ref authorization 'provider) (record))
    (entity "Healthcare::Patient" (.ref authorization 'patient) (record))
    (entity "Healthcare::Encounter" (.ref authorization 'encounter) (record))
    (entity
     "Healthcare::MedicationOrder" (.ref authorization 'order)
     (record
      (cons "assignedProvider"
            (entity-ref "Healthcare::Provider" (.ref authorization 'provider)))
      (cons "patient"
            (entity-ref "Healthcare::Patient" (.ref authorization 'patient)))
      (cons "encounter"
            (entity-ref "Healthcare::Encounter" (.ref authorization 'encounter)))
      (cons "reconciliationObserved"
            (.ref authorization 'reconciliation-observed?))
      (cons "revoked" (.ref authorization 'revoked?)))))))

(def (source-by-identity profiles identity)
  (find (lambda (source) (equal? (.ref source 'identity) identity))
        (apply append (map (lambda (profile) (.ref profile 'source-assets))
                           profiles))))

(def (source-text root profiles identity expected-language)
  (let (source (source-by-identity profiles identity))
    (unless (and source (ontology-source? source)
                 (eq? (.ref source 'language) expected-language))
      (error "Healthcare Cedar Source is absent or has the wrong language"
             identity))
    (call-with-input-file
     (path-expand (.ref source 'path) root)
     read-all-as-string)))

(def (medication-capability profiles)
  (let* ((profile
          (find (lambda (candidate)
                  (equal? (.ref candidate 'identity) +medication-profile+))
                profiles))
         (capability
          (and profile
               (find poo-flow-authorization-capability?
                     (.ref profile 'capabilities)))))
    (unless capability
      (error "Medication Safety capability is absent" +medication-profile+))
    capability))

(def (healthcare-authorization-capability-digest receipt)
  (unless (ontology-case-composition-receipt? receipt)
    (error "Healthcare capability digest requires a Case receipt" receipt))
  (poo-flow-authorization-capabilities-digest
   CedarDualEngineAuthorizationProvider
   (list (medication-capability (.ref receipt 'profiles)))))

(def (healthcare-case-cedar-snapshot
      receipt assurance root authority-context proof-binding)
  (unless (and (ontology-case-composition-receipt? receipt)
               (.ref receipt 'accepted?)
               (.ref receipt 'governance-handoff-ready?)
               (healthcare-case-assurance? assurance)
               (eq? (.ref assurance 'case-id) (.ref receipt 'case-id))
               (poo-flow-cedar-authority-context? authority-context)
               (poo-flow-cedar-proof-binding? proof-binding))
    (error "Healthcare Cedar snapshot requires an assurance-closed admitted Case"
           receipt))
  (let* ((profiles (.ref receipt 'profiles))
         (authorization (car (.ref (.ref receipt 'case) 'authorizations)))
         (capability (medication-capability profiles)))
    (unless (healthcare-medication-administration? authorization)
      (error "Healthcare Case requires medication authorization" authorization))
    (unless (equal?
             (healthcare-authorization-subject-digest receipt authorization)
             (.ref proof-binding 'subject-snapshot))
      (error "Healthcare subject snapshot does not match Cedar proof binding"
             (.ref proof-binding 'subject-snapshot)))
    (unless (equal? (healthcare-case-assurance-digest assurance)
                    (.ref proof-binding 'independent-bundle))
      (error "Healthcare assurance does not match Cedar proof binding"
             (.ref proof-binding 'independent-bundle)))
    (let (capability-contract
          (poo-flow-authorization-capability-contract
           CedarDualEngineAuthorizationProvider (list capability)))
      (unless (equal? (.ref capability-contract 'contract-digest)
                      (.ref proof-binding 'capability-contract))
        (error "Healthcare capability contract does not match Cedar proof binding"
               (.ref proof-binding 'capability-contract))))
    (.cc
     (poo-flow-cedar-governance-snapshot
      (symbol->string (.ref receipt 'case-id))
      profiles
      (.ref receipt 'governance-assessments)
      authority-context
      proof-binding
      (list
       (poo-flow-cedar-policy
        "healthcare-medication-permit"
        (source-text root profiles +medication-policy-source+ 'cedar))
       (poo-flow-cedar-policy
        "healthcare-medication-revocation"
        (source-text root profiles +medication-revocation-source+ 'cedar)))
      (poo-flow-cedar-schema
       (source-text root profiles +medication-schema-source+ 'json))
      (poo-flow-cedar-entities (healthcare-entities authorization))
      (list
       (poo-flow-cedar-runtime-capability
        (.ref capability 'action) (.ref capability 'event-kind))))
     'assurance assurance)))

(def (healthcare-case-cedar-request receipt assurance intent handoff)
  (unless (and (ontology-case-composition-receipt? receipt)
               (.ref receipt 'accepted?)
               (healthcare-case-assurance? assurance)
               (eq? (.ref assurance 'case-id) (.ref receipt 'case-id))
               (poo-flow-cedar-runtime-handoff? handoff))
    (error "Healthcare Cedar request requires assurance closure and handoff"))
  (let (authorization (car (.ref (.ref receipt 'case) 'authorizations)))
    (unless (healthcare-medication-administration? authorization)
      (error "Healthcare Case requires medication authorization" authorization))
    (poo-flow-cedar-authorization-request
     (string-append "Healthcare::Provider::\""
                    (.ref authorization 'provider) "\"")
     "Healthcare::Action::\"administerMedication\""
     (string-append "Healthcare::MedicationOrder::\""
                    (.ref authorization 'order) "\"")
     (.o assurance_digest: (healthcare-case-assurance-digest assurance)
         assurance_closed: #t)
     intent
     handoff)))
