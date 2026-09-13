;;; Source contribution contracts only. No parser, query engine, or evaluator.
(import :poo-flow/src/module-system/contribution/interface
        (only-in :std/srfi/1 every))
(export GovernanceProfile. source-asset source-asset? governance-profile?
        governance-module)

(def GovernanceProfile.
  (.o kind: 'lambda-episteme.governance-profile
      revision: "1" owner: "lambda-episteme"
      ontology: (.o) policies: (.o) source-assets: '()))
(def (nonempty-string? value)
  (and (string? value) (> (string-length value) 0)))
(def (has-slots? value slots)
  (and (object? value) (every (lambda (slot) (.slot? value slot)) slots)))
(def (source-asset? value)
  (and (has-slots? value '(identity path language))
       (nonempty-string? (.ref value 'identity))
       (nonempty-string? (.ref value 'path))
       (symbol? (.ref value 'language))))
(def (source-asset identity-value path-value language-value)
  (let ((value (.o identity: identity-value path: path-value language: language-value)))
    (unless (source-asset? value) (error "invalid source asset" identity-value))
    value))
(def (governance-profile? value)
  (and (has-slots? value '(kind identity revision owner ontology policies source-assets))
       (eq? (.ref value 'kind) 'lambda-episteme.governance-profile)
       (every (lambda (slot) (nonempty-string? (.ref value slot))) '(identity revision owner))
       (object? (.ref value 'ontology)) (object? (.ref value 'policies))
       (list? (.ref value 'source-assets))
       (every source-asset? (.ref value 'source-assets))))
(def (governance-module profile-value)
  (unless (governance-profile? profile-value) (error "invalid governance profile"))
  (make-contribution (.ref profile-value 'identity) (.ref profile-value 'revision)
                     (.ref profile-value 'owner) profile-value '(knowledge-governance) '()))
