;;; Executable implementation ledger.  Implementation completeness and a
;;; project's compliance decision are deliberately separate dimensions.
(import :poo-flow/src/module-system/contribution/interface
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d
        :lambda-episteme/modules/sdlc/standards/nasa-7150-2d-catalog
        (only-in :std/srfi/1 every filter)
        (only-in :std/srfi/13 string-contains))
(export nasa-implementation-matrix nasa-implementation-summary)
(def referenced-standards
  '("NASA-STD-8739.8" "NASA-STD-1006" "NASA-STD-7009" "NPR 7120.5"
    "NPR 8705.4" "NPR 2210.1" "NPR 2810.1" "NPR 7120.11"
    "NPR 7123.1" "CMMI" "FAR" "NFS"))
(def (nasa-implementation-matrix)
  (map
   (lambda (row)
     (let* ((id (.ref row 'identity))
            (mode (nasa-rule-mode id))
            (validator-value (cond ((equal? id "SWE-052") 'trace-inventory)
                             ((member id '("SWE-219" "SWE-220")) 'safety-measurements)
                             (else 'source-bound-criterion-review)))
            (external-values
             (filter (lambda (ref)
                       (ormap (lambda (text) (string-contains text ref))
                              (append (.ref row 'source-parts)
                                      (.ref row 'source-notes))))
                     referenced-standards)))
       (.o requirement: id source-url: (.ref row 'source-url)
           paragraph-count: (length (.ref row 'source-parts))
           applicability: mode validator: validator-value
           implementation-status: 'implemented
           implementation-surfaces:
           '(catalog applicability criterion-evidence lifecycle-admission
             tailoring-routing negative-authority-boundary)
           evidence-binding: 'implemented
           stage-inventory-check:
           (if (eq? validator-value 'source-bound-criterion-review)
             'not-applicable 'required)
           external-references: external-values
           external-reference-status:
           (if (null? external-values) 'none 'declared-external-dependency)
           compliance-status: 'not-evaluated
           certification-status: 'not-claimed
           required-acceptance:
           (if (eq? validator-value 'source-bound-criterion-review)
             '(source-bound-content-verification revision-and-scope-verification)
             '(structured-inventory-verification source-bound-content-verification))
           regression-suite: (if (eq? validator-value 'source-bound-criterion-review)
                               "t/sdlc/unit/nasa-review-test.ss"
                               "t/sdlc/unit/nasa-structured-test.ss"))))
   nasa-requirement-catalog))

(def (nasa-implementation-summary)
  (let* ((rows (nasa-implementation-matrix))
         (gaps (filter (lambda (row)
                         (not (eq? (.ref row 'implementation-status)
                                   'implemented)))
                       rows)))
    (.o standard: "nasa/npr-7150.2d"
        requirement-count: (length rows)
        implemented-count:
        (length (filter (lambda (row)
                          (eq? (.ref row 'implementation-status) 'implemented))
                        rows))
        implementation-gap-identities:
        (map (lambda (row) (.ref row 'requirement)) gaps)
        implementation-complete?:
        (and (= (length rows) 130) (null? gaps)
             (every (lambda (row)
                      (if (memq (.ref row 'stage-inventory-check)
                                '(required not-applicable)) #t #f))
                    rows))
        project-compliance: 'not-evaluated
        certification: 'not-claimed)))
