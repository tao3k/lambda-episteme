;;; User selection projection. Importing this module enables no standard.
(import :poo-flow/src/module-system/contribution/interface
        :poo-flow/src/module-system/declaration/interface
        :lambda-episteme/governance/objects
        :lambda-episteme/modules/sdlc/types
        :lambda-episteme/modules/sdlc/objects
        :lambda-episteme/modules/sdlc/funs
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        (only-in :std/srfi/1 every))
(export sdlc-config)

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
      (sdlc-with-standards SdlcProfile
        (if (null? flags) '() (list Nasa7150_2D))))))
