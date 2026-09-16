// SPDX-FileCopyrightText: 2026 tao3k team and Contributors
// SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

permit (
  principal is Healthcare::Provider,
  action == Healthcare::Action::"administerMedication",
  resource is Healthcare::MedicationOrder
)
when {
  principal == resource.assignedProvider &&
  resource.reconciliationObserved &&
  context.poo_flow.governanceAdmitted &&
  context.assuranceClosed &&
  context.trajectoryHandoffReady
};
