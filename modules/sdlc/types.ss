(import (only-in :clan/poo/object .ref .slot? object?)
        :poo-flow/src/module-system/contribution/model
        :poo-flow/lambda-episteme/governance/objects
        (only-in :std/srfi/1 every)
        (only-in :std/misc/list delete-duplicates/hash))
(export standard-profile? sdlc-profile? sdlc-text?
        SdlcStandard SdlcBoundFact SdlcProject SdlcObligation SdlcEvidence
        SdlcTailoringRequest SdlcTraceNode SdlcTraceEdge SdlcTraceRule
        sdlc-bound-fact? sdlc-project? sdlc-obligation? sdlc-evidence?
        sdlc-tailoring-request? sdlc-trace-node? sdlc-trace-edge? sdlc-trace-rule?)

(def (sdlc-text? value) (and (string? value) (> (string-length value) 0)))
(def (text-slots names)
  (map (lambda (name) (poo-clos-direct-slot-definition name type-predicate: sdlc-text?)) names))
(def (enum-slot name choices)
  (poo-clos-direct-slot-definition name
    type-predicate: (lambda (value) (if (memq value choices) #t #f))))
(def (requirements? values)
  (and (list? values)
       (every (lambda (r) (and (object? r) (.slot? r 'identity)
                               (sdlc-text? (.ref r 'identity)))) values)
       (let (ids (map (lambda (r) (.ref r 'identity)) values))
         (= (length ids) (length (delete-duplicates/hash ids))))))

;;; CLOS owns inheritance and effective-slot conjunction; declarations are
;;; ordinary native class and slot metaobjects, with no contribution DSL.
(def SdlcSubject
  (poo-clos-class 'sdlc/subject direct-slots: (text-slots '(subject revision))))
(def SdlcBoundFact
  (poo-clos-class 'sdlc/bound-fact direct-superclasses: (list SdlcSubject)
    direct-slots: (text-slots '(scope))))
(def SdlcClause
  (poo-clos-class 'sdlc/clause direct-slots: (text-slots '(standard requirement))))
(def SdlcIdentified
  (poo-clos-class 'sdlc/identified direct-slots: (text-slots '(identity))))
(def SdlcStandard
  (poo-clos-class 'sdlc/standard direct-superclasses: (list SdlcIdentified)
    direct-slots: (append (text-slots '(edition source-url))
      (list (enum-slot 'coverage '(partial complete))
            (enum-slot 'assessment '(not-evaluated))
            (poo-clos-direct-slot-definition 'requirements type-predicate: requirements?)))))
(def SdlcProject
  (poo-clos-class 'sdlc/project direct-superclasses: (list SdlcBoundFact)
    direct-slots: (list (poo-clos-direct-slot-definition 'complete? type-predicate: boolean?))))
(def SdlcObligation
  (poo-clos-class 'sdlc/obligation direct-superclasses: (list SdlcClause)
    direct-slots: (list (enum-slot 'applicability '(applicable unknown not-applicable)))))
(def SdlcEvidence
  (poo-clos-class 'sdlc/evidence direct-superclasses: (list SdlcBoundFact SdlcClause SdlcIdentified)
    direct-slots: (append (text-slots '(producer)) (list (enum-slot 'outcome '(pass fail))))))
(def SdlcTailoringRequest
  (poo-clos-class 'sdlc/tailoring-request direct-superclasses: (list SdlcSubject SdlcClause)
    direct-slots: (text-slots '(rationale))))
(def SdlcTraceNode
  (poo-clos-class 'sdlc/trace-node direct-superclasses: (list SdlcBoundFact SdlcIdentified)
    direct-slots: (list (poo-clos-direct-slot-definition 'category type-predicate: symbol?))))
(def SdlcTraceEdge
  (poo-clos-class 'sdlc/trace-edge direct-superclasses: (list SdlcBoundFact SdlcIdentified)
    direct-slots: (text-slots '(source target relation))))
(def SdlcTraceRule
  (poo-clos-class 'sdlc/trace-rule direct-superclasses: (list SdlcIdentified)
    direct-slots: (map (lambda (name) (poo-clos-direct-slot-definition name type-predicate: symbol?))
                       '(source-category target-category))))

(def (sdlc-profile? value)
  (and (governance-profile? value) (.slot? value 'standards)
       (list? (.ref value 'standards))
       (every standard-profile? (.ref value 'standards))
       (let ((ids (map (lambda (s) (.ref s 'identity)) (.ref value 'standards))))
         (= (length ids) (length (delete-duplicates/hash ids))))))
(def (standard-profile? value) (poo-flow-model? SdlcStandard value))
(def (sdlc-bound-fact? value) (poo-flow-model? SdlcBoundFact value))
(def (sdlc-project? value) (poo-flow-model? SdlcProject value))
(def (sdlc-obligation? value) (poo-flow-model? SdlcObligation value))
(def (sdlc-evidence? value) (poo-flow-model? SdlcEvidence value))
(def (sdlc-tailoring-request? value) (poo-flow-model? SdlcTailoringRequest value))
(def (sdlc-trace-node? value) (poo-flow-model? SdlcTraceNode value))
(def (sdlc-trace-edge? value) (poo-flow-model? SdlcTraceEdge value))
(def (sdlc-trace-rule? value) (poo-flow-model? SdlcTraceRule value))

(export SdlcCriterionEvidence sdlc-criterion-evidence?
        SdlcSafetyComponent sdlc-safety-component?)
(def SdlcCriterionEvidence
  (poo-clos-class 'sdlc/criterion-evidence direct-superclasses: (list SdlcEvidence)
    direct-slots: (text-slots '(criterion source-digest))))
(def (sdlc-criterion-evidence? value) (poo-flow-model? SdlcCriterionEvidence value))
(def (coverage-or-unknown? value)
  (or (eq? value 'unknown) (and (real? value) (<= 0 value 100))))
(def (complexity-or-unknown? value)
  (or (eq? value 'unknown) (and (exact-integer? value) (>= value 0))))
(def SdlcSafetyComponent
  (poo-clos-class 'sdlc/safety-component direct-superclasses: (list SdlcBoundFact SdlcIdentified)
    direct-slots: (list
      (poo-clos-direct-slot-definition 'safety-critical? type-predicate: boolean?)
      (poo-clos-direct-slot-definition 'mcdc-percent type-predicate: coverage-or-unknown?)
      (poo-clos-direct-slot-definition 'cyclomatic-complexity type-predicate: complexity-or-unknown?))))
(def (sdlc-safety-component? value) (poo-flow-model? SdlcSafetyComponent value))

(export SdlcTailoringPacket sdlc-tailoring-packet?
        SdlcAuthorityAttestation sdlc-authority-attestation?)
(def SdlcTailoringPacket
  (poo-clos-class 'sdlc/tailoring-packet
    direct-superclasses: (list SdlcBoundFact SdlcClause SdlcIdentified)
    direct-slots: (text-slots '(rationale risk mitigations risk-acceptance archived-matrix))))
(def SdlcAuthorityAttestation
  (poo-clos-class 'sdlc/authority-attestation
    direct-superclasses: (list SdlcBoundFact SdlcClause SdlcIdentified)
    direct-slots: (append (text-slots '(request signer record))
      (list (poo-clos-direct-slot-definition 'authority type-predicate: symbol?)
            (enum-slot 'decision '(approved rejected))))))
(def (sdlc-tailoring-packet? value) (poo-flow-model? SdlcTailoringPacket value))
(def (sdlc-authority-attestation? value) (poo-flow-model? SdlcAuthorityAttestation value))

(export SdlcStagePolicy sdlc-stage-policy? SdlcLifecycleState sdlc-lifecycle-state?
        SdlcVerificationRequest sdlc-verification-request?)
(def (nonempty-text-list? values)
  (and (list? values) (pair? values) (every sdlc-text? values)
       (= (length values) (length (delete-duplicates/hash values)))))
(def SdlcStagePolicy
  (poo-clos-class 'sdlc/stage-policy direct-superclasses: (list SdlcIdentified)
    direct-slots: (list (enum-slot 'assessment-scope '(project institution))
                       (poo-clos-direct-slot-definition 'requirements type-predicate: nonempty-text-list?))))
(def SdlcLifecycleState
  (poo-clos-class 'sdlc/lifecycle-state direct-superclasses: (list SdlcBoundFact)
    direct-slots: (text-slots '(stage))))
(def SdlcVerificationRequest
  (poo-clos-class 'sdlc/verification-request direct-superclasses: (list SdlcBoundFact)
    direct-slots: (list (enum-slot 'purpose '(criterion-content classification-and-context tailoring-decision structured-inventory certification-decision))
                       (poo-clos-direct-slot-definition 'facts type-predicate: object?))))
(def (sdlc-stage-policy? value) (poo-flow-model? SdlcStagePolicy value))
(def (sdlc-lifecycle-state? value) (poo-flow-model? SdlcLifecycleState value))
(def (sdlc-verification-request? value) (poo-flow-model? SdlcVerificationRequest value))

(export SdlcSafetyInventory SdlcTraceInventory sdlc-safety-inventory? sdlc-trace-inventory?
        sdlc-artifact-digest?)
(def (sdlc-artifact-digest? value)
  (and (string? value) (= (string-length value) 64)
       (every (lambda (c) (or (char<=? #\0 c #\9) (char<=? #\a c #\f))) (string->list value))))
(def SdlcInventory
  (poo-clos-class 'sdlc/inventory direct-superclasses: (list SdlcBoundFact SdlcIdentified)
    direct-slots: (list (poo-clos-direct-slot-definition 'artifact-digest type-predicate: sdlc-artifact-digest?)
                       (poo-clos-direct-slot-definition 'complete? type-predicate: boolean?))))
(def (instances-slot name predicate)
  (poo-clos-direct-slot-definition name
    type-predicate: (lambda (values) (and (list? values) (every predicate values)))))
(def SdlcSafetyInventory
  (poo-clos-class 'sdlc/safety-inventory direct-superclasses: (list SdlcInventory)
    direct-slots: (list (instances-slot 'components sdlc-safety-component?))))
(def SdlcTraceInventory
  (poo-clos-class 'sdlc/trace-inventory direct-superclasses: (list SdlcInventory)
    direct-slots: (list (instances-slot 'nodes sdlc-trace-node?) (instances-slot 'edges sdlc-trace-edge?))))
(def (sdlc-safety-inventory? value) (poo-flow-model? SdlcSafetyInventory value))
(def (sdlc-trace-inventory? value) (poo-flow-model? SdlcTraceInventory value))
