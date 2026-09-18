;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Editable FHIR source declarations. Digests and byte counts are generated
;;; from checked-in bytes into source.lock.ss.

(import (only-in :clan/poo/object .o)
        (only-in :poo-flow/src/feature-system/source-lock-feature
                 SourceReference. SourceLockEntry. SourcesLock.))

(export +poo-flow-fhir-r4-package-source-identity+
        +poo-flow-fhir-medication-request-source-identity+
        +poo-flow-fhir-au-base-package-source-identity+
        +poo-flow-fhir-au-base-ig-source-identity+
        +poo-flow-fhir-au-core-package-source-identity+
        +poo-flow-fhir-au-core-ig-source-identity+
        +poo-flow-fhir-au-core-patient-source-identity+
        FHIRSources
        FHIRSourcesLock)

(def +poo-flow-fhir-r4-package-source-identity+
  "hl7.fhir.r4.core@4.0.1/source/package.json")
(def +poo-flow-fhir-medication-request-source-identity+
  "hl7.fhir.r4.core@4.0.1/source/StructureDefinition-MedicationRequest")
(def +poo-flow-fhir-au-base-package-source-identity+
  "hl7.fhir.au.base@5.0.0/source/package.json")
(def +poo-flow-fhir-au-base-ig-source-identity+
  "hl7.fhir.au.base@5.0.0/source/ImplementationGuide-hl7.fhir.au.base")
(def +poo-flow-fhir-au-core-package-source-identity+
  "hl7.fhir.au.core@1.0.0/source/package.json")
(def +poo-flow-fhir-au-core-ig-source-identity+
  "hl7.fhir.au.core@1.0.0/source/ImplementationGuide-hl7.fhir.au.core")
(def +poo-flow-fhir-au-core-patient-source-identity+
  "hl7.fhir.au.core@1.0.0/source/StructureDefinition-au-core-patient")

(def (fhir-source-reference identity-value path-value canonical-value
                            version-value authority-value package-value
                            artifact-value archive-digest-value)
  (.o (:: @ SourceReference.)
      identity: identity-value
      path: path-value
      canonical-uri: canonical-value
      exact-version: version-value
      representation: 'json
      metadata:
      (list (cons 'authority authority-value)
            (cons 'package package-value)
            (cons 'artifact artifact-value)
            (cons 'archive-sha256 archive-digest-value))))

(def FHIRSources
  (list
   (fhir-source-reference
    +poo-flow-fhir-r4-package-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.r4.core/4.0.1/package.json"
    "https://packages2.fhir.org/packages/hl7.fhir.r4.core/4.0.1"
    "4.0.1" 'hl7-international "hl7.fhir.r4.core" "package.json"
    "b090bf929e1f665cf2c91583720849695bc38d2892a7c5037c56cb00817fb091")
   (fhir-source-reference
    +poo-flow-fhir-medication-request-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.r4.core/4.0.1/StructureDefinition-MedicationRequest.json"
    "https://hl7.org/fhir/R4/StructureDefinition-MedicationRequest.json"
    "4.0.1" 'hl7-international "hl7.fhir.r4.core"
    "StructureDefinition-MedicationRequest"
    "b090bf929e1f665cf2c91583720849695bc38d2892a7c5037c56cb00817fb091")
   (fhir-source-reference
    +poo-flow-fhir-au-base-package-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.au.base/5.0.0/package.json"
    "https://hl7.org.au/fhir/5.0.0/package.tgz#package/package.json"
    "5.0.0" 'hl7-australia "hl7.fhir.au.base" "package.json"
    "168a71b4fcfdfab57256739f510abd593f06fdd7eb0918a7168bc087e77094d4")
   (fhir-source-reference
    +poo-flow-fhir-au-base-ig-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.au.base/5.0.0/ImplementationGuide-hl7.fhir.au.base.json"
    "https://hl7.org.au/fhir/5.0.0/ImplementationGuide-hl7.fhir.au.base.json"
    "5.0.0" 'hl7-australia "hl7.fhir.au.base"
    "ImplementationGuide-hl7.fhir.au.base"
    "168a71b4fcfdfab57256739f510abd593f06fdd7eb0918a7168bc087e77094d4")
   (fhir-source-reference
    +poo-flow-fhir-au-core-package-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.au.core/1.0.0/package.json"
    "https://hl7.org.au/fhir/core/1.0.0/package.tgz#package/package.json"
    "1.0.0" 'hl7-australia "hl7.fhir.au.core" "package.json"
    "26b3e5ea603957ca7cbf3cd04a171fe689bf180a03364dcfe0d576346c311a60")
   (fhir-source-reference
    +poo-flow-fhir-au-core-ig-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.au.core/1.0.0/ImplementationGuide-hl7.fhir.au.core.json"
    "https://hl7.org.au/fhir/core/1.0.0/ImplementationGuide-hl7.fhir.au.core.json"
    "1.0.0" 'hl7-australia "hl7.fhir.au.core"
    "ImplementationGuide-hl7.fhir.au.core"
    "26b3e5ea603957ca7cbf3cd04a171fe689bf180a03364dcfe0d576346c311a60")
   (fhir-source-reference
    +poo-flow-fhir-au-core-patient-source-identity+
    "modules/healthcare/standards/fhir/sources/hl7.fhir.au.core/1.0.0/StructureDefinition-au-core-patient.json"
    "https://hl7.org.au/fhir/core/1.0.0/StructureDefinition-au-core-patient.json"
    "1.0.0" 'hl7-australia "hl7.fhir.au.core"
    "StructureDefinition-au-core-patient"
    "26b3e5ea603957ca7cbf3cd04a171fe689bf180a03364dcfe0d576346c311a60")))

(include "source.lock.ss")
