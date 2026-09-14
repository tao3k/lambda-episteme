(import (only-in :clan/poo/object .o .ref .slot? object?)
        :poo-flow/lambda-episteme/modules/sdlc/types
        :poo-flow/lambda-episteme/modules/sdlc/objects
        :poo-flow/lambda-episteme/modules/sdlc/funs
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-profile
        :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        (only-in :gerbil/runtime/hash list->hash-table-string))
(export (import: :poo-flow/lambda-episteme/modules/sdlc/standards/nasa-7150-2d-profile)
        nasa-requirement-by-id nasa-matrix-invocation)

;;; Complete requirement index and matrix; execution and approvals remain separate.
(def nasa-requirement-index
  (list->hash-table-string
   (map (lambda (requirement)
          (cons (.ref requirement 'identity) requirement))
        nasa-requirement-catalog)))
(def (nasa-requirement-by-id identity-value)
  (or (hash-get nasa-requirement-index identity-value)
      (error "unknown NASA requirement" identity-value)))
;;; Matrix invocation is not final applicability: clause conditions and approved
;;; tailoring still apply. Institutional obligations use their own source text.
(def (nasa-matrix-invocation identity-value class-value)
  (unless (memq class-value '(a b c d e f)) (error "invalid NASA software class"))
  (let ((requirement (nasa-requirement-by-id identity-value)))
    (if (.slot? requirement 'class-matrix)
      (.ref (.ref requirement 'class-matrix) class-value)
      'requirement-text)))

(export nasa-trace-rules nasa-applicability nasa-project-obligations)
;;; Table 1, section 3.12.1. One relation supports both lookup directions;
;;; storing a second reversed edge is not required by this model.
(def (nasa-trace-rules class-value)
  (unless (memq class-value '(a b c d e f)) (error "invalid NASA software class"))
  (append
    (if (memq class-value '(a b c f))
      (list (sdlc-trace-rule "SWE-052/higher-requirements" 'higher-requirement 'requirement)) '())
    (if (memq class-value '(a b c d))
      (list (sdlc-trace-rule "SWE-052/hazards" 'requirement 'hazard)) '())
    (if (memq class-value '(a b c))
      (list (sdlc-trace-rule "SWE-052/design" 'requirement 'design)
            (sdlc-trace-rule "SWE-052/code" 'design 'code)) '())
    (if (memq class-value '(a b c d f))
      (list (sdlc-trace-rule "SWE-052/verification" 'requirement 'verification)
            (sdlc-trace-rule "SWE-052/nonconformances" 'requirement 'nonconformance)) '())))
(def (context-fact context key)
  (if (.slot? context key)
    (let ((value (.ref context key)))
      (unless (or (boolean? value) (eq? value 'unknown)) (error "invalid NASA context fact" key))
      value)
    'unknown))
(def (truth-or left right)
  (cond ((or (eq? left #t) (eq? right #t)) #t)
        ((and (eq? left #f) (eq? right #f)) #f) (else 'unknown)))
(def (truth-and left right)
  (cond ((or (eq? left #f) (eq? right #f)) #f)
        ((and (eq? left #t) (eq? right #t)) #t) (else 'unknown)))
(def (project-category-trigger context)
  ;; Project category and payload risk class are separate from software class.
  (truth-or (context-fact context 'category-1?)
            (truth-and (context-fact context 'category-2?)
                       (context-fact context 'payload-risk-a-or-b?))))

(export nasa-rule-mode nasa-conditional-requirements)
(def nasa-conditional-requirements
  '("SWE-023" "SWE-027" "SWE-032" "SWE-045" "SWE-070" "SWE-121" "SWE-131" "SWE-134" "SWE-141" "SWE-143" "SWE-146" "SWE-157" "SWE-178" "SWE-179" "SWE-193" "SWE-206" "SWE-211" "SWE-219" "SWE-220"))
(def nasa-unconditional-requirements
  '("SWE-013" "SWE-015" "SWE-016" "SWE-017" "SWE-018" "SWE-020" "SWE-022" "SWE-024" "SWE-033" "SWE-034" "SWE-036" "SWE-037" "SWE-039" "SWE-040" "SWE-042" "SWE-046" "SWE-050" "SWE-051" "SWE-052" "SWE-053" "SWE-054" "SWE-055" "SWE-057" "SWE-058" "SWE-060" "SWE-061" "SWE-062" "SWE-063" "SWE-065" "SWE-066" "SWE-068" "SWE-071" "SWE-073" "SWE-075" "SWE-077" "SWE-079" "SWE-080" "SWE-081" "SWE-082" "SWE-083" "SWE-084" "SWE-085" "SWE-086" "SWE-087" "SWE-088" "SWE-089" "SWE-090" "SWE-093" "SWE-094" "SWE-125" "SWE-135" "SWE-136" "SWE-139" "SWE-147" "SWE-148" "SWE-151" "SWE-154" "SWE-156" "SWE-159" "SWE-174" "SWE-176" "SWE-184" "SWE-185" "SWE-186" "SWE-187" "SWE-189" "SWE-190" "SWE-191" "SWE-192" "SWE-194" "SWE-195" "SWE-196" "SWE-199" "SWE-200" "SWE-201" "SWE-202" "SWE-203" "SWE-204" "SWE-205" "SWE-207" "SWE-210"))
(def nasa-institutional-requirements
  '("SWE-002" "SWE-004" "SWE-152" "SWE-129" "SWE-100" "SWE-098" "SWE-208" "SWE-209" "SWE-212" "SWE-221" "SWE-222" "SWE-223" "SWE-003" "SWE-005" "SWE-140" "SWE-095" "SWE-006" "SWE-091" "SWE-092" "SWE-142" "SWE-144" "SWE-153" "SWE-215" "SWE-216" "SWE-217" "SWE-214" "SWE-218" "SWE-126" "SWE-150" "SWE-021"))
(def nasa-rule-mode-index
  (list->hash-table-string
   (append (map (lambda (id) (cons id 'conditional))
                nasa-conditional-requirements)
           (map (lambda (id) (cons id 'unconditional))
                nasa-unconditional-requirements)
           (map (lambda (id) (cons id 'institutional))
                nasa-institutional-requirements))))
(def (nasa-rule-mode id)
  (let (entry (hash-get nasa-rule-mode-index id))
    (if entry
      entry
      (error "NASA requirement has no reviewed applicability rule" id))))

(def (nasa-condition id class-value context)
  (cond
   ((member id '("SWE-023" "SWE-219" "SWE-220")) (context-fact context 'safety-critical?))
   ((equal? id "SWE-134")
    (truth-or (context-fact context 'safety-critical?) (context-fact context 'mission-critical?)))
   ((equal? id "SWE-131") (context-fact context 'ivv-required?))
   ((member id '("SWE-178" "SWE-179")) (context-fact context 'ivv-performed?))
   ((equal? id "SWE-141")
    (truth-and (context-fact context 'reaching-kdp-a?)
               (truth-or (project-category-trigger context)
                         (context-fact context 'mdaa-selected-ivv?))))
   ((equal? id "SWE-143") (project-category-trigger context))
   ((equal? id "SWE-121") (context-fact context 'approved-tailoring-exists?))
   ((equal? id "SWE-027") (context-fact context 'reused-component?))
   ((member id '("SWE-146" "SWE-206")) (context-fact context 'auto-generated-code?))
   ((equal? id "SWE-032")
    (case class-value
      ((a) #t)
      ((b) (let (excluded (context-fact context 'nasa-class-d-payload?))
             (if (eq? excluded 'unknown) 'unknown (not excluded))))
      (else #f)))
   ((equal? id "SWE-157") (context-fact context 'communications-capable?))
   ((equal? id "SWE-070") (context-fact context 'flight-qualification-tools?))
   ((equal? id "SWE-193") (context-fact context 'loaded-behavior-inputs?))
   ((equal? id "SWE-211") (context-fact context 'embedded-reused-component?))
   ((equal? id "SWE-045") (context-fact context 'joint-audit?))
   ;; Explicit reviewed sets prevent future catalog additions falling through.
   (else (case (nasa-rule-mode id)
           ((unconditional institutional) #t)
           (else (error "missing conditional NASA implementation" id))))))
(def (nasa-applicability identity-value class-value context)
  (unless (object? context) (error "NASA context must be POO-native"))
  (let* ((row (nasa-requirement-by-id identity-value))
         (invocation-value (nasa-matrix-invocation identity-value class-value))
         (condition-value (nasa-condition identity-value class-value context))
         (status-value (cond ((eq? invocation-value 'not-invoked) 'not-invoked)
                             ((eq? invocation-value 'requirement-text) 'institutional-review-required)
                             ((eq? condition-value #t) 'applicable)
                             ((eq? condition-value #f) 'condition-not-triggered)
                             (else 'context-review-required))))
    (.o kind: 'sdlc.applicability standard: "nasa/npr-7150.2d" requirement: identity-value
        software-class: class-value status: status-value invocation: invocation-value
        source-url: (.ref row 'source-url) section: (.ref row 'section)
        tailoring: 'not-approved assessment: 'not-evaluated)))
(def (nasa-project-obligations class-value context)
  (map (lambda (r) (nasa-applicability (.ref r 'identity) class-value context))
       nasa-requirement-catalog))
