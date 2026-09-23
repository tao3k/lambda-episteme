;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Final User Composition. The root imports exactly the POO values it composes;
;;; no filesystem scanner or implicit re-export widens this boundary.
(import (only-in :poo-flow/src/module-system/profile-composition/use-syntax
                 use-composition)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/privacy
                 PrivacyProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/regions/australia
                 AustraliaHealthcareRegionProfile))

(export healthcare-australia)

(def healthcare-australia
  (use-composition healthcare-australia
    (use-module healthcare as care
      (profile EvidenceProfile)
      (profile PrivacyProfile)
      (profile HealthcareBaseProfile)
      (profile AustraliaHealthcareRegionProfile))
    (compose
      (profiles care
        EvidenceProfile
        PrivacyProfile
        HealthcareBaseProfile
        AustraliaHealthcareRegionProfile))))
