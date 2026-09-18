;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .o)
        (only-in :clan/poo/mop validate)
        :poo-flow/src/module-system/poo-clos/interface
        (only-in :poo-flow/src/modules/standards/objects
                 poo-flow-standard-constraint-profile)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/objects
                 HealthcareStandardValidationExecutor)
        "types.ss")

(export FHIRStandardValidationExecutor
        FHIRValidationExecutor
        FHIRMedicationRequestStandardProfile
        FHIRAUCorePatientStandardProfile
        poo-flow-fhir-capability
        poo-flow-fhir-constraint)

(def (poo-flow-fhir-capability identity-value capability-value state-value
                               owner-value evidence-digests-value detail-value)
  (validate
   PooFlowFhirCapability
   (.o kind: +poo-flow-fhir-capability-kind+
       identity: identity-value
       capability: capability-value
       state: state-value
       owner: owner-value
       evidence-digests: evidence-digests-value
       detail: detail-value)))

(def FHIRStandardValidationExecutor
  (poo-clos-class
   'healthcare/fhir-standard-validation-executor
   direct-superclasses: (list HealthcareStandardValidationExecutor)))

(def FHIRValidationExecutor
  (poo-clos-make-instance FHIRStandardValidationExecutor))

(def FHIRMedicationRequestStandardProfile
  (.o (:: @
          (poo-flow-standard-constraint-profile
           "http://hl7.org/fhir/StructureDefinition/MedicationRequest"
           "2026-09-17" '("hl7.fhir.r4.core@4.0.1") '()
           '((constraint-source . materialized-artifact))
           '("hl7.fhir.r4.core@4.0.1/MedicationRequest") '()
           '((owner . lambda-episteme) (industry . healthcare))
           'source-reviewed))
      identity:
      "http://hl7.org/fhir/StructureDefinition/MedicationRequest"
      provider-identity:
      "lambda-episteme/healthcare/standards/provider/fhir/v1"
      resource-kind: 'MedicationRequest))

(def FHIRAUCorePatientStandardProfile
  (.o (:: @
          (poo-flow-standard-constraint-profile
           "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"
           "2026-09-17" '("hl7.fhir.au.core@1.0.0") '()
           '((constraint-source . materialized-artifact))
           '("hl7.fhir.au.core@1.0.0/StructureDefinition/au-core-patient") '()
           '((owner . lambda-episteme) (industry . healthcare))
           'reference-qualified))
      identity:
      "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient"
      provider-identity:
      "lambda-episteme/healthcare/standards/provider/fhir/v1"
      resource-kind: 'Patient))

(def (poo-flow-fhir-constraint identity-value constraint-kind-value path-value
                               expected-value support-state-value)
  (validate
   PooFlowFhirConstraint
   (.o kind: +poo-flow-fhir-constraint-kind+
       identity: identity-value
       constraint-kind: constraint-kind-value
       path: path-value
       expected: expected-value
       support-state: support-state-value)))
