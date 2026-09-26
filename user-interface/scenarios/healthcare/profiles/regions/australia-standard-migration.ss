;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o .ref)
        (only-in :poo-flow/modules/governance/objects
                 poo-flow-governance-precondition
                 poo-flow-governance-threat)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/interface
                 HealthcareModule)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export AustraliaHealthcareStandardMigrationProfile)

(def AustraliaMigrationStandards
  (.ref HealthcareModule 'standards))
(def AustraliaMigrationStandardEditions
  (.ref AustraliaMigrationStandards 'editions))
(def AustraliaMigrationFeature
  (.ref (.ref AustraliaMigrationStandards 'features) 'migration))
(def AustraliaMigrationFixture
  (.ref (.ref AustraliaMigrationFeature 'fixtures) 'australia))

;;; Region-specific migration governance is separate from care-delivery
;;; Profiles.  It composes only evidence needed to admit a Standard migration.
(.def (AustraliaHealthcareStandardMigrationProfile self HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/regions/australia/standard-migration")
  (name 'australia-standard-migration)
  (profile-imports =>.+
   (.o healthcare: HealthcareBaseProfile
       evidence: EvidenceProfile
       privacy: PrivacyProfile))
  (concept-declarations =>.+ (.o))
  (relation-declarations =>.+ (.o))
  (source-declarations =>.+
   (.o cedar-human-authorization:
       (ontology-source
        "healthcare/standard-migration/authorization/policy"
        "user-interface/scenarios/healthcare/authorization/standard-migration.cedar"
        'cedar 'scenario 'healthcare #f)
       cedar-human-authorization-schema:
       (ontology-source
        "healthcare/standard-migration/authorization/schema"
        "user-interface/scenarios/healthcare/authorization/standard-migration-schema.json"
        'json 'scenario 'healthcare #f)
       tla-migration-model:
       (ontology-source
        "healthcare/standard-migration/formal-model/tla-plus"
        "user-interface/scenarios/healthcare/cases/au-legacy-interface-fhir-migration/proof/tla/HealthcareStandardMigration.tla"
        'tla-plus 'scenario 'healthcare #f)
       tla-migration-config:
       (ontology-source
        "healthcare/standard-migration/formal-model/tlc-config"
        "user-interface/scenarios/healthcare/cases/au-legacy-interface-fhir-migration/proof/tla/HealthcareStandardMigration.cfg"
        'tla-plus-config 'scenario 'healthcare #f)
       lean-migration-refinement:
       (ontology-source
        "healthcare/standard-migration/refinement/lean"
        "proof/lean/EpistemeProof/Healthcare/StandardMigrationRefinement.lean"
        'lean 'scenario 'healthcare #f)
       cedar-migration-authorization-spec:
       (ontology-source
        "healthcare/standard-migration/authorization/cedar-lean-spec"
        "proof/lean/EpistemeProof/Healthcare/StandardMigrationCedarAuthorization.lean"
        'lean 'scenario 'healthcare #f)))
  (rule-declarations =>.+ (.o))
  (threat-declarations =>.+
   (.o parser-evidence-unbound:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/parser-evidence-unbound"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/parser-receipt"
          #t "evidence:gerbil-parser-qualified-source-snapshot"))
        mitigations: '("bind parser receipt to the exact legacy source snapshot"))
       ai-authority-escalation:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/ai-authority-escalation"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/ai-advisory-only"
          #t "evidence:ai-analysis-is-advisory"))
        mitigations: '("require independent human approval of every mapping"))
       target-conformance-bypass:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/target-conformance-bypass"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/conformance"
          #t "evidence:exact-au-core-conformance-receipt"))
        mitigations: '("validate the candidate against the pinned AU Core edition"))
       formal-impact-stale:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/formal-impact-stale"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/tla-lean-impact"
          #t "evidence:exact-tla-digest-bound-to-lean-refinement"))
        mitigations:
        '("reject stale Lean evidence whenever the TLA+ source digest changes"))
       human-authorization-bypass:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/human-authorization-bypass"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/cedar-human-permit"
          #t "evidence:exact-reviewer-action-resource-cedar-permit"))
        mitigations:
        '("require Cedar human authorization before cutover readiness"))
       unsafe-cutover:
       (poo-flow-governance-threat
        "healthcare/regions/australia/migration/threat/unsafe-cutover"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/migration/precondition/rollback"
          #t "evidence:legacy-source-snapshot-retained"))
        mitigations: '("shadow validate before a phased application-owned cutover"))))
  (policies
   (.o jurisdiction: 'AU
       ai-role: 'advisory-only
       migration-mode: 'coexistence
       cutover-owner: 'application-human-reviewer
       governance-interface:
       "lambda-episteme/healthcare/standards/migration/governance"
       governance-slots: 'mandatory-by-stage
       target-version-policy: 'exact-edition-only))
  (standard-requirements
   (list (.ref AustraliaMigrationStandardEditions 'fhir-r4)
         (.ref AustraliaMigrationStandardEditions 'au-base)
         (.ref AustraliaMigrationStandardEditions 'au-core)))
  (migration-fixture AustraliaMigrationFixture)
  (capability-declarations =>.+ (.o))
  (query-declarations =>.+ (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((parser-receipt-bound?
         . "healthcare/regions/australia/migration/threat/parser-evidence-unbound")
        (ai-advisory-only?
         . "healthcare/regions/australia/migration/threat/ai-authority-escalation")
        (independent-human-review?
         . "healthcare/regions/australia/migration/threat/ai-authority-escalation")
        (target-conformance-required?
         . "healthcare/regions/australia/migration/threat/target-conformance-bypass")
        (formal-impact-bound?
         . "healthcare/regions/australia/migration/threat/formal-impact-stale")
        (cedar-human-authorization-required?
         . "healthcare/regions/australia/migration/threat/human-authorization-bypass")
        (rollback-source-snapshot-retained?
         . "healthcare/regions/australia/migration/threat/unsafe-cutover"))))))
