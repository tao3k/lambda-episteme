;;; Source-bound review across every catalog requirement. No authority execution.
(import (only-in :clan/poo/object .o .ref .slot? object?)
        :poo-flow/src/module-system/contribution/model
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        (only-in :std/srfi/1 every any filter delete-duplicates iota))
(export nasa-requirement-criteria nasa-criterion-evidence nasa-assess-project
        nasa-tailoring-requirements nasa-safety-component nasa-safety-review)

(def (row-digest row)
  (.ref nasa-catalog-source-digests
        (string->symbol (string-append "chapter" (substring (.ref row 'section) 0 1)))))
(def (nasa-requirement-criteria id)
  (let* ((row (nasa-requirement-by-id id)) (parts (.ref row 'source-parts)))
    (map (lambda (part index)
           (.o identity: (string-append id "/p" (number->string (+ index 1)))
               requirement: id text: part source-url: (.ref row 'source-url)
               source-digest: (row-digest row)))
         parts (iota (length parts)))))
(def (nasa-criterion-evidence id project requirement-id criterion-id producer-value outcome-value)
  (unless (sdlc-project? project) (error "invalid NASA evidence project"))
  (unless (member criterion-id (map (lambda (c) (.ref c 'identity)) (nasa-requirement-criteria requirement-id)))
    (error "unknown NASA criterion" requirement-id criterion-id))
  (poo-flow-check-model SdlcCriterionEvidence
    (.o (:: @ (poo-flow-model-prototype SdlcCriterionEvidence))
        identity: id kind: 'sdlc.evidence
        subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
        standard: "nasa/npr-7150.2d" requirement: requirement-id criterion: criterion-id
        source-digest: (row-digest (nasa-requirement-by-id requirement-id))
        producer: producer-value outcome: outcome-value)))
(def (unique-ids? values)
  (let (ids (map (lambda (v) (.ref v 'identity)) values))
    (= (length ids) (length (delete-duplicates ids equal?)))))
(def (bound? value project)
  (every (lambda (key) (equal? (.ref value key) (.ref project key))) '(subject revision scope)))
(def (row-activity row)
  (let (section (.ref row 'section))
    (cond ((equal? (substring section 0 1) "2") 'institutional)
          ((equal? (substring section 0 1) "3") 'management)
          ((equal? (substring section 0 1) "5") 'support)
          (else (list-ref '(requirements architecture design implementation verification operations)
                          (- (string->number (substring section 2 3)) 1))))))
(def (assess-one row class-value project context evidence (applicability-override #f))
  (let* ((id (.ref row 'identity))
         (applicability-value (or applicability-override (nasa-applicability id class-value context)))
         (app-status (.ref applicability-value 'status))
         (criteria-values (nasa-requirement-criteria id))
         (related (filter (lambda (e) (and (equal? (.ref e 'requirement) id)
                                          (equal? (.ref e 'subject) (.ref project 'subject))
                                          (equal? (.ref e 'scope) (.ref project 'scope)))) evidence))
         (current (filter (lambda (e) (and (bound? e project)
                                          (equal? (.ref e 'source-digest) (row-digest row)))) related))
         (missing (filter (lambda (c) (not (any (lambda (e) (equal? (.ref c 'identity) (.ref e 'criterion))) current))) criteria-values))
         (status-value
          (cond ((not (eq? app-status 'applicable)) app-status)
                ((any (lambda (e) (eq? (.ref e 'outcome) 'fail)) current) 'reported-failure)
                ((null? missing) 'evidence-present)
                ((not (.ref project 'complete?)) 'unknown)
                ((> (length related) (length current)) 'stale-evidence)
                (else 'missing-evidence))))
    (.o requirement: id activity: (row-activity row) status: status-value
        applicability: applicability-value criteria: criteria-values
        missing-criteria: (map (lambda (c) (.ref c 'identity)) missing)
        evidence-identities: (map (lambda (e) (.ref e 'identity)) current)
        excluded-evidence: (- (length related) (length current))
        authority: 'not-verified compliance: 'not-evaluated)))
(def (validate-review-inputs project context evidence)
  (unless (and (sdlc-project? project) (object? context) (list? evidence)
               (every sdlc-criterion-evidence? evidence) (unique-ids? evidence))
    (error "invalid NASA project assessment inputs"))
  (for-each
   (lambda (e)
     (unless (and (equal? (.ref e 'standard) "nasa/npr-7150.2d")
                  (member (.ref e 'criterion)
                          (map (lambda (c) (.ref c 'identity))
                               (nasa-requirement-criteria (.ref e 'requirement)))))
       (error "evidence is not bound to a NASA criterion"))) evidence))
(def (nasa-assess-project class-value project context evidence)
  (validate-review-inputs project context evidence)
  (let* ((rows (map (lambda (row) (assess-one row class-value project context evidence)) nasa-requirement-catalog))
         (pending-values (filter (lambda (r) (not (memq (.ref r 'status) '(evidence-present not-invoked)))) rows)))
    (.o kind: 'sdlc.nasa-assessment subject: (.ref project 'subject)
        revision: (.ref project 'revision) scope: (.ref project 'scope)
        software-class: class-value requirements: rows pending: pending-values
        release-authorized?: #f compliance: 'not-evaluated authority: 'not-verified)))

;;; Appendix C routing plus Chapter 2. Context facts describe scope, not approval.
(def (nasa-tailoring-requirements id class-value context)
  (unless (object? context) (error "invalid tailoring context"))
  (let* ((row (nasa-requirement-by-id id))
         (invocation-value (nasa-matrix-invocation id class-value))
         (label (if (.slot? row 'class-matrix)
                  (.ref row (if (eq? class-value 'f) 'authority-f 'authority-a-e)) ""))
         (base (cond ((equal? label "HQ OCE and HQ OSMA") '(hq-oce hq-osma))
                     ((equal? label "HQ OSMA") '(hq-osma))
                     ((equal? label "Center and Center CIO") '(center-eta center-cio))
                     ((equal? label "Center") '(center-eta))
                     ((equal? label "CIO") '(cio)) (else '())))
         (health (if (.slot? context 'health-medical?) (.ref context 'health-medical?) 'unknown))
         (cyber? (equal? (substring (.ref row 'section) 0 (min 4 (string-length (.ref row 'section)))) "3.11")))
    (unless (or (boolean? health) (eq? health 'unknown)) (error "invalid health/medical context"))
    (.o requirement: id software-class: class-value invocation: invocation-value
        required-authorities: (delete-duplicates
          (append base (if cyber? '(saiso-or-designated-ciso) '())
                  (if (eq? health #t) '(chmo) '())
                  (if (equal? id "SWE-141") '(hq-osma) '())) eq?)
        context-review-required?: (eq? health 'unknown)
        required-records: '(rationale risk mitigations risk-acceptance authority-signatures archived-matrix)
        source-url: "https://nodis3.gsfc.nasa.gov/displayDir.cfm?Internal_ID=N_PR_7150_002D_&page_name=Chapter2"
        approved?: #f authority: 'not-verified)))

(def (nasa-safety-component id project safety-value coverage-value complexity-value)
  (unless (sdlc-project? project) (error "invalid safety snapshot"))
  (poo-flow-check-model SdlcSafetyComponent
    (.o (:: @ (poo-flow-model-prototype SdlcSafetyComponent)) identity: id
        subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
        safety-critical?: safety-value mcdc-percent: coverage-value cyclomatic-complexity: complexity-value)))
(def (nasa-safety-review project components)
  (unless (and (sdlc-project? project) (list? components)
               (every sdlc-safety-component? components) (unique-ids? components))
    (error "invalid safety inventory"))
  (let* ((current (filter (lambda (c) (and (bound? c project) (.ref c 'safety-critical?))) components))
         (reviews (map (lambda (c)
                         (let ((coverage-value (.ref c 'mcdc-percent)) (complexity-value (.ref c 'cyclomatic-complexity)))
                           (.o identity: (.ref c 'identity)
                               coverage: (cond ((eq? coverage-value 'unknown) 'unknown)
                                               ((= coverage-value 100) 'threshold-met) (else 'coverage-gap))
                               complexity: (cond ((eq? complexity-value 'unknown) 'unknown)
                                                 ((<= complexity-value 15) 'threshold-met)
                                                 (else 'waiver-review-required))))) current)))
    (.o kind: 'sdlc.nasa-safety-review components: reviews
        inventory: (cond ((not (.ref project 'complete?)) 'partial)
                         ((null? current) 'review-required) (else 'supplied-complete))
        excluded-components: (- (length components) (length current))
        release-authorized?: #f compliance: 'not-evaluated)))

(export nasa-tailoring-packet nasa-authority-attestation nasa-tailoring-review)
(def (nasa-tailoring-packet id project requirement-id rationale-value risk-value mitigations-value acceptance-value archive-value)
  (unless (sdlc-project? project) (error "invalid tailoring project"))
  (nasa-requirement-by-id requirement-id)
  (poo-flow-check-model SdlcTailoringPacket
    (.o (:: @ (poo-flow-model-prototype SdlcTailoringPacket)) identity: id
        subject: (.ref project 'subject) revision: (.ref project 'revision) scope: (.ref project 'scope)
        standard: "nasa/npr-7150.2d" requirement: requirement-id
        rationale: rationale-value risk: risk-value mitigations: mitigations-value
        risk-acceptance: acceptance-value archived-matrix: archive-value)))
(def (nasa-authority-attestation id packet authority-value signer-value record-value decision-value)
  (unless (sdlc-tailoring-packet? packet) (error "invalid tailoring packet"))
  (poo-flow-check-model SdlcAuthorityAttestation
    (.o (:: @ (poo-flow-model-prototype SdlcAuthorityAttestation)) identity: id
        subject: (.ref packet 'subject) revision: (.ref packet 'revision) scope: (.ref packet 'scope)
        standard: (.ref packet 'standard) requirement: (.ref packet 'requirement)
        request: (.ref packet 'identity) authority: authority-value signer: signer-value
        record: record-value decision: decision-value)))
(def (nasa-tailoring-review project class-value context packet attestations)
  (unless (and (sdlc-project? project) (sdlc-tailoring-packet? packet)
               (bound? packet project) (equal? (.ref packet 'standard) "nasa/npr-7150.2d")
               (list? attestations) (every sdlc-authority-attestation? attestations)
               (unique-ids? attestations))
    (error "invalid tailoring review inputs"))
  (let* ((routing (nasa-tailoring-requirements (.ref packet 'requirement) class-value context))
         (required (.ref routing 'required-authorities))
         (current (filter (lambda (a)
                            (and (bound? a project)
                                 (equal? (.ref a 'standard) (.ref packet 'standard))
                                 (equal? (.ref a 'requirement) (.ref packet 'requirement))
                                 (equal? (.ref a 'request) (.ref packet 'identity)))) attestations))
         (matches? (lambda (need supplied)
                     (if (eq? need 'saiso-or-designated-ciso)
                       ;; Delegation still needs external verification even if a
                       ;; record claims the designated Center CISO role.
                       (memq supplied '(saiso designated-ciso)) (eq? need supplied))))
         (relevant (filter (lambda (a) (any (lambda (need) (matches? need (.ref a 'authority))) required)) current))
         (missing (filter (lambda (need)
                            (not (any (lambda (a) (and (matches? need (.ref a 'authority))
                                                       (eq? (.ref a 'decision) 'approved))) relevant))) required))
         (status-value
          (cond ((or (not (eq? (.ref routing 'invocation) 'invoked)) (null? required)) 'scope-review-required)
                ((any (lambda (a) (eq? (.ref a 'decision) 'rejected)) relevant) 'reported-rejection)
                ((.ref routing 'context-review-required?) 'context-review-required)
                ((pair? missing) 'missing-authority-records)
                (else 'authority-verification-required))))
    (.o kind: 'sdlc.nasa-tailoring-review request: (.ref packet 'identity)
        status: status-value missing-authorities: missing
        accepted-record-identities: (map (lambda (a) (.ref a 'identity)) relevant)
        excluded-records: (- (length attestations) (length relevant))
        approved?: #f authority: 'not-verified)))


(export nasa-assess-institution)
;;; Center/Agency source obligations have their own review scope, so project
;;; reports do not silently discharge duties belonging to institutional owners.
(def (nasa-assess-institution class-value snapshot context evidence)
  (validate-review-inputs snapshot context evidence)
  (unless (memq class-value '(a b c d e f)) (error "invalid NASA software class"))
  (let* ((institutional (filter (lambda (r) (not (.slot? r 'class-matrix))) nasa-requirement-catalog))
         (reviews
          (map (lambda (r)
                 (let* ((id (.ref r 'identity))
                        (selected? (cond ((member id '("SWE-091" "SWE-092" "SWE-142"))
                                          (memq class-value '(a b c)))
                                         ((equal? id "SWE-006") (memq class-value '(a b c d)))
                                         (else #t)))
                        (app (.o (:: @ (nasa-applicability id class-value context))
                                 status: (if selected? 'applicable 'condition-not-triggered))))
                   (assess-one r class-value snapshot context evidence app))) institutional)))
    (.o kind: 'sdlc.nasa-institutional-assessment
        subject: (.ref snapshot 'subject) revision: (.ref snapshot 'revision)
        scope: (.ref snapshot 'scope) requirements: reviews
        authority: 'not-verified compliance: 'not-evaluated)))
