;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .cc .o .ref .slot?)
        (only-in :poo-flow/src/modules/standards/config
                 PooFlowStandardMigrationGovernanceInterface.)
        (only-in :poo-flow/src/modules/standards/objects
                 poo-flow-standard-feature-module
                 poo-flow-standard-governance-binding
                 poo-flow-standard-governance-interface)
        (only-in :poo-flow/src/modules/standards/funs
                 poo-flow-standard-digest)
        (only-in :poo-flow/src/modules/proof/interface
                 poo-flow-proof-artifact
                 poo-flow-proof-receipt
                 poo-flow-proof-impact-binding
                 poo-flow-proof-refinement-binding
                 poo-flow-proof-assurance
                 poo-flow-proof-assurance?)
        (only-in :poo-flow/src/modules/authorization/providers/cedar/config
                 CedarAuthorizationProvider)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/fhir/objects
                 FHIRAUCorePatientStandardProfile)
        "types.ss"
        "objects.ss"
        "funs.ss"
        "authorization.ss")

(export HealthcareStandardMigrationFeatureModule
        AUHealthcareMigrationFixture
        AULegacyHealthcareInterfaceLandscape
        AULegacyHL7v2PatientParserProjection
        AULegacyHL7v2PatientSubject
        AULegacyHL7v2PatientFHIRCandidate
        AULegacyHL7v2PatientFieldMappings
        AULegacyHL7v2PatientAIAnalysis
        AULegacyHL7v2PatientMigrationProposal
        AULegacyHL7v2PatientMigrationReview
        AULegacyHL7v2PatientMigrationCase
        AUHealthcareMigrationFormalModelEvidence
        AUHealthcareMigrationTLAConfigEvidence
        AUHealthcareMigrationRefinementProofEvidence
        AUHealthcareMigrationRefinementReceipt
        AUHealthcareMigrationCedarAuthorizationEvidence
        AUHealthcareMigrationCedarAuthorizationReceipt
        AUHealthcareMigrationRefinementBinding
        AUHealthcareMigrationProofAssurance
        AUHealthcareMigrationImpactContract
        HealthcareStandardMigrationGovernanceInterface)

(def +au-migration-tla-source-digest+
  "sha256:043ac3e0074752fddf6a2ac4dd889d75930a0deb9c06a576d3b3cdb61981c04f")
(def +au-migration-tla-config-digest+
  "sha256:6abcb5349eb74d53d96bfb7fea2bf74631e3891f656a337fde3a083008837bc4")
(def +au-migration-lean-source-digest+
  "sha256:4f1f157441ae98843faf1030c3244d326f3ff96b0bee044044b457118253f57e")
(def +au-migration-cedar-lean-source-digest+
  "sha256:3661cc83e29981c20da89301dd53fd135aee01703ce7e7edf6edd1d65c08ef93")

(def AUHealthcareMigrationFormalModelEvidence
  (poo-flow-proof-artifact
   "lambda-episteme/healthcare/standard-migration/tla-model"
   'tlc 'tla-plus
   "user-interface/scenarios/healthcare/cases/au-legacy-interface-fhir-migration/proof/tla/HealthcareStandardMigration.tla"
   +au-migration-tla-source-digest+
   '(AINeverGrantsAuthority ReviewRequiresConformance
     CedarPermitRequiresHumanReview CutoverRequiresCedarPermit
     CutoverRequiresCompleteEvidence)
   (.o module: "HealthcareStandardMigration"
       config-digest: +au-migration-tla-config-digest+)))

(def AUHealthcareMigrationTLAConfigEvidence
  (poo-flow-proof-artifact
   "lambda-episteme/healthcare/standard-migration/tlc-config"
   'tlc 'tla-plus-config
   "user-interface/scenarios/healthcare/cases/au-legacy-interface-fhir-migration/proof/tla/HealthcareStandardMigration.cfg"
   +au-migration-tla-config-digest+ '()
   (.o model-artifact:
       "lambda-episteme/healthcare/standard-migration/tla-model")))

(def AUHealthcareMigrationRefinementProofEvidence
  (poo-flow-proof-artifact
   "lambda-episteme/healthcare/standard-migration/lean-refinement"
   'lean 'lean
   "proof/lean/EpistemeProof/Healthcare/StandardMigrationRefinement.lean"
   +au-migration-lean-source-digest+
   '(aiCannotAuthorize cutoverRequiresHumanCedarAndEvidence
     tlaImpactContractBindsExactSource)
   (.o library: "EpistemeHealthcareProof"
       module: "EpistemeProof.Healthcare.StandardMigrationRefinement"
       tla-source-digest: +au-migration-tla-source-digest+)))

(def AUHealthcareMigrationRefinementReceipt
  (poo-flow-proof-receipt
   "lambda-episteme/healthcare/standard-migration/lean-receipt"
   AUHealthcareMigrationRefinementProofEvidence 'lean
   '(aiCannotAuthorize cutoverRequiresHumanCedarAndEvidence
     tlaImpactContractBindsExactSource)
   (poo-flow-standard-digest
    (list 'EpistemeHealthcareProof +au-migration-lean-source-digest+))
   #t))

(def AUHealthcareMigrationCedarAuthorizationEvidence
  (poo-flow-proof-artifact
   "lambda-episteme/healthcare/standard-migration/cedar-lean-spec"
   'lean 'lean
   "proof/lean/EpistemeProof/Healthcare/StandardMigrationCedarAuthorization.lean"
   +au-migration-cedar-lean-source-digest+
   '(cutoverRequiresIndependentHumanReview
     cutoverNeverDelegatesAuthorityToAI
     cutoverRequiresExactHealthcareCedarProjection
     cedarDenyBlocksCutover
     explicitCedarForbidBlocksCutover)
   (.o library: "EpistemeHealthcareCedarProof"
       module:
       "EpistemeProof.Healthcare.StandardMigrationCedarAuthorization"
       upstream-semantics:
       "PooFlowProof.PooC3.CedarAuthorizationSemantics"
       cedar-spec-revision:
       "e9fa9c1e6b636f29b0897d8706bd7aa5eaf06f9a")))

(def AUHealthcareMigrationCedarAuthorizationReceipt
  (poo-flow-proof-receipt
   "lambda-episteme/healthcare/standard-migration/cedar-lean-receipt"
   AUHealthcareMigrationCedarAuthorizationEvidence 'lean
   '(cutoverRequiresIndependentHumanReview
     cutoverNeverDelegatesAuthorityToAI
     cutoverRequiresExactHealthcareCedarProjection
     cedarDenyBlocksCutover
     explicitCedarForbidBlocksCutover)
   (poo-flow-standard-digest
    (list 'EpistemeHealthcareCedarProof
          +au-migration-cedar-lean-source-digest+
          "e9fa9c1e6b636f29b0897d8706bd7aa5eaf06f9a"))
   #t))

;;; This is the executable change-impact boundary: a new TLA+ source digest or
;;; invariant set cannot reuse an old Lean qualification.  The Agent must write
;;; a new refinement-proof Binding before review/admission can pass again.
(def AUHealthcareMigrationImpactContract
  (poo-flow-proof-impact-binding
   "lambda-episteme/healthcare/standard-migration/tla-to-lean-impact"
   AUHealthcareMigrationFormalModelEvidence
   AUHealthcareMigrationRefinementProofEvidence
   (.o AINeverGrantsAuthority: '(aiCannotAuthorize)
       ReviewRequiresConformance:
       '(cutoverRequiresHumanCedarAndEvidence)
       CedarPermitRequiresHumanReview:
       '(cutoverRequiresHumanCedarAndEvidence)
       CutoverRequiresCedarPermit:
       '(cutoverRequiresHumanCedarAndEvidence)
       CutoverRequiresCompleteEvidence:
       '(cutoverRequiresHumanCedarAndEvidence))))

(def AUHealthcareMigrationRefinementBinding
  (poo-flow-proof-refinement-binding
   "lambda-episteme/healthcare/standard-migration/refinement-binding"
   AUHealthcareMigrationFormalModelEvidence
   AUHealthcareMigrationRefinementProofEvidence
   AUHealthcareMigrationRefinementReceipt
   AUHealthcareMigrationImpactContract))

(def AUHealthcareMigrationProofAssurance
  (poo-flow-proof-assurance
   "lambda-episteme/healthcare/standard-migration/proof-assurance"
   (list AUHealthcareMigrationFormalModelEvidence
         AUHealthcareMigrationTLAConfigEvidence
         AUHealthcareMigrationRefinementProofEvidence
         AUHealthcareMigrationCedarAuthorizationEvidence)
   (list AUHealthcareMigrationRefinementReceipt
         AUHealthcareMigrationCedarAuthorizationReceipt)
   (list AUHealthcareMigrationRefinementBinding)))

;;; The landscape is explicit so a migration program can select one old
;;; interface without pretending that Australia has a single cut-over format.
(def AULegacyHealthcareInterfaceLandscape
  (.o jurisdiction: 'AU
      legacy-interfaces:
      (.o hl7v2: (.o syntax-owner: 'gerbil-parser
                     semantic-owner: 'lambda-healthcare
                     typical-use: 'messages
                     qualification-state: 'qualified)
          cda: (.o syntax-owner: 'gerbil-parser
                   semantic-owner: 'lambda-healthcare
                   typical-use: 'documents
                   qualification-state: 'declared-only)
          national-service:
          (.o syntax-owner: 'service-adapter
              semantic-owner: 'lambda-healthcare
              typical-use: 'national-service-api
              qualification-state: 'declared-only))
      target-standard: 'fhir
      target-profile: (.ref FHIRAUCorePatientStandardProfile 'identity)
      ai-role: 'advisory-only
      authorization-owner: 'human-reviewer))

;;; Retained output of the gerbil-parser qualification over the fixed Case
;;; source. The root qualification gate replays the parser and requires exact
;;; equality; Lambda only admits the typed projection into a POO subject.
(def AULegacyHL7v2PatientParserProjection
  '((schema . "gerbil-parser.hl7v2-adt-a08-patient.v1")
    (sourceDigest .
     "sha256:483dca758f175709eff204968df4b8b566b76a6711065f64ff91d99fd013e1dc")
    (grammarDigest .
     "sha256:f7e358f905a0f9c5004018fbfae60666da39cded0ff615127c0de8213ab64293")
    (sourceInterface . hl7v2)
    (sourceMessageType . "ADT^A08")
    (sourceVersion . "2.5.1")
    (identifierSystem . "urn:oid:1.2.36.1.2001.1005.17")
    (identifierValue . "8003608166690503")
    (familyName . "Nguyen")
    (givenNames "Ava")))

(def AULegacyHL7v2PatientSubject
  (healthcare-hl7v2-patient-projection->subject
   AULegacyHL7v2PatientParserProjection))

(def AULegacyHL7v2PatientFHIRCandidate
  (healthcare-au-legacy-patient->fhir-candidate
   AULegacyHL7v2PatientSubject))

(def AULegacyHL7v2PatientFieldMappings
  (.o patient-identifier:
      (healthcare-standard-migration-field-mapping
       "PID-3" "Patient.identifier[0]" 'copy-identifier
       "preserve the qualified Australian patient identifier system and value")
      patient-name:
      (healthcare-standard-migration-field-mapping
       "PID-5" "Patient.name[0]" 'copy-human-name
       "preserve the reviewed family and given name components")))

;;; AI owns bounded analysis and candidate assistance, never version selection,
;;; review authority or cutover authorization.  The exact source snapshot,
;;; target edition, mapping gaps and risks are part of its immutable receipt.
(def AULegacyHL7v2PatientAIAnalysis
  (healthcare-standard-migration-ai-analysis
   "lambda-episteme/healthcare/migration/au/hl7v2-adt-a08-to-au-core-patient/ai-analysis/v1"
   'hl7v2 "2.5.1"
   (.ref AULegacyHL7v2PatientSubject 'source-snapshot-digest)
   "hl7.fhir.au.core@1.0.0"
   (.ref FHIRAUCorePatientStandardProfile 'identity)
   AULegacyHL7v2PatientFieldMappings
   '()
   '(patient-identity-collision semantic-drift parallel-interface-divergence)
   'shadow-validate-then-phased-cutover
   "ai-mapping-assistant/example-v1" 'advisory-only))

(def AULegacyHL7v2PatientMigrationProposal
  (healthcare-standard-migration-proposal
   "lambda-episteme/healthcare/migration/au/hl7v2-adt-a08-to-au-core-patient/proposal/v1"
   'hl7v2
   (.ref FHIRAUCorePatientStandardProfile 'identity)
   (poo-flow-standard-digest AULegacyHL7v2PatientFHIRCandidate)
   (.ref AULegacyHL7v2PatientAIAnalysis 'mapping-evidence-digest)
   (.ref AULegacyHL7v2PatientAIAnalysis 'analysis-digest)
   "ai-mapping-assistant/example-v1" 'advisory-only))

(def AULegacyHL7v2PatientMigrationReview
  (healthcare-standard-migration-review
   AULegacyHL7v2PatientMigrationProposal
   "human-reviewer/example-au-clinical-informatician"
   'approved
   (poo-flow-standard-digest
    '(human-review-evidence example-au-patient-1 approved))))

(def AULegacyHL7v2PatientMigrationCase
  (healthcare-standard-migration-case
   "lambda-episteme/healthcare/migration/au/hl7v2-adt-a08-to-au-core-patient/v1"
   'AU 'hl7v2 "2.5.1" "hl7.fhir.au.core@1.0.0"
   (.ref AULegacyHL7v2PatientSubject 'source-snapshot-digest)
   (poo-flow-standard-digest AULegacyHL7v2PatientParserProjection)
   (.ref AULegacyHL7v2PatientSubject 'parser-grammar-digest)
   'qualified
   (poo-flow-standard-digest
    (list 'gerbil-parser-hl7v2-qualification
          (.ref AULegacyHL7v2PatientSubject 'source-snapshot-digest)
          (.ref AULegacyHL7v2PatientSubject 'parser-grammar-digest)
          (poo-flow-standard-digest AULegacyHL7v2PatientParserProjection)))
   AULegacyHL7v2PatientAIAnalysis
   AULegacyHL7v2PatientMigrationProposal
   AULegacyHL7v2PatientMigrationReview))

;;; AU data is a fixture extension of the generic migration FeatureModule.  It
;;; does not become a sibling module beside Standards.
(def AUHealthcareMigrationFixture
  (.o identity:
      "lambda-episteme/healthcare/standards/migration/fixtures/australia"
      jurisdiction: 'AU
      landscape: AULegacyHealthcareInterfaceLandscape
      cases:
      (.o hl7v2-patient: AULegacyHL7v2PatientMigrationCase)
      analyses:
      (.o hl7v2-patient: AULegacyHL7v2PatientAIAnalysis)
      proposals:
      (.o hl7v2-patient: AULegacyHL7v2PatientMigrationProposal)
      reviews:
      (.o hl7v2-patient: AULegacyHL7v2PatientMigrationReview)))

(def (migration-governance-binding slot owner evidence-kind status
                                   authority-bearing? payload canonical)
  (poo-flow-standard-governance-binding
   slot owner evidence-kind (poo-flow-standard-digest canonical)
   status authority-bearing? payload))

(def (healthcare-migration-governance-binding-valid? binding)
  (let ((slot (.ref binding 'slot))
        (payload (.ref binding 'payload)))
    (case slot
      ((authority-provider)
       (eq? payload CedarAuthorizationProvider))
      ((human-authorization)
       (or
        (and (eq? payload
                  HealthcareStandardMigrationHumanAuthorizationInterface)
             (equal? (.ref payload 'action)
                     "Healthcare::Action::\"approveStandardMigrationCutover\""))
        (and (eq? (.ref binding 'status) 'admitted)
             (eq? (.ref binding 'evidence-kind) 'cedar-human-permit)
             (.slot? payload 'request)
             (.slot? payload 'decision)
             (equal? (.ref (.ref payload 'request) 'action)
                     "Healthcare::Action::\"approveStandardMigrationCutover\""))))
      ((proof-assurance)
       (and (poo-flow-proof-assurance? payload)
            (.ref payload 'current?)
            (.ref payload 'admitted?)
            (equal? (.ref payload 'assurance-digest)
                    (.ref AUHealthcareMigrationProofAssurance
                          'assurance-digest))))
      ((conformance)
       (eq? payload FHIRAUCorePatientStandardProfile))
      ((audit-receipt)
       (healthcare-standard-migration-case? payload))
      (else #t))))

(def HealthcareStandardMigrationGovernanceInterface
  (poo-flow-standard-governance-interface
   "lambda-episteme/healthcare/standards/migration/governance"
   (.ref PooFlowStandardMigrationGovernanceInterface. 'required-slots)
   (.ref PooFlowStandardMigrationGovernanceInterface. 'optional-slots)
   (.ref PooFlowStandardMigrationGovernanceInterface. 'stage-requirements)
   (.o authority-provider:
       (migration-governance-binding
        'authority-provider "poo-flow/authorization/cedar"
        'cedar-dual-engine 'qualified #t CedarAuthorizationProvider
        '(poo-flow authorization cedar strict-lockstep))
       human-authorization:
       (migration-governance-binding
        'human-authorization "lambda-healthcare/standard-migration"
        'cedar-human-authorization-interface 'qualified #t
        HealthcareStandardMigrationHumanAuthorizationInterface
        '(Healthcare::MigrationReviewer
          Healthcare::Action::approveStandardMigrationCutover
          Healthcare::StandardMigration))
       proof-assurance:
       (migration-governance-binding
        'proof-assurance "lambda-healthcare/standard-migration"
        'poo-flow-proof-assurance 'qualified #f
        AUHealthcareMigrationProofAssurance
        (list (.ref AUHealthcareMigrationProofAssurance 'assurance-digest)
              +au-migration-tla-source-digest+
              +au-migration-tla-config-digest+
              +au-migration-lean-source-digest+
              +au-migration-cedar-lean-source-digest+))
       conformance:
       (migration-governance-binding
        'conformance "lambda-healthcare/fhir"
        'fhir-au-core-conformance 'qualified #f
        FHIRAUCorePatientStandardProfile
        (list (.ref FHIRAUCorePatientStandardProfile 'identity)
              "hl7.fhir.au.core@1.0.0"))
       audit-receipt:
       (migration-governance-binding
        'audit-receipt "lambda-healthcare/standard-migration"
        'migration-audit-contract 'qualified #f
        AULegacyHL7v2PatientMigrationCase
        (list (.ref AULegacyHL7v2PatientMigrationCase 'identity)
              (.ref AULegacyHL7v2PatientMigrationReview 'review-digest))))
   healthcare-migration-governance-binding-valid?))

(def HealthcareStandardMigrationFeatureModule
  (letrec
      ((feature-value
        (.cc
         (poo-flow-standard-feature-module
          "lambda-episteme/healthcare/standards/features/migration"
          'migration
          '(source-adapter mapping-proposal human-review conformance
            admission governance fixture)
          (.o australia: AUHealthcareMigrationFixture)
          HealthcareStandardMigrationGovernanceInterface
          '((owner . lambda-healthcare)))
         'source-interface-kinds '(hl7v2 cda national-service)
         '.candidate healthcare-au-legacy-patient->fhir-candidate
         '.admit healthcare-standard-migration-admit
         '.write-governance
         (lambda (binding)
           (.cc feature-value 'governance
                ((.ref (.ref feature-value 'governance)
                       '.write-governance)
                 binding)))
         '.validate-governance
         (lambda (stage)
           ((.ref (.ref feature-value 'governance)
                  '.validate-governance)
            stage)))))
    feature-value))
