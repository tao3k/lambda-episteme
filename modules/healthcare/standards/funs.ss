;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Boundary: fail-closed base method for unsupported Provider/Profile crosses.
(import (only-in :clan/poo/mop .defmethod-bundle)
        :core/poo-clos/interface
        "objects.ss")

(export HealthcareStandardDefaultValidationMethod
        HealthcareStandardDefaultValidationMethods)

(def HealthcareStandardDefaultValidationMethod
  (poo-clos-method
   'healthcare/standard-validation-unsupported
   (list (poo-clos-class-specializer HealthcareStandardValidationExecutor)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer)
         (poo-clos-any-specializer))
   (lambda (_frame _executor profile _validation-closure _subject)
     (error "Healthcare Standard Provider/Profile crossing is unsupported"
            profile))))

(.defmethod-bundle HealthcareStandardDefaultValidationMethods
  HealthcareStandardValidationProtocol
  HealthcareStandardDefaultValidationMethod)

(poo-clos-compose-method-bundle
 HealthcareStandardValidationGeneric
 HealthcareStandardDefaultValidationMethods)
