;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Final User Composition. Profiles and Scenarios are discovered from the
;;; sibling trees by the POO Flow-owned macro; no wrapper or import registry is
;;; maintained here.
(import :poo-flow/src/user-interface/config-discovery-syntax)

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
      AustraliaHealthcareRegionProfile)))
