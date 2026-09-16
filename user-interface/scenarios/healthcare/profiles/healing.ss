;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-concept ontology-relation)
        (only-in :poo-flow/lambda-episteme/user-interface/profiles/ontology/evidence
                 EvidenceProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/base
                 HealthcareBaseProfile))

(export HealingProfile)

(.def (HealingProfile @ HealthcareBaseProfile)
  (identity "lambda-episteme/ontology/healthcare/healing")
  (name 'healing)
  (.import (.o healthcare: HealthcareBaseProfile evidence: EvidenceProfile))
  (.add-concept
   (.o healing-episode:
       (ontology-concept 'HealingEpisode '(Encounter) '(time-bound))
       recovery-milestone:
       (ontology-concept 'RecoveryMilestone '(Evidence) '())))
  (.add-relation
   (.o recovers-from:
       (ontology-relation 'RECOVERS_FROM 'HealingEpisode 'Condition '())
       reaches-milestone:
       (ontology-relation
        'REACHES_MILESTONE 'HealingEpisode 'RecoveryMilestone
        '(evidence-required))))
  (.add-source (.o))
  (.add-rule (.o))
  (policies (.o observation: 'time-bound
                outcome: 'evidence-required))
  (.add-query (.o healing-progress: 'healing-progress)))
