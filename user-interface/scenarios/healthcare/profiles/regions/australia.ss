;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import (only-in :clan/poo/object .def .o)
        (only-in :poo-flow/src/modules/governance/objects
                 poo-flow-governance-precondition
                 poo-flow-governance-threat)
        (only-in :poo-flow/lambda-episteme/modules/ontology/interface
                 ontology-source)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/governance
                 healthcare-contextual-governance-assessment)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/primary-care
                 PrimaryCareProfile)
        (only-in :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/profiles/support-at-home
                 SupportAtHomeProfile))

(export AustraliaHealthcareRegionProfile)

;;; A Region owns jurisdictional evidence and compliance deltas.  The care
;;; journey and its semantic vocabulary remain reusable across jurisdictions.
(.def (AustraliaHealthcareRegionProfile self SupportAtHomeProfile)
  (identity "lambda-episteme/ontology/healthcare/regions/australia")
  (name 'australia)
  (.import
   (.o primary-care: PrimaryCareProfile
       support-at-home: SupportAtHomeProfile))
  (.add-concept (.o))
  (.add-relation (.o))
  (.add-source
   (.o primary-care-authority:
       (ontology-source
        "healthcare/regions/australia/primary-care/authority-evidence"
        "user-interface/scenarios/healthcare/sources/regions/australia/primary-care-authority.json"
        'json 'scenario 'healthcare #f)
       support-at-home-authority:
       (ontology-source
        "healthcare/regions/australia/support-at-home/authority-evidence"
        "user-interface/scenarios/healthcare/sources/regions/australia/support-at-home-authority.json"
        'json 'scenario 'healthcare #f)))
  (.add-rule (.o))
  (.add-threat
   (.o primary-care-program-drift:
       (poo-flow-governance-threat
        "healthcare/regions/australia/threat/primary-care-program-drift"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/precondition/primary-care-program"
          #t "evidence:current-mymedicare-program"))
        mitigations:
        '("validate MyMedicare registration and provider requirements against current authority evidence"))
       home-support-program-drift:
       (poo-flow-governance-threat
        "healthcare/regions/australia/threat/home-support-program-drift"
        'critical 'mitigated
        (list
         (poo-flow-governance-precondition
          "healthcare/regions/australia/precondition/home-support-program"
          #t "evidence:current-support-at-home-program"))
        mitigations:
        '("validate assessment, support-plan and referral requirements against current authority evidence"))))
  (policies
   (.o region: 'australia
       jurisdiction-code: 'AU
       primary-care-program: 'mymedicare
       home-support-program: 'support-at-home))
  (.add-capability (.o))
  (.add-query (.o))
  (.assess-governance
   (lambda (context)
     (healthcare-contextual-governance-assessment
      self context
      '((regional-primary-care-program-verified?
         . "healthcare/regions/australia/threat/primary-care-program-drift")
        (regional-home-support-program-verified?
         . "healthcare/regions/australia/threat/home-support-program-drift"))))))
