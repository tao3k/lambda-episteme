// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

permit (
  principal is Healthcare::MigrationReviewer,
  action == Healthcare::Action::"approveStandardMigrationCutover",
  resource is Healthcare::StandardMigration
)
when {
  context.poo_flow.governanceAdmitted &&
  !context.aiAuthority &&
  context.migrationDigest == context.poo_flow.intentDigest &&
  context.formalAssuranceDigest != "" &&
  context.humanReviewDigest != "" &&
  context.targetStandardEdition == "hl7.fhir.au.core@1.0.0"
};
