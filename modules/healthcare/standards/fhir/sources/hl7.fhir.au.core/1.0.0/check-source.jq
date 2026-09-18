# SPDX-FileCopyrightText: 2026 tao3k team and Contributors
# SPDX-License-Identifier: Apache-2.0 AND LGPL-2.1-or-later

(.resourceType == "StructureDefinition")
and (.id == "au-core-patient")
and (.url == "http://hl7.org.au/fhir/core/StructureDefinition/au-core-patient")
and (.version == "1.0.0")
and (.baseDefinition == "http://hl7.org.au/fhir/StructureDefinition/au-patient")
and (.type == "Patient")
and (
  [
    .differential.element[]?.constraint[]?
    | select(
        .key == "au-core-pat-01"
        or .key == "au-core-pat-02"
        or .key == "au-core-pat-03"
      )
    | .key
  ]
  == ["au-core-pat-01", "au-core-pat-02", "au-core-pat-03"]
)
