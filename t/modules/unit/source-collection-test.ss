;;; -*- Gerbil -*-
;;; Boundary: contributor tests its source object without entering core tests.

(import (only-in :std/test check-equal? check-exception test-case test-suite)
        (only-in :std/error Error?)
        (only-in :agentic-ai-lab/modules/workflow/control-plane/failure execution-failure?)
        (only-in :yuanxu/module-system/selection/syntax
                 agentic-ai-lab-modules!)
        (only-in :yuanxu/module-system/selection/objects
                 agentic-ai-lab-user-module-selection
                 agentic-ai-lab-user-module-selection-entrypoint
                 agentic-ai-lab-user-module-selection-source-ref
                 agentic-ai-lab-user-module-bundles->modules)
        (only-in :yuanxu/module-system/source/objects
                 agentic-ai-lab-module-source-ref-kind
                 agentic-ai-lab-module-source-ref-metadata
                 agentic-ai-lab-module-source-ref-value)
        (only-in :yuanxu/module-system/source/collection make-agentic-ai-lab-module-source-collection make-agentic-ai-lab-module-load-path make-agentic-ai-lab-contribution-module-source make-agentic-ai-lab-user-interface-module-source make-agentic-ai-lab-user-interface-module-load-path extend-agentic-ai-lab-module-load-path agentic-ai-lab-module-source-collection-identity agentic-ai-lab-module-source-collection-owner agentic-ai-lab-module-source-collection-modules-root agentic-ai-lab-module-source-collection-interfaces agentic-ai-lab-module-load-path-collections)
        (only-in :agentic-ai-lab/modules/module-authoring/module-source-collection make-agentic-ai-lab-contribution-module-load-path)
        (only-in :agentic-ai-lab/modules/workflow/scenario/configuration/module-source-selection
                 agentic-ai-lab-module-selection-source-refs)
        (rename-in :agentic-ai-lab/lambda-episteme/user-interface/init
                   (agentic-ai-lab-user-module-bundles
                    lambda-user-module-bundles)))

(export lambda-episteme-source-collection-test)

;;; The contributor is tested from its own checkout. Parent-repository mount
;;; paths belong to Agentic AI Lab integration tests, not this independent package.
(defrule (composition-root-test-case name body ...)
  (test-case name body ...))

(def (metadata-ref source-ref key)
  (let (entry (assq key (agentic-ai-lab-module-source-ref-metadata source-ref)))
    (and entry (cdr entry))))

(def lambda-episteme-module-source
  (make-agentic-ai-lab-contribution-module-source
   'lambda-episteme "."))

(def lambda-episteme-module-load-path
  (make-agentic-ai-lab-contribution-module-load-path
   'lambda-episteme "."))

(def lambda-episteme-user-module-source
  (make-agentic-ai-lab-user-interface-module-source
   'lambda-episteme-user "user-interface"))

(def lambda-episteme-user-module-load-path
  (make-agentic-ai-lab-user-interface-module-load-path
   'lambda-episteme-user
   "user-interface"
   lambda-episteme-module-load-path))

(def lambda-episteme-contribution-load-path
  (make-agentic-ai-lab-contribution-module-load-path 'lambda-episteme "."))

(def lambda-episteme-source-collection-test
  (test-suite "Lambda module source collection and unified POO load path"
    (composition-root-test-case "agentic-ai-lab-module-source-collection-interfaces discovers public module interfaces"
      (let (sources
            (agentic-ai-lab-module-source-collection-interfaces lambda-episteme-module-source))
        (check-equal?
         (map agentic-ai-lab-module-source-ref-value sources)
         '("modules/decision-kind/interface.ss"
           "modules/diataxis/interface.ss"
           "modules/healthcare/interface.ss"
           "modules/ontology/interface.ss"))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'module-key)) sources)
         '((custom . decision-kind)
           (custom . diataxis)
           (custom . healthcare)
           (custom . ontology)))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'module-layout)) sources)
         '(agentic-ai-lab-module-v1 agentic-ai-lab-module-v1
           agentic-ai-lab-module-v1 agentic-ai-lab-module-v1))
        (check-equal?
         (map (lambda (source) (metadata-ref source 'entrypoint-role)) sources)
         '(interface interface interface interface))))

    (composition-root-test-case "Lambda init uses the same source-neutral module declaration"
      (let* ((selections
              (agentic-ai-lab-user-module-bundles->modules
               lambda-user-module-bundles))
             (selection (car (reverse selections))))
        (check-equal? (agentic-ai-lab-user-module-selection-source-ref selection) #f)
        (check-equal? (agentic-ai-lab-user-module-selection-entrypoint selection) #f)))

    (composition-root-test-case "an explicit @ modules path resolves public interfaces"
      (let* ((selection
              (caar
               (agentic-ai-lab-modules!
                :custom (@ "./modules" +private))))
             (sources
              (agentic-ai-lab-module-selection-source-refs
               lambda-episteme-module-load-path selection)))
        (check-equal?
         (map agentic-ai-lab-module-source-ref-value sources)
         '("./modules/decision-kind/interface.ss"
           "./modules/diataxis/interface.ss"
           "./modules/healthcare/interface.ss"
           "./modules/ontology/interface.ss"))))

    (composition-root-test-case "the contribution identity expands its checked-out modules"
      (let* ((selection
              (caar (agentic-ai-lab-modules! :custom (lambda-episteme))))
             (sources
              (agentic-ai-lab-module-selection-source-refs
               lambda-episteme-contribution-load-path
               selection)))
        (check-equal? (length sources) 4)
        (check-equal?
         (map agentic-ai-lab-module-source-ref-kind sources)
         '(local local local local))
        (check-equal?
         (map agentic-ai-lab-module-source-ref-value sources)
         '("modules/decision-kind/interface.ss"
           "modules/diataxis/interface.ss"
           "modules/healthcare/interface.ss"
           "modules/ontology/interface.ss"))))

    (composition-root-test-case "a module name resolves one contributed module"
      (let* ((selection (caar (agentic-ai-lab-modules! :custom (ontology))))
             (source
              (car
               (agentic-ai-lab-module-selection-source-refs
                lambda-episteme-contribution-load-path selection))))
        (check-equal? (metadata-ref source 'source-collection)
                      'lambda-episteme)
        (check-equal? (agentic-ai-lab-module-source-ref-value source)
                      "modules/ontology/interface.ss")))

    (composition-root-test-case "the User Interface exposes a user-first private module source"
      (check-equal?
       (map agentic-ai-lab-module-source-collection-identity
            (agentic-ai-lab-module-load-path-collections
             lambda-episteme-user-module-load-path))
       '(lambda-episteme-user lambda-episteme agentic-ai-lab-maintained))
      (check-equal?
       (agentic-ai-lab-module-source-collection-owner
        lambda-episteme-user-module-source)
       'user)
      (check-equal?
       (agentic-ai-lab-module-source-collection-modules-root
        lambda-episteme-user-module-source)
       "user-interface/modules"))

    (composition-root-test-case "the same selection syntax resolves Lambda through its source object"
      (let* ((selection
              (car
               (reverse
                (agentic-ai-lab-user-module-bundles->modules
                 lambda-user-module-bundles))))
             (source
              (car (agentic-ai-lab-module-selection-source-refs
                    lambda-episteme-contribution-load-path selection))))
        (check-equal? (metadata-ref source 'source-collection) 'lambda-episteme)
        (check-equal? (metadata-ref source 'source-owner) 'contributor)
        (check-equal? (agentic-ai-lab-module-source-ref-value source)
                      "modules/ontology/interface.ss")))

    (composition-root-test-case "a user source placed first overrides the contributor source"
      (let* ((user-source
              (make-agentic-ai-lab-module-source-collection
               'user-modules 'user "." "modules"))
             (user-first
             (make-agentic-ai-lab-module-load-path
               'user-first
               (cons user-source
                     (agentic-ai-lab-module-load-path-collections
                      lambda-episteme-contribution-load-path))))
             (selection
              (car
               (reverse
                (agentic-ai-lab-user-module-bundles->modules
                 lambda-user-module-bundles))))
             (source
              (car (agentic-ai-lab-module-selection-source-refs
                    user-first selection))))
        (check-equal? (metadata-ref source 'source-collection) 'user-modules)))

    (composition-root-test-case "duplicate collection identities fail during composition"
      (check-exception
       (extend-agentic-ai-lab-module-load-path
        lambda-episteme-module-load-path
        'duplicate
        (list lambda-episteme-module-source))
       Error?))

    (composition-root-test-case "explicit private paths remain an intentional escape hatch"
      (let* ((selection
              (caar
               (agentic-ai-lab-modules!
                :custom (private-module @ "./private/module" +doctor))))
             (source
              (car (agentic-ai-lab-module-selection-source-refs
                    lambda-episteme-module-load-path selection))))
        (check-equal? (agentic-ai-lab-module-source-ref-value source)
                      "./private/module/interface.ss")))

    (composition-root-test-case "a missing source fails before loader execution"
      (check-exception
       (agentic-ai-lab-module-selection-source-refs
        lambda-episteme-module-load-path
        (agentic-ai-lab-user-module-selection 'custom 'missing '()))
       execution-failure?))))
