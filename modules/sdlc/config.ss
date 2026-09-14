;;; User selection projection. Importing this module enables no standard.
(import :poo-flow/src/module-system/declaration/interface
        :poo-flow/lambda-episteme/governance/objects
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/funs
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-profile
        (only-in :std/srfi/1 every))
(export sdlc-config sdlc-nasa-7150-profile)

;;; Module-owned base Profile for scenarios that explicitly select NASA
;;; NPR 7150.2D. User compositions derive scenario Profiles from this value.
(def sdlc-nasa-7150-profile
  (sdlc-with-standards SdlcProfile (list Nasa7150_2D)))

(def (sdlc-config selection)
  (unless (and (poo-flow-user-module-selection? selection)
               (equal? (poo-flow-user-module-selection-key selection) '(custom . sdlc)))
    (error "expected a custom/sdlc selection"))
  (let ((flags (poo-flow-user-module-selection-flags selection)))
    (unless (every (lambda (flag) (eq? flag '+nasa-7150-2d)) flags)
      (error "unsupported SDLC feature" flags))
    (unless (<= (length flags) 1)
      (error "duplicate SDLC feature" flags))
    (governance-module
     (if (null? flags) SdlcProfile sdlc-nasa-7150-profile))))
