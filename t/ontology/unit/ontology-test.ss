;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .cc .def .o .ref .set! object?)
        :std/list/list
        (only-in :poo-flow/src/graph/types
                 poo-flow-graph poo-flow-graph-edge poo-flow-graph-node
                 poo-flow-graph-edge-kind poo-flow-graph-edges
                 poo-flow-graph-node-metadata poo-flow-graph-nodes
                 poo-flow-graph-node-id
                 poo-flow-graph?)
        :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/profile-composition/interface
        :poo-flow/src/modules/governance/interface
        :poo-flow/src/modules/authorization/providers/cedar/interface
        :poo-flow/lambda-episteme/modules/ontology/interface
        :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
        :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/scenario
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/healing
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/medication-safety
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/authorization
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/post-operative-healing/case
        :poo-flow/lambda-episteme/user-interface/scenarios/software-engineering/profiles/base
        :poo-flow/lambda-episteme/user-interface/scenarios/software-engineering/scenario
        :poo-flow/lambda-episteme/user-interface/scenarios/software-engineering/cases/architecture-governance/case
        :poo-flow/lambda-episteme/user-interface/scenarios/commercial-finance/profiles/base
        :poo-flow/lambda-episteme/user-interface/scenarios/commercial-finance/scenario
        :poo-flow/lambda-episteme/user-interface/scenarios/commercial-finance/cases/transaction-posting/case
        :poo-flow/lambda-episteme/user-interface/scenarios/manufacturing/profiles/base
        :poo-flow/lambda-episteme/user-interface/scenarios/manufacturing/scenario
        :poo-flow/lambda-episteme/user-interface/scenarios/manufacturing/cases/work-order-execution/case
        :poo-flow/lambda-episteme/user-interface/scenarios/education/profiles/base
        :poo-flow/lambda-episteme/user-interface/scenarios/education/scenario
        :poo-flow/lambda-episteme/user-interface/scenarios/education/cases/enrollment-context/case)

(export ontology-test)

(def MissingCaseProfile
  (.o (:: @ EvidenceProfile)
      identity: "lambda-episteme/ontology/missing-case-profile"
      name: 'missing-case-profile
      imports: '()))

(def BrokenImportProfile
  (.o (:: @ HealingProfile)
      identity: "lambda-episteme/ontology/healthcare/broken-import"
      name: 'broken-import
      imports: (list MissingCaseProfile)))

(def broken-import-composition
  (poo-flow-scenario-case
   'broken-import '() (list BrokenImportProfile) '() '()))

(def ReverseScopeProfile
  (.o (:: @ EvidenceProfile)
      identity: "lambda-episteme/ontology/reverse-scope"
      name: 'reverse-scope
      imports: (list HealingProfile)))

(def reverse-scope-composition
  (poo-flow-scenario-case
   'reverse-scope '()
   (list EvidenceProfile HealthcareBaseProfile HealingProfile
         ReverseScopeProfile)
   '() '()))

(def ConflictingProfile
  (.o (:: @ HealthcareBaseProfile)
      identity: "lambda-episteme/ontology/healthcare/conflicting"
      name: 'conflicting
      imports: (list HealthcareBaseProfile)
      conflicts:
      (list "lambda-episteme/ontology/healthcare/medication-safety")))

(def conflicting-composition
  (poo-flow-scenario-case
   'conflicting '()
   (list EvidenceProfile PrivacyProfile HealthcareBaseProfile
         MedicationSafetyProfile ConflictingProfile)
   '() '()))

(.def (UnmitigatedMedicationSafetyProfile @ MedicationSafetyProfile)
  (identity "lambda-episteme/ontology/healthcare/medication-safety/unmitigated")
  (name 'medication-safety-unmitigated)
  (.add-threat
   (.o contraindication-evidence-drift:
       (poo-flow-governance-threat
        "healthcare/medication/threat/contraindication-evidence-drift"
        'critical
        'exposed
        (list
         (poo-flow-governance-precondition
          "healthcare/medication/precondition/reconciliation-missing"
          #t
          "evidence:medication-reconciliation-missing"))))))

(def unmitigated-medication-composition
  (poo-flow-scenario-case
   'unmitigated-medication '()
   (list EvidenceProfile PrivacyProfile HealthcareBaseProfile
         UnmitigatedMedicationSafetyProfile)
   '() '()))

(def cedar-test-digest
  (string-append "sha256:" (make-string 64 #\0)))

(def (healthcare-test-proof receipt)
  (let* ((profiles (.ref receipt 'profiles))
         (assessments (.ref receipt 'governance-assessments))
         (authorization (car (.ref (.ref receipt 'case) 'authorizations))))
    (poo-flow-cedar-proof-binding
     (symbol->string (.ref receipt 'case-id))
     (map (lambda (profile) (.ref profile 'identity)) profiles)
     cedar-test-digest cedar-test-digest cedar-test-digest
     (healthcare-authorization-capability-digest receipt)
     (poo-flow-governance-assessments-digest assessments)
     (healthcare-authorization-subject-digest receipt authorization)
     '("PooFlowProof.Enterprise.GovernanceThreatAssuranceClosure"
       "PooFlowProof.PooC3.CedarDualEngineArbitration"))))

(def CustomProjectionProfile
  (.o (:: @ HealingProfile)
      identity: "lambda-episteme/ontology/healthcare/custom-projection"
      name: 'custom-projection
      imports: (list HealthcareBaseProfile)
      .project:
      (lambda (profile)
        (.o identity: (.ref profile 'identity)
            projection-kind: 'healthcare-custom))))

(def custom-projection-composition
  (poo-flow-scenario-case
   'custom-projection '()
   (list EvidenceProfile HealthcareBaseProfile CustomProjectionProfile)
   '() '()))

(def StrictHealthcareScenario
  (.o (:: @ HealthcareScenario)
      .admit-profile?:
      (lambda (profile)
        (eq? (.ref profile 'name) 'healing))))

(def CyclicProfileA
  (.o (:: @ HealthcareBaseProfile)
      identity: "lambda-episteme/ontology/healthcare/cycle-a"
      name: 'cycle-a
      imports: '()))

(def CyclicProfileB
  (.o (:: @ HealthcareBaseProfile)
      identity: "lambda-episteme/ontology/healthcare/cycle-b"
      name: 'cycle-b
      imports: (list CyclicProfileA)))

(.set! CyclicProfileA imports (list CyclicProfileB))

(def cyclic-composition
  (poo-flow-scenario-case
   'cyclic '()
   (list EvidenceProfile HealthcareBaseProfile CyclicProfileA CyclicProfileB)
   '() '()))

(def BrokenSemanticVocabulary
  (ontology-vocabulary
   (list (ontology-concept 'BrokenConcept '(MissingConcept) '()))
   (list (ontology-relation 'BROKEN_EDGE
                            'BrokenConcept 'MissingRange '()))))

(def BrokenSemanticProfile
  (.o (:: @ HealthcareBaseProfile)
      identity: "lambda-episteme/ontology/healthcare/broken-semantics"
      name: 'broken-semantics
      imports: (list HealthcareBaseProfile)
      ontology: BrokenSemanticVocabulary
      terms: (ontology-vocabulary-concept-identities BrokenSemanticVocabulary)))

(def broken-semantic-composition
  (poo-flow-scenario-case
   'broken-semantics '()
   (list EvidenceProfile HealthcareBaseProfile BrokenSemanticProfile)
   '() '()))

(def (test-ontology-case case-id-value scenario-value compositions-value
                         sources-value graph-value)
  (.cc OntologyCase
       case-id: case-id-value
       scenario: scenario-value
       compositions: compositions-value
       sources: sources-value
       graph: graph-value))

(def (compose-healthcare-test-case case-id-value compositions-value
                                   sources-value)
  (ontology-compose-case
   (test-ontology-case
    case-id-value HealthcareScenario compositions-value sources-value
    (poo-flow-graph case-id-value '() '()))))

;; Case files export declarations only. Receipts and evaluations are consumers'
;; derived values, never extra user-interface bindings maintained beside a Case.
(def post-operative-healing-compositions
  (.ref PostOperativeHealingCase 'compositions))
(def post-operative-healing-receipt
  (ontology-compose-case PostOperativeHealingCase))
(def post-operative-healing-evaluation
  (ontology-evaluate-case post-operative-healing-receipt))

(def architecture-governance-receipt
  (ontology-compose-case ArchitectureGovernanceCase))
(def architecture-governance-evaluation
  (ontology-evaluate-case architecture-governance-receipt))

(def transaction-posting-receipt
  (ontology-compose-case TransactionPostingCase))
(def transaction-posting-evaluation
  (ontology-evaluate-case transaction-posting-receipt))

(def work-order-execution-receipt
  (ontology-compose-case WorkOrderExecutionCase))
(def work-order-execution-evaluation
  (ontology-evaluate-case work-order-execution-receipt))

(def enrollment-context-receipt
  (ontology-compose-case EnrollmentContextCase))
(def enrollment-context-evaluation
  (ontology-evaluate-case enrollment-context-receipt))

(def TestCaseSource
  (ontology-source
   "ontology/healthcare/test-case-source"
   "t/ontology/unit/ontology-test.ss"
   'scheme 'case 'healthcare 'post-operative-healing))

(def (profile-source-paths profile)
  (map (lambda (source) (.ref source 'path))
       (.ref profile 'source-assets)))

(def (contributor-source-path path)
  (let (local-path (path-expand path "."))
    (if (file-exists? local-path)
      local-path
      (path-expand path "packages/lambda-episteme"))))

(def ontology-test
  (test-suite
   "Ontology Profiles, Scenarios, Sources and Cases"

   (test-case "Ontology is one ordinary contributed module"
     (check (contribution? ontology-module) => #t)
     (check (equal? (.ref ontology-module 'identity)
                    "lambda-episteme/ontology")
            => #t)
     (check (ontology-scenario? HealthcareScenario) => #t)
     (check (ontology-case? PostOperativeHealingCase) => #t))

   (test-case "Common and Scenario Profiles retain explicit scope"
     (check (ontology-profile? EvidenceProfile) => #t)
     (check (ontology-profile? PrivacyProfile) => #t)
     (check (ontology-profile? HealthcareBaseProfile) => #t)
     (check (ontology-profile? HealingProfile) => #t)
     (check (ontology-profile? MedicationSafetyProfile) => #t)
     (check (.ref EvidenceProfile 'profile-scope) => 'common)
     (check (.ref HealingProfile 'scenario) => 'healthcare)
     (check (object? (.ref HealthcareBaseProfile '.import)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-concept)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-relation)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-source)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-rule)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-query)) => #t)
     (check (object? (.ref HealthcareBaseProfile '.add-threat)) => #t)
     (check (map (lambda (profile) (.ref profile 'identity))
                 (.ref MedicationSafetyProfile 'imports))
            => (list "lambda-episteme/ontology/healthcare/base"
                     "lambda-episteme/ontology/evidence"
                     "lambda-episteme/ontology/privacy")))

   (test-case "one declarative Case slot closes named Profile compositions"
     (check (object? (.ref PostOperativeHealingCase '.use-composition)) => #t)
     (check (length post-operative-healing-compositions) => 3)
     (check (map poo-flow-scenario-case-name
                 post-operative-healing-compositions)
            => '(common healthcare medication))
     (check (ontology-case-composition-receipt?
             post-operative-healing-receipt)
            => #t)
     (check (.ref post-operative-healing-receipt 'accepted?) => #t)
     (check (map (lambda (profile) (.ref profile 'name))
                 (.ref post-operative-healing-receipt 'profiles))
            => '(evidence privacy healthcare-base healing medication-safety))
     (check (length (.ref post-operative-healing-receipt 'projection)) => 5)
     (check (.ref post-operative-healing-receipt 'runtime-executed?) => #f))

   (test-case "reasoning graph derives Case, Profile and Impact relations"
     (let* ((reasoning
             (ontology-case-reasoning-graph
              post-operative-healing-receipt))
            (edges (poo-flow-graph-edges reasoning))
            (edge-kinds (map poo-flow-graph-edge-kind edges))
            (impact
             (ontology-reasoning-impact
              reasoning
              "source:healthcare/medication/authorization/policy")))
       (check (poo-flow-graph? reasoning) => #t)
       (check (length (filter (lambda (kind) (eq? kind 'HAS_CASE))
                              edge-kinds))
              => 1)
       (check (length (filter (lambda (kind)
                                (eq? kind 'USES_COMPOSITION))
                              edge-kinds))
              => 3)
       (check (length (filter (lambda (kind)
                                (eq? kind 'HAS_EFFECTIVE_PROFILE))
                              edge-kinds))
              => 5)
       (check (memq 'DECLARES_SOURCE edge-kinds) ? values)
       (check (memq 'DECLARES_THREAT edge-kinds) ? values)
       (check (memq 'DECLARES_CAPABILITY edge-kinds) ? values)
       (check (ontology-reasoning-impact? impact) => #t)
       (check (.ref impact 'target-entity-kind) => 'source)
       (check (.ref impact 'impacted-case-ids)
              => '(post-operative-healing))
       (check (.ref impact 'status) => 'snapshot-scoped-impact)
       (check (.ref impact 'temporal-impact-assessed?) => #f)
       (check (.ref impact 'release-authorized?) => #f)
       (check (.ref impact 'runtime-executed?) => #f)))

   (test-case "Healthcare GQL properties come from accepted POO values"
     (let* ((reasoning
             (ontology-case-reasoning-graph
              post-operative-healing-receipt))
            (nodes (poo-flow-graph-nodes reasoning))
            (scenario
             (find (lambda (node)
                     (equal? (poo-flow-graph-node-id node)
                             "scenario:healthcare"))
                   nodes))
            (case-node
             (find (lambda (node)
                     (equal? (poo-flow-graph-node-id node)
                             "case:post-operative-healing"))
                   nodes))
            (profile
             (find (lambda (node)
                     (equal? (poo-flow-graph-node-id node)
                             "profile:lambda-episteme/ontology/healthcare/healing"))
                   nodes)))
       (check (ontology-reasoning-query-property scenario 'identity)
              => "healthcare")
       (check (ontology-reasoning-query-property case-node 'id)
              => "post-operative-healing")
       (check (ontology-reasoning-query-property profile 'identity)
              => "lambda-episteme/ontology/healthcare/healing")))

   (test-case "Case composition evaluates declared vertical Governance threats"
     (let* ((threats
             (.ref (.ref MedicationSafetyProfile 'threat-model) 'threats))
            (assessments
             (.ref post-operative-healing-receipt
                   'governance-assessments))
            (medication-assessment
             (find
              (lambda (assessment)
                (equal?
                 (.ref assessment 'profile-identity)
                 "lambda-episteme/ontology/healthcare/medication-safety"))
              assessments)))
       (check (length threats) => 1)
       (check (poo-flow-governance-threat? (car threats)) => #t)
       (check (.ref (car threats) 'phase) => 'mitigated)
       (check (length assessments) => 5)
       (check (poo-flow-governance-assessment? medication-assessment) => #t)
       (check (.ref medication-assessment 'handoff-ready?) => #t)
       (check (.ref medication-assessment 'runtime-executed?) => #f)
       (check (.ref post-operative-healing-receipt
                    'governance-handoff-ready?)
              => #t)))

   (test-case "Healthcare Cedar rejects a Case without exact assurance"
     (let* ((root (if (file-exists? "modules/ontology/interface.ss")
                    "." "lambda-episteme"))
            (context
             (poo-flow-cedar-authority-context
              "healthcare-authority" "post-operative-runtime" 1
              cedar-test-digest 1 1 0))
            (proof (healthcare-test-proof post-operative-healing-receipt)))
       (check-exception
        (healthcare-case-cedar-snapshot
         post-operative-healing-receipt cedar-test-digest root context proof)
        true)))

   (test-case "native Rule objects execute over declarative Case Graphs"
     (for-each
      (lambda (evaluation)
        (check (ontology-case-evaluation-receipt? evaluation) => #t)
        (check (poo-flow-graph? (.ref evaluation 'graph)) => #t)
        (check (.ref evaluation 'accepted?) => #t)
        (check (.ref evaluation 'runtime-executed?) => #t))
      (list post-operative-healing-evaluation
            architecture-governance-evaluation
            transaction-posting-evaluation
            work-order-execution-evaluation
            enrollment-context-evaluation)))

   (test-case "unmitigated vertical threat blocks Case handoff"
     (let* ((receipt
             (compose-healthcare-test-case
              'unsafe-medication-case
              (list unmitigated-medication-composition)
              '()))
            (assessment
             (find
              (lambda (item)
                (equal?
                 (.ref item 'profile-identity)
                 "lambda-episteme/ontology/healthcare/medication-safety/unmitigated"))
              (.ref receipt 'governance-assessments))))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'governance-handoff-ready?) => #f)
       (check (memq 'governance-handoff-blocked
                    (ontology-case-diagnostic-codes receipt))
              ? values)
       (check (.ref assessment 'unresolved-threats)
              => '("healthcare/medication/threat/contraindication-evidence-drift"))
       (check (.ref assessment 'runtime-executed?) => #f)))

   (test-case "vertical assets are native Scenario Profile Case values"
     (for-each
      (lambda (scenario)
        (check (ontology-scenario? scenario) => #t))
      (list SoftwareEngineeringScenario CommercialFinanceScenario
            ManufacturingScenario EducationScenario))
     (for-each
      (lambda (profile)
        (check (ontology-profile? profile) => #t))
      (list SoftwareEngineeringBaseProfile CommercialFinanceBaseProfile
            ManufacturingBaseProfile EducationBaseProfile))
     (for-each
      (lambda (case-value)
        (check (ontology-case? case-value) => #t))
      (list ArchitectureGovernanceCase TransactionPostingCase
            WorkOrderExecutionCase EnrollmentContextCase))
     (for-each
      (lambda (receipt)
        (check (ontology-case-composition-receipt? receipt) => #t)
        (check (.ref receipt 'accepted?) => #t)
        (check (.ref receipt 'runtime-executed?) => #f))
      (list architecture-governance-receipt transaction-posting-receipt
            work-order-execution-receipt enrollment-context-receipt)))

   (test-case "POO Profiles own semantics and bind only external evidence"
     (for-each
      (lambda (profile)
        (check (every (lambda (source)
                        (not (eq? (.ref source 'language) 'rdf)))
                      (.ref profile 'source-assets))
               => #t))
      (list EvidenceProfile SoftwareEngineeringBaseProfile
            CommercialFinanceBaseProfile HealthcareBaseProfile
            ManufacturingBaseProfile EducationBaseProfile))
     (check (profile-source-paths EvidenceProfile) => '())
     (check (profile-source-paths SoftwareEngineeringBaseProfile)
            => '("user-interface/scenarios/software-engineering/sources/architectural-decision-making.md"))
     (check (profile-source-paths CommercialFinanceBaseProfile)
            => '())
     (check (profile-source-paths HealthcareBaseProfile)
            => '("user-interface/scenarios/healthcare/sources/synthetic-care-delivery.toml"))
     (check (profile-source-paths ManufacturingBaseProfile)
            => '())
     (check (profile-source-paths EducationBaseProfile)
            => '()))

   (test-case "semantic objects project typed relation boundaries"
     (let* ((profile-projection
             (find (lambda (projection)
                     (equal? (.ref projection 'identity)
                             "lambda-episteme/ontology/healthcare/base"))
                   (.ref post-operative-healing-receipt 'projection)))
            (vocabulary (.ref profile-projection 'ontology))
            (relation (car (.ref vocabulary 'relations))))
       (check (.ref relation 'identity) => 'HAS_PATIENT)
       (check (.ref relation 'domain) => 'Encounter)
       (check (.ref relation 'range) => 'Patient)
       (check (.ref relation 'constraints) => '(required))))

   (test-case "every selected Source path exists under its contributor owner"
     (for-each
      (lambda (profile)
        (for-each
         (lambda (source)
           (check (file-exists?
                   (contributor-source-path (.ref source 'path)))
                  => #t))
         (.ref profile 'source-assets)))
      (list EvidenceProfile SoftwareEngineeringBaseProfile
            CommercialFinanceBaseProfile HealthcareBaseProfile
            ManufacturingBaseProfile EducationBaseProfile))
     (check (file-exists?
             (contributor-source-path (.ref TestCaseSource 'path)))
            => #t))

   (test-case "Scenario and Case Sources have non-reversing ownership"
     (let (mapping-source
           (car (.ref HealthcareBaseProfile 'source-assets)))
       (check (.ref mapping-source 'source-scope) => 'scenario)
       (check (.ref mapping-source 'scenario) => 'healthcare))
     (check (.ref TestCaseSource 'source-scope) => 'case)
     (check (.ref TestCaseSource 'case-id)
            => 'post-operative-healing)
     (let* ((wrong-source
             (ontology-source
              "ontology/healthcare/wrong-case"
              "t/ontology/unit/ontology-test.ss"
              'scheme 'case 'healthcare 'another-case))
            (receipt
             (compose-healthcare-test-case
              'post-operative-healing
              post-operative-healing-compositions
              (list wrong-source))))
       (check (.ref receipt 'accepted?) => #f)
       (check (memq 'case-source-owner-mismatch
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "missing required relations and cycles are typed failures"
     (let* ((missing-case
             (test-ontology-case
              'missing-transaction-account CommercialFinanceScenario
              (list (car (.ref TransactionPostingCase 'compositions))) '()
              (poo-flow-graph
               'missing-transaction-account
               (list (poo-flow-graph-node
                      'transaction-only 'Transaction))
               '())))
            (missing-evaluation
             (ontology-evaluate-case (ontology-compose-case missing-case)))
            (cyclic-case
             (test-ontology-case
              'cyclic-architecture SoftwareEngineeringScenario
              (list (car (.ref ArchitectureGovernanceCase 'compositions))) '()
              (poo-flow-graph
               'cyclic-architecture
               (list (poo-flow-graph-node
                      'component-a 'SoftwareComponent)
                     (poo-flow-graph-node
                      'component-b 'SoftwareComponent))
               (list (poo-flow-graph-edge
                      'component-a 'component-b 'dependsOn)
                     (poo-flow-graph-edge
                      'component-b 'component-a 'dependsOn)))))
            (cyclic-evaluation
             (ontology-evaluate-case (ontology-compose-case cyclic-case))))
       (check (.ref missing-evaluation 'accepted?) => #f)
       (check (memq 'required-relation-missing
                    (ontology-evaluation-diagnostic-codes missing-evaluation))
              ? values)
       (check (.ref cyclic-evaluation 'accepted?) => #f)
       (check (memq 'relation-cycle
                    (ontology-evaluation-diagnostic-codes cyclic-evaluation))
              ? values)))

   (test-case "missing Profile imports fail before projection"
     (let (receipt
           (compose-healthcare-test-case
            'broken-import-case (list broken-import-composition) '()))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'projection) => '())
       (check (memq 'missing-profile-import
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "Common Profiles cannot reverse-import a Scenario Profile"
     (let (receipt
           (compose-healthcare-test-case
            'reverse-scope-case (list reverse-scope-composition) '()))
       (check (.ref receipt 'accepted?) => #f)
       (check (memq 'common-profile-imports-scenario-profile
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "selected conflicting Profiles fail before projection"
     (let (receipt
           (compose-healthcare-test-case
            'conflicting-case (list conflicting-composition) '()))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'projection) => '())
       (check (memq 'selected-profile-conflict
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "derived Profile replaces the gerbil-poo projection method slot"
     (let* ((receipt
             (compose-healthcare-test-case
              'custom-projection-case
              (list custom-projection-composition) '()))
            (projection (car (reverse (.ref receipt 'projection)))))
       (check (.ref receipt 'accepted?) => #t)
       (check (.ref projection 'identity)
              => "lambda-episteme/ontology/healthcare/custom-projection")
       (check (.ref projection 'projection-kind) => 'healthcare-custom)))

   (test-case "derived Scenario replaces the gerbil-poo admission method slot"
     (check (ontology-scenario-admits-profile?
             StrictHealthcareScenario HealingProfile)
            => #t)
     (check (ontology-scenario-admits-profile?
             StrictHealthcareScenario EvidenceProfile)
            => #f))

   (test-case "cyclic Profile imports fail before projection"
     (let (receipt
           (compose-healthcare-test-case
            'cyclic-case (list cyclic-composition) '()))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'projection) => '())
       (check (memq 'cyclic-profile-import
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "unresolved semantic references fail before projection"
     (let (receipt
           (compose-healthcare-test-case
            'broken-semantic-case (list broken-semantic-composition) '()))
       (check (.ref receipt 'accepted?) => #f)
       (check (.ref receipt 'projection) => '())
       (check (memq 'unresolved-concept-parent
                    (ontology-case-diagnostic-codes receipt))
              ? values)
       (check (memq 'unresolved-relation-endpoint
                    (ontology-case-diagnostic-codes receipt))
              ? values)))

   (test-case "Profile removal preserves closure or reports every blocker"
     (let* ((removed-leaf
             (ontology-remove-case-profile
              post-operative-healing-receipt
              "lambda-episteme/ontology/healthcare/healing"))
            (blocked
             (ontology-remove-case-profile
              post-operative-healing-receipt
              "lambda-episteme/ontology/evidence"))
            (blocked-diagnostic (car (.ref blocked 'diagnostics))))
       (check (.ref removed-leaf 'accepted?) => #t)
       (check (map (lambda (profile) (.ref profile 'name))
                   (.ref removed-leaf 'profiles))
              => '(evidence privacy healthcare-base medication-safety))
       (check (.ref blocked 'accepted?) => #f)
       (check (.ref blocked-diagnostic 'code) => 'profile-removal-blocked)
       (check (.ref blocked-diagnostic 'detail)
              => (list "lambda-episteme/ontology/healthcare/base"
                       "lambda-episteme/ontology/healthcare/healing"
                       "lambda-episteme/ontology/healthcare/medication-safety"
                       "lambda-episteme/ontology/privacy"))))))
