;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Lambda Healthcare composes the generic Standards Lego stud with its FHIR
;;; family, exact editions, catalog and Provider.  Core owns none of these.
(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/modules/standards/config
                 poo-flow-standard-default-budget
                 poo-flow-standards-module)
        (only-in "fhir/config.ss"
                 FHIRStandardsCatalog
                 FHIRValidationProvider
                 FHIRStandardFamily
                 FHIRR4StandardRef
                 AUBaseStandardRef
                 AUCoreStandardRef)
        (only-in "fhir/objects.ss"
                 FHIRMedicationRequestStandardProfile
                 FHIRAUCorePatientStandardProfile)
        (only-in "migration/config.ss"
                 HealthcareStandardMigrationFeatureModule))

(export HealthcareStandardsModule)

(def HealthcareStandardsModule
  (.o (:: @
          (poo-flow-standards-module
           "lambda-episteme/modules/healthcare/standards"
           FHIRStandardsCatalog
           poo-flow-standard-default-budget
           (.o fhir: FHIRValidationProvider)
           (.o migration: HealthcareStandardMigrationFeatureModule)))
      industry: 'healthcare
      families: (.o fhir: FHIRStandardFamily)
      editions:
      (.o fhir-r4: FHIRR4StandardRef
          au-base: AUBaseStandardRef
          au-core: AUCoreStandardRef)
      profiles:
      (.o medication-request: FHIRMedicationRequestStandardProfile
          au-core-patient: FHIRAUCorePatientStandardProfile)))
