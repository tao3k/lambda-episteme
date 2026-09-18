-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import PooFlowProof.PooC3.CedarAuthorizationSemantics

namespace EpistemeProof.Healthcare.StandardMigrationCedarAuthorization

open PooFlowProof.PooC3.CedarAuthorizationSemantics

/-!
Vertical Cedar specification for the AU legacy-interface migration Case.

The actual decision is the pinned upstream `Cedar.Spec.isAuthorized` result.
This refinement adds only Healthcare-owned projection obligations: the exact
reviewer/action/resource kinds, independent human review, target conformance,
rollback evidence, and the rule that AI has no cutover authority.
-/

structure MigrationCedarProjection where
  input : CedarAuthorizationInput
  principalKind : String
  action : String
  resourceKind : String
  humanReviewBound : Bool
  targetConformanceBound : Bool
  rollbackSnapshotRetained : Bool
  aiAuthority : Bool

structure MigrationCutoverAdmission
    (projection : MigrationCedarProjection) : Prop where
  reviewerKindExact :
    projection.principalKind = "Healthcare::MigrationReviewer"
  actionExact :
    projection.action =
      "Healthcare::Action::approveStandardMigrationCutover"
  resourceKindExact :
    projection.resourceKind = "Healthcare::StandardMigration"
  independentHumanReview : projection.humanReviewBound = true
  targetConformance : projection.targetConformanceBound = true
  rollbackEvidence : projection.rollbackSnapshotRetained = true
  aiHasNoAuthority : projection.aiAuthority = false
  cedarAllows :
    (authorize projection.input).decision = Cedar.Spec.Decision.allow

theorem cutoverRequiresIndependentHumanReview
    {projection : MigrationCedarProjection}
    (admission : MigrationCutoverAdmission projection) :
    projection.humanReviewBound = true :=
  admission.independentHumanReview

theorem cutoverNeverDelegatesAuthorityToAI
    {projection : MigrationCedarProjection}
    (admission : MigrationCutoverAdmission projection) :
    projection.aiAuthority = false :=
  admission.aiHasNoAuthority

theorem cutoverRequiresExactHealthcareCedarProjection
    {projection : MigrationCedarProjection}
    (admission : MigrationCutoverAdmission projection) :
    projection.principalKind = "Healthcare::MigrationReviewer" ∧
      projection.action =
        "Healthcare::Action::approveStandardMigrationCutover" ∧
      projection.resourceKind = "Healthcare::StandardMigration" := by
  exact ⟨admission.reviewerKindExact, admission.actionExact,
    admission.resourceKindExact⟩

theorem cedarDenyBlocksCutover
    (projection : MigrationCedarProjection)
    (denied :
      (authorize projection.input).decision = Cedar.Spec.Decision.deny) :
    ¬MigrationCutoverAdmission projection := by
  intro admission
  rw [admission.cedarAllows] at denied
  contradiction

theorem explicitCedarForbidBlocksCutover
    (projection : MigrationCedarProjection)
    (forbidden :
      Cedar.Thm.IsExplicitlyForbidden
        projection.input.request
        projection.input.entities
        projection.input.policies) :
    ¬MigrationCutoverAdmission projection := by
  apply cedarDenyBlocksCutover projection
  exact forbid_forces_deny projection.input forbidden

end EpistemeProof.Healthcare.StandardMigrationCedarAuthorization
