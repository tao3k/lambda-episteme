;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(import :std/test
        (only-in :clan/poo/object .cc .ref)
        (only-in :std/srfi/1 find)
        :poo-flow/src/modules/temporal-causality/interface
        :poo-flow/lambda-episteme/modules/ontology/interface
        :poo-flow/lambda-episteme/user-interface/scenarios/healthcare/cases/australian-personal-care-coordination/case)

(export australian-personal-care-test)

(def admitted-receipt
  (ontology-compose-case AustralianPersonalCareCoordinationCase))

(def (assessment-by-profile receipt identity)
  (find (lambda (assessment)
          (equal? (.ref assessment 'profile-identity) identity))
        (.ref receipt 'governance-assessments)))

(def australian-personal-care-test
  (test-suite
   "Australian personal care coordination"

   (test-case "primary care and Support at Home Profiles admit one Case"
     (let ((evaluation (ontology-evaluate-case admitted-receipt)))
       (check (.ref admitted-receipt 'accepted?) => #t)
       (check (.ref admitted-receipt 'governance-handoff-ready?) => #t)
       (check (map (lambda (profile) (.ref profile 'name))
                   (.ref admitted-receipt 'profiles))
              => '(evidence privacy healthcare-base australian-primary-care
                            australian-support-at-home))
       (check (map (lambda (assessment)
                     (.ref assessment 'unresolved-threats))
                   (.ref admitted-receipt 'governance-assessments))
              => '(() () () () ()))
       (check (.ref evaluation 'accepted?) => #t)
       (check (.ref evaluation 'runtime-executed?) => #t)))

   (test-case "the causal cut keeps routine, unsafe and prospective paths apart"
     (let* ((event-graph
             (poo-flow-causal-event-graph
              "person-1" (.ref admitted-receipt 'events)))
            (cut (poo-flow-causal-cut event-graph 8))
            (classification
             (poo-flow-temporal-causal-classify
              event-graph cut "personal-care-request-1" 10)))
       (check (length (.ref cut 'events)) => 8)
       (check (.ref classification 'past-event-ids)
              => '("personal-care-request-1"
                   "primary-care-triage-1"
                   "mymedicare-registration-confirmed-1"
                   "preferred-gp-consultation-1"
                   "support-at-home-referral-1"
                   "aged-care-assessment-approved-1"
                   "support-plan-issued-1"))
       (check (.ref classification 'current-event-ids)
              => '("home-care-provider-accepted-1"))
       (check (.ref classification 'future-event-ids)
              => '("first-home-care-visit-1"))
       (check (.ref classification 'counterfactual-event-ids)
              => '("routine-booking-without-triage-1"
                   "unconsented-health-information-disclosure-1"))
       (check (.ref classification 'hypothesized-event-ids)
              => '("sustained-independent-living-1"))
       (check (.ref classification 'unknown-frontier) => '())
       (check (.ref classification 'release-authorized?) => #f)))

   (test-case "Support at Home authority evidence impacts this Case"
     (let* ((reasoning
             (ontology-case-reasoning-graph admitted-receipt))
            (impact
             (ontology-reasoning-impact
              reasoning
              "source:healthcare/australia/support-at-home/authority-evidence")))
       (check (.ref impact 'status) => 'snapshot-scoped-impact)
       (check (.ref impact 'target-entity-kind) => 'source)
       (check (.ref impact 'impacted-case-ids)
              => '(australian-personal-care-coordination))
       (check (.ref impact 'temporal-impact-assessed?) => #f)
       (check (.ref impact 'release-authorized?) => #f)))

   (test-case "each missing Australian care observation blocks handoff"
     (for-each
      (lambda (specification)
        (let* ((slot (car specification))
               (profile-identity (cadr specification))
               (threat-identity (caddr specification))
               (unsafe-case
                (.cc AustralianPersonalCareCoordinationCase
                     'case-id
                     (string->symbol
                      (string-append "missing-" (symbol->string slot)))
                     slot #f))
               (receipt (ontology-compose-case unsafe-case))
               (assessment
                (assessment-by-profile receipt profile-identity)))
          (check (.ref receipt 'accepted?) => #f)
          (check (.ref receipt 'governance-handoff-ready?) => #f)
          (check (.ref assessment 'unresolved-threats)
                 => (list threat-identity))))
      '((mymedicare-dual-consent-observed?
         "lambda-episteme/ontology/healthcare/australia/primary-care"
         "healthcare/australia/primary-care/threat/unconsented-registration")
        (primary-care-provider-eligibility-verified?
         "lambda-episteme/ontology/healthcare/australia/primary-care"
         "healthcare/australia/primary-care/threat/ineligible-practice-or-gp")
        (clinical-triage-complete?
         "lambda-episteme/ontology/healthcare/australia/primary-care"
         "healthcare/australia/primary-care/threat/untriaged-appointment")
        (health-information-sharing-consented?
         "lambda-episteme/ontology/healthcare/australia/primary-care"
         "healthcare/australia/primary-care/threat/health-information-over-disclosure")
        (aged-care-assessment-approved?
         "lambda-episteme/ontology/healthcare/australia/support-at-home"
         "healthcare/australia/support-at-home/threat/assessment-bypass")
        (support-plan-bound?
         "lambda-episteme/ontology/healthcare/australia/support-at-home"
         "healthcare/australia/support-at-home/threat/unbound-support-plan")
        (referral-code-active?
         "lambda-episteme/ontology/healthcare/australia/support-at-home"
         "healthcare/australia/support-at-home/threat/invalid-referral-code")
        (consumer-provider-choice-observed?
         "lambda-episteme/ontology/healthcare/australia/support-at-home"
         "healthcare/australia/support-at-home/threat/provider-choice-overridden"))))))
