;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o .ref)
        (only-in :poo-flow/src/modules/standards/config
                 PooFlowStandardMigrationFeatureModule.)
        (only-in :poo-flow/src/modules/standards/funs
                 poo-flow-standard-digest)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/fhir/objects
                 FHIRAUCorePatientStandardProfile)
        "objects.ss"
        "funs.ss")

(export HealthcareStandardMigrationFeatureModule
        AUHealthcareMigrationFixture
        AULegacyHealthcareInterfaceLandscape
        AULegacyHL7v2PatientParserProjection
        AULegacyHL7v2PatientSubject
        AULegacyHL7v2PatientFHIRCandidate
        AULegacyHL7v2PatientMigrationProposal
        AULegacyHL7v2PatientMigrationReview
        AULegacyHL7v2PatientMigrationCase)

;;; The landscape is explicit so a migration program can select one old
;;; interface without pretending that Australia has a single cut-over format.
(def AULegacyHealthcareInterfaceLandscape
  (.o jurisdiction: 'AU
      legacy-interfaces:
      (.o hl7v2: (.o syntax-owner: 'gerbil-parser
                     semantic-owner: 'lambda-healthcare
                     typical-use: 'messages)
          cda: (.o syntax-owner: 'gerbil-parser
                   semantic-owner: 'lambda-healthcare
                   typical-use: 'documents)
          national-service:
          (.o syntax-owner: 'service-adapter
              semantic-owner: 'lambda-healthcare
              typical-use: 'national-service-api))
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
     "sha256:f340d1e7795086a914f05b050997e3402b70692af6a419f275d7e147a739ac29")
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

(def AULegacyHL7v2PatientMigrationProposal
  (healthcare-standard-migration-proposal
   "lambda-episteme/healthcare/migration/au/hl7v2-adt-a08-to-au-core-patient/proposal/v1"
   'hl7v2
   (.ref FHIRAUCorePatientStandardProfile 'identity)
   (poo-flow-standard-digest AULegacyHL7v2PatientFHIRCandidate)
   (poo-flow-standard-digest
    '(mapping-evidence reviewed-v1
      patient-id->identifier patient-name->name))
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
   'AU 'hl7v2 "2.5.1"
   (.ref AULegacyHL7v2PatientSubject 'source-snapshot-digest)
   (poo-flow-standard-digest AULegacyHL7v2PatientParserProjection)
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
      proposals:
      (.o hl7v2-patient: AULegacyHL7v2PatientMigrationProposal)
      reviews:
      (.o hl7v2-patient: AULegacyHL7v2PatientMigrationReview)))

(def HealthcareStandardMigrationFeatureModule
  (.o (:: @ PooFlowStandardMigrationFeatureModule.)
      identity: "lambda-episteme/healthcare/standards/features/migration"
      source-interface-kinds: '(hl7v2 cda national-service)
      fixtures: (.o australia: AUHealthcareMigrationFixture)
      .candidate: healthcare-au-legacy-patient->fhir-candidate
      .admit: healthcare-standard-migration-admit
      metadata: '((owner . lambda-healthcare))))
