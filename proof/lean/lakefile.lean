-- SPDX-FileCopyrightText: 2026 tao3k team and Contributors
--
-- SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

import Lake
open Lake DSL

package «lambda-episteme-proof» where
  version := v!"0.1.0"

/-! The vertical proof consumes only the published POO Flow temporal-causality
core. The exact revision prevents a parent checkout or sibling worktree from
silently changing the theorem base. -/
require «poo-flow-proof» from git
  "https://github.com/tao3k/poo-flow.git"
  @ "da492eea00a7dab502cfb4c7586edefbba96bbec"
  / "packages/proof/lean"

@[default_target]
lean_lib EpistemeHealthcareTemporalProof where
  roots := #[
    `EpistemeProof.Healthcare.AIAssistedPrescriptionCausalityRefinement,
    `EpistemeProof.Healthcare.StandardMigrationRefinement
  ]

lean_lib EpistemeHealthcareCedarProof where
  roots := #[
    `EpistemeProof.Healthcare.StandardMigrationCedarAuthorization
  ]

/-! Release/CI aggregate. Developers build one owner-specific library above
without materializing the unrelated Cedar or temporal import closure. -/
lean_lib EpistemeHealthcareProof where
  roots := #[
    `EpistemeProof
  ]
