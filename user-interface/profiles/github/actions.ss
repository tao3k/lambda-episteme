;;; -*- Gerbil -*-
;;; Reusable GitHub workflow Profiles; no scenario or runtime execution lives here.

(import (only-in :clan/poo/object .def)
        :poo-flow/src/modules/funflow/github-ci-contract)
(export actions)

(.def (actions @ poo-flow-funflow-github-ci-profile)
  (name 'actions)
  (owner 'lambda-episteme)
  (features '(pull-request environments deployments schema-validation))
  (extends poo-flow-funflow-github-ci-profile)
  (scope '(workflow))
  (capabilities '(pull-request environments deployments))
  (guard '(schema-validated))
  (runtime-executed #f)
  (source 'lambda-episteme.user-interface.profiles.github.actions))
