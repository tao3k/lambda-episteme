;;; -*- Gerbil -*-
;;; SPDX-FileCopyrightText: 2026 tao3k team and Contributors
;;;
;;; SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

;;; Exact change-impact qualification between the migration TLA+ model and its
;;; Lean refinement.  A changed upstream digest must invalidate the retained
;;; downstream Binding before an Agent can write it into the governance slot.
(import :std/test
        (only-in :clan/poo/object .all-slots .cc .ref)
        (only-in :std/crypto/digest sha256)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/text/hex hex-encode)
        (only-in :poo-flow/src/modules/standards/interface
                 poo-flow-standard-digest)
        (only-in :poo-flow/src/modules/proof/interface
                 poo-flow-proof-assurance)
        (only-in :poo-flow/lambda-episteme/modules/healthcare/standards/migration/interface
                 AUHealthcareMigrationFormalModelEvidence
                 AUHealthcareMigrationTLAConfigEvidence
                 AUHealthcareMigrationImpactContract
                 AUHealthcareMigrationRefinementProofEvidence
                 AUHealthcareMigrationRefinementReceipt
                 AUHealthcareMigrationCedarAuthorizationEvidence
                 AUHealthcareMigrationCedarAuthorizationReceipt
                 AUHealthcareMigrationRefinementBinding
                 AUHealthcareMigrationProofAssurance
                 HealthcareStandardMigrationGovernanceInterface))

(export healthcare-standard-migration-proof-impact-test)

(def (file-digest path)
  (string-append
   "sha256:"
   (hex-encode
    (sha256 (call-with-input-file path read-all-as-string)))))

(def healthcare-standard-migration-proof-impact-test
  (test-suite
   "Healthcare Standard migration TLA+ to Lean impact"
   (test-case "retained governance evidence matches exact source bytes"
     (let* ((tla-path
             (.ref AUHealthcareMigrationFormalModelEvidence 'path))
            (cfg-path
             (.ref AUHealthcareMigrationTLAConfigEvidence 'path))
            (lean-path
             (.ref AUHealthcareMigrationRefinementProofEvidence 'path))
            (cedar-lean-path
             (.ref AUHealthcareMigrationCedarAuthorizationEvidence 'path))
            (tla-digest (file-digest tla-path))
            (lean-source (call-with-input-file lean-path read-all-as-string)))
       (check-equal?
        tla-digest
        (.ref AUHealthcareMigrationFormalModelEvidence 'content-digest))
       (check-equal?
        (file-digest cfg-path)
        (.ref AUHealthcareMigrationTLAConfigEvidence 'content-digest))
       (check-equal?
        (file-digest lean-path)
        (.ref AUHealthcareMigrationRefinementProofEvidence 'content-digest))
       (check-equal?
        (file-digest cedar-lean-path)
        (.ref AUHealthcareMigrationCedarAuthorizationEvidence
              'content-digest))
       (check-equal?
        (.ref (.ref AUHealthcareMigrationCedarAuthorizationEvidence
                    'metadata)
              'upstream-semantics)
        "PooFlowProof.PooC3.CedarAuthorizationSemantics")
       (check-equal?
        (.ref (.ref AUHealthcareMigrationRefinementProofEvidence 'metadata)
              'tla-source-digest)
        tla-digest)
       (check-equal? (and (string-contains lean-source tla-digest) #t) #t)
       (check-equal?
        (.ref AUHealthcareMigrationImpactContract 'upstream-content-digest)
        tla-digest)
       (check-equal?
        (.ref AUHealthcareMigrationImpactContract 'downstream-content-digest)
        (.ref AUHealthcareMigrationRefinementProofEvidence 'content-digest))
       (check-equal?
        (.all-slots (.ref AUHealthcareMigrationImpactContract 'impact-map))
        '(AINeverGrantsAuthority ReviewRequiresConformance
          CedarPermitRequiresHumanReview CutoverRequiresCedarPermit
          CutoverRequiresCompleteEvidence))))
   (test-case "an Agent cannot write a stale TLA impact Binding"
     (let* ((binding
             (.ref
              (.ref HealthcareStandardMigrationGovernanceInterface 'bindings)
              'proof-assurance))
            (stale-tla
             (.cc AUHealthcareMigrationFormalModelEvidence 'content-digest
                  (poo-flow-standard-digest 'changed-tla-source)))
            (stale-assurance
             (poo-flow-proof-assurance
              "lambda-episteme/healthcare/standard-migration/stale-proof"
              (list stale-tla AUHealthcareMigrationTLAConfigEvidence
                    AUHealthcareMigrationRefinementProofEvidence
                    AUHealthcareMigrationCedarAuthorizationEvidence)
              (list AUHealthcareMigrationRefinementReceipt
                    AUHealthcareMigrationCedarAuthorizationReceipt)
              (list AUHealthcareMigrationRefinementBinding)))
            (stale-binding (.cc binding 'payload stale-assurance)))
       (check-equal? (.ref stale-assurance 'current?) #f)
       (check-equal? (.ref stale-assurance 'admitted?) #f)
       (check-exception
        ((.ref HealthcareStandardMigrationGovernanceInterface
               '.write-governance)
         stale-binding)
        true)))))
