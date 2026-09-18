# Software Engineering Decision Policy

Software engineering ontology extensions must keep implementation artifacts
linked to the decisions or evidence that authorize them.

Architecture dependency relations must remain acyclic, and every
`ImplementationArtifact` must declare the `DecisionRecord` that authorizes it.
