;;; Package public surface. Upstream PackageSpec follows its import closure.
(import "governance/interface.ss"
        "modules/adr/interface.ss"
        "modules/decision-kind/interface.ss"
        "modules/diataxis/interface.ss"
        "modules/sdlc/interface.ss"
        "modules/sdlc/standards/interface.ss")
(export (import: "governance/interface.ss")
        (import: "modules/adr/interface.ss")
        (import: "modules/decision-kind/interface.ss")
        (import: "modules/diataxis/interface.ss")
        (import: "modules/sdlc/interface.ss")
        (import: "modules/sdlc/standards/interface.ss"))
