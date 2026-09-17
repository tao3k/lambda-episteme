;;; -*- Gerbil -*-
;;; Boundary: contributor tests its source object without entering core tests.

(import (only-in :std/test check-equal? check-exception test-case test-suite)
        (only-in :std/error Error?)
        (only-in :poo-flow/src/core/failure execution-failure?)
        (only-in :poo-flow/src/module-system/load poo-flow-modules!)
        (only-in :poo-flow/src/module-system/declaration/interface
                 poo-flow-user-module-selection
                 poo-flow-user-module-selection-entrypoint
                 poo-flow-user-module-selection-source-ref
                 poo-flow-user-module-bundles->modules)
        (only-in :poo-flow/src/module-system/loader/source
                 poo-flow-module-source-ref-kind
                 poo-flow-module-source-ref-metadata
                 poo-flow-module-source-ref-value)
        (only-in :poo-flow/src/module-system/loader/module-source-interface
                 make-poo-flow-module-source-collection
                 make-poo-flow-module-load-path
                 make-poo-flow-contribution-module-source
                 make-poo-flow-contribution-module-load-path
                 make-poo-flow-user-interface-module-source
                 make-poo-flow-user-interface-module-load-path
                 make-poo-flow-contribution-registry-entry
                 make-poo-flow-contribution-registry
                 poo-flow-contribution-registry-load-path
                 extend-poo-flow-module-load-path
                 poo-flow-module-source-collection-identity
                 poo-flow-module-source-collection-owner
                 poo-flow-module-source-collection-modules-root
                 poo-flow-load-modules
                 poo-flow-module-load-path-collections
                 poo-flow-official-contribution-load-path
                 poo-flow-module-selection-source-refs)
        (rename-in :poo-flow/lambda-episteme/user-interface/init
                   (poo-flow-user-module-bundles
                    lambda-user-module-bundles)))

(export lambda-episteme-source-collection-test)

;;; Contribution module Sources are intentionally expressed from the POO Flow
;;; composition root.  Scope the cwd change to one test so another file in the
;;; same native gxtest batch never observes fixture state.
(def +poo-flow-composition-root+
  (if (file-exists? "modules/ontology/interface.ss")
    (path-normalize (path-expand "../.."))
    (current-directory)))

(def (call-with-poo-flow-composition-root thunk)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory +poo-flow-composition-root+))
      thunk
      (lambda () (current-directory previous-directory)))))

(defrule (composition-root-test-case name body ...)
  (test-case name
    (call-with-poo-flow-composition-root (lambda () body ...))))

(def (metadata-ref source-ref key)
  (let (entry (assq key (poo-flow-module-source-ref-metadata source-ref)))
    (and entry (cdr entry))))

(def lambda-episteme-module-source
  (make-poo-flow-contribution-module-source
   'lambda-episteme "packages/lambda-episteme"))

(def lambda-episteme-module-load-path
  (make-poo-flow-contribution-module-load-path
   'lambda-episteme "packages/lambda-episteme"))

(def lambda-episteme-user-module-source
  (make-poo-flow-user-interface-module-source
   'lambda-episteme-user "packages/lambda-episteme/user-interface"))

(def lambda-episteme-user-module-load-path
  (make-poo-flow-user-interface-module-load-path
   'lambda-episteme-user
   "packages/lambda-episteme/user-interface"
   lambda-episteme-module-load-path))

(def lambda-episteme-source-collection-test
  (test-suite "Lambda module source collection and unified POO load path"
    (composition-root-test-case "poo-flow-load-modules discovers public module interfaces"
      (let (sources
            (poo-flow-load-modules lambda-episteme-module-source))
        (check-equal?
         (map poo-flow-module-source-ref-value sources)
         '("packages/lambda-episteme/modules/decision-kind/interface.ss"
           "packages/lambda-episteme/modules/diataxis/interface.ss"
           "packages/lambda-episteme/modules/ontology/interface.ss"))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'module-key)) sources)
         '((custom . decision-kind)
           (custom . diataxis)
           (custom . ontology)))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'module-layout)) sources)
         '(poo-flow-module-v1 poo-flow-module-v1 poo-flow-module-v1))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'entrypoint-role)) sources)
         '(interface interface interface))))

    (composition-root-test-case "Lambda init uses the same source-neutral module declaration"
      (let* ((selections
              (poo-flow-user-module-bundles->modules
               lambda-user-module-bundles))
             (selection (car (reverse selections))))
        (check-equal? (poo-flow-user-module-selection-source-ref selection) #f)
        (check-equal? (poo-flow-user-module-selection-entrypoint selection) #f)))

    (composition-root-test-case "an explicit @ modules path resolves public interfaces"
      (let* ((selection
              (caar
               (poo-flow-modules!
                :custom (@ "packages/lambda-episteme/modules" +private))))
             (sources
              (poo-flow-module-selection-source-refs
               lambda-episteme-module-load-path selection)))
        (check-equal?
         (map poo-flow-module-source-ref-value sources)
         '("packages/lambda-episteme/modules/decision-kind/interface.ss"
           "packages/lambda-episteme/modules/diataxis/interface.ss"
           "packages/lambda-episteme/modules/ontology/interface.ss"))))

    (composition-root-test-case "an official registered name expands the trusted contribution"
      (let* ((selection
              (caar (poo-flow-modules! :custom (lambda-episteme))))
             (sources
              (poo-flow-module-selection-source-refs
               poo-flow-official-contribution-load-path
               selection)))
        (check-equal? (length sources) 3)
        (check-equal?
         (map poo-flow-module-source-ref-kind sources)
         '(local local local))
        (check-equal?
         (map poo-flow-module-source-ref-value sources)
         '("packages/lambda-episteme/modules/decision-kind/interface.ss"
           "packages/lambda-episteme/modules/diataxis/interface.ss"
           "packages/lambda-episteme/modules/ontology/interface.ss"))))

    (composition-root-test-case "a registered module name resolves one contributed module"
      (let* ((selection (caar (poo-flow-modules! :custom (ontology))))
             (source
              (car
               (poo-flow-module-selection-source-refs
                poo-flow-official-contribution-load-path selection))))
        (check-equal? (metadata-ref source 'source-collection)
                      'lambda-episteme)
        (check-equal? (poo-flow-module-source-ref-value source)
                      "packages/lambda-episteme/modules/ontology/interface.ss")))

    (composition-root-test-case "a missing registered checkout produces a pinned materialization source"
      (let* ((registry
              (make-poo-flow-contribution-registry
               (list
                (make-poo-flow-contribution-registry-entry
                 'remote-contribution
                 "https://example.invalid/remote-contribution.git"
                 "0123456789abcdef"
                 "absent/remote-contribution"
                 "modules"
                 '(remote-module)))))
             (load-path (poo-flow-contribution-registry-load-path registry))
             (selection
              (caar (poo-flow-modules! :custom (remote-contribution))))
             (source
              (car (poo-flow-module-selection-source-refs
                    load-path selection))))
        (check-equal? (poo-flow-module-source-ref-kind source) 'registry)
        (check-equal? (metadata-ref source 'repository)
                      "https://example.invalid/remote-contribution.git")
        (check-equal? (metadata-ref source 'revision) "0123456789abcdef")
        (check-equal? (metadata-ref source 'materialization) 'required)))

    (composition-root-test-case "the User Interface exposes a user-first private module source"
      (check-equal?
       (map poo-flow-module-source-collection-identity
            (poo-flow-module-load-path-collections
             lambda-episteme-user-module-load-path))
       '(lambda-episteme-user poo-flow-maintained lambda-episteme))
      (check-equal?
       (poo-flow-module-source-collection-owner
        lambda-episteme-user-module-source)
       'user)
      (check-equal?
       (poo-flow-module-source-collection-modules-root
        lambda-episteme-user-module-source)
       "packages/lambda-episteme/user-interface/modules"))

    (composition-root-test-case "the extended load path resolves core before contributor sources"
      (check-equal?
       (map poo-flow-module-source-collection-identity
            (poo-flow-module-load-path-collections
             lambda-episteme-module-load-path))
       '(poo-flow-maintained lambda-episteme))
      (let* ((core-selection
              (poo-flow-user-module-selection 'flow 'funflow '()))
             (core-source
              (car (poo-flow-module-selection-source-refs
                    lambda-episteme-module-load-path core-selection))))
        (check-equal? (metadata-ref core-source 'source-collection)
                      'poo-flow-maintained)
        (check-equal? (poo-flow-module-source-ref-value core-source)
                      "src/modules/funflow/interface.ss")))

    (composition-root-test-case "the same selection syntax resolves Lambda through its source object"
      (let* ((selection
              (car
               (reverse
                (poo-flow-user-module-bundles->modules
                 lambda-user-module-bundles))))
             (source
              (car (poo-flow-module-selection-source-refs
                    poo-flow-official-contribution-load-path selection))))
        (check-equal? (metadata-ref source 'source-collection) 'lambda-episteme)
        (check-equal? (metadata-ref source 'source-owner) 'contributor)
        (check-equal? (poo-flow-module-source-ref-value source)
                      "packages/lambda-episteme/modules/ontology/interface.ss")))

    (composition-root-test-case "a user source placed first overrides the contributor source"
      (let* ((user-source
              (make-poo-flow-module-source-collection
               'user-modules 'user "packages/lambda-episteme" "modules"))
             (user-first
             (make-poo-flow-module-load-path
               'user-first
               (cons user-source
                     (poo-flow-module-load-path-collections
                      poo-flow-official-contribution-load-path))))
             (selection
              (car
               (reverse
                (poo-flow-user-module-bundles->modules
                 lambda-user-module-bundles))))
             (source
              (car (poo-flow-module-selection-source-refs
                    user-first selection))))
        (check-equal? (metadata-ref source 'source-collection) 'user-modules)))

    (composition-root-test-case "duplicate collection identities fail during composition"
      (check-exception
       (extend-poo-flow-module-load-path
        lambda-episteme-module-load-path
        'duplicate
        (list lambda-episteme-module-source))
       Error?))

    (composition-root-test-case "explicit private paths remain an intentional escape hatch"
      (let* ((selection
              (caar
               (poo-flow-modules!
                :custom (private-module @ "./private/module" +doctor))))
             (source
              (car (poo-flow-module-selection-source-refs
                    lambda-episteme-module-load-path selection))))
        (check-equal? (poo-flow-module-source-ref-value source)
                      "./private/module/interface.ss")))

    (composition-root-test-case "a missing source fails before loader execution"
      (check-exception
       (poo-flow-module-selection-source-refs
        lambda-episteme-module-load-path
        (poo-flow-user-module-selection 'custom 'missing '()))
       execution-failure?))))
