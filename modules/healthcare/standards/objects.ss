;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Healthcare Provider and Standard Profile are independently extensible axes.
;;; Their crossing is therefore owned by a Lambda-local CLOS generic.
(import :core/poo-clos/interface)

(export HealthcareStandardValidationExecutor
        HealthcareStandardValidationProtocol
        HealthcareStandardValidationGeneric
        healthcare-standard-validate)

(def HealthcareStandardValidationExecutor
  (poo-clos-class 'healthcare/standard-validation-executor))

(def HealthcareStandardValidationProtocol
  (poo-clos-generic-protocol 'healthcare/standard-validate))

(def HealthcareStandardValidationGeneric
  (poo-clos-generic-function
   'healthcare-standard-validate 4
   protocol: HealthcareStandardValidationProtocol))

(def (healthcare-standard-validate executor profile validation-closure subject)
  (poo-clos-call
   HealthcareStandardValidationGeneric executor profile validation-closure subject))
