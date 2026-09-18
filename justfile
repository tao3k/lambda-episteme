set shell := ["bash", "-uc"]

self_root := justfile_directory()

default:
    @just --justfile '{{ self_root }}/justfile' --list

test-python-align:
    #!/usr/bin/env bash
    set -euo pipefail

    SELF_ROOT='{{ self_root }}'
    SUPERPROJECT_ROOT="$(git -C "$SELF_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || true)"

    if [[ -n "$SUPERPROJECT_ROOT" && -d "$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src" ]]; then
      export PYTHONPATH="$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src${PYTHONPATH:+:$PYTHONPATH}"
    fi

    if ! (cd "$SELF_ROOT" && uv run python -c 'import wendao_core_lib.episteme_contracts' >/dev/null 2>&1); then
      echo "error: install wendao-core-lib or run from a superproject checkout that contains packages/python/wendao-core-lib" >&2
      exit 1
    fi

    echo "== python episteme align tests ==" >&2
    (
      cd "$SELF_ROOT"
      uv run python -m unittest discover -s tests -p 'test_*.py'
    )

ontology-registry:
    #!/usr/bin/env bash
    set -euo pipefail

    SELF_ROOT='{{ self_root }}'
    SUPERPROJECT_ROOT="$(git -C "$SELF_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || true)"

    if [[ -n "$SUPERPROJECT_ROOT" && -d "$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src" ]]; then
      export PYTHONPATH="$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src${PYTHONPATH:+:$PYTHONPATH}"
    fi

    if ! (cd "$SELF_ROOT" && uv run python -c 'import wendao_core_lib.episteme_contracts' >/dev/null 2>&1); then
      echo "error: install wendao-core-lib or run from a superproject checkout that contains packages/python/wendao-core-lib" >&2
      exit 1
    fi

    (
      cd "$SELF_ROOT"
      uv run python -m wendao_core_lib.episteme_contracts.wendao_ontology_registry --output ontology/registry.json
    )

ontology-registry-check:
    #!/usr/bin/env bash
    set -euo pipefail

    SELF_ROOT='{{ self_root }}'
    SUPERPROJECT_ROOT="$(git -C "$SELF_ROOT" rev-parse --show-superproject-working-tree 2>/dev/null || true)"

    if [[ -n "$SUPERPROJECT_ROOT" && -d "$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src" ]]; then
      export PYTHONPATH="$SUPERPROJECT_ROOT/packages/python/wendao-core-lib/src${PYTHONPATH:+:$PYTHONPATH}"
    fi

    if ! (cd "$SELF_ROOT" && uv run python -c 'import wendao_core_lib.episteme_contracts' >/dev/null 2>&1); then
      echo "error: install wendao-core-lib or run from a superproject checkout that contains packages/python/wendao-core-lib" >&2
      exit 1
    fi

    (
      cd "$SELF_ROOT"
      uv run python -m wendao_core_lib.episteme_contracts.wendao_ontology_registry --output ontology/registry.json --check
    )

build-wendao:
    #!/usr/bin/env bash
    set -euo pipefail

    SELF_ROOT='{{ self_root }}'
    SUPERPROJECT_ROOT="$(git -C "$SELF_ROOT" rev-parse --show-superproject-working-tree)"

    if [[ -z "$SUPERPROJECT_ROOT" ]]; then
      echo "error: wendao-episteme tests must execute from a checked-out superproject" >&2
      exit 1
    fi

    echo "== build wendao ==" >&2
    (
      cd "$SUPERPROJECT_ROOT"
      direnv exec . cargo build -p xiuxian-wendao --bin wendao
    )

test: build-wendao test-python-align
    #!/usr/bin/env bash
    set -euo pipefail

    SELF_ROOT='{{ self_root }}'
    SUPERPROJECT_ROOT="$(git -C "$SELF_ROOT" rev-parse --show-superproject-working-tree)"
    WENDAO_BIN="${WENDAO_BIN:-$SUPERPROJECT_ROOT/target/debug/wendao}"

    if [[ -z "$SUPERPROJECT_ROOT" ]]; then
      echo "error: wendao-episteme tests must execute from a checked-out superproject" >&2
      exit 1
    fi

    run_wendao() {
      (
        cd "$SUPERPROJECT_ROOT"
        "$WENDAO_BIN" "$@"
      )
    }

    run_expected_lint_failure() {
      local scenario="$1"
      echo "== lint expected-failure $(basename "$scenario") ==" >&2
      if run_wendao --root "$scenario" lint markdown docs >/dev/null 2>&1; then
        echo "error: expected lint failure for $scenario" >&2
        exit 1
      fi
    }

    for framework in \
      johnny-decimal \
      diataxis \
      evergreen-notes \
      adr \
      moc \
      folgezettel \
      ibis \
      structural-proprioception \
      search-reasoning \
      semantic-consistency \
      epistemic-sensemaking \
      temporal-scaffolding; do
      echo "== audit template $framework ==" >&2
      run_wendao audit --template "$framework" >/dev/null
    done

    for scenario in "$SELF_ROOT"/tests/fixtures/frameworks/*; do
      [[ -d "$scenario/docs" ]] || continue
      echo "== lint $(basename "$scenario") ==" >&2
      run_wendao --root "$scenario" lint markdown docs >/dev/null
    done

    run_expected_lint_failure "$SELF_ROOT/tests/fixtures/commands/lint_invalid_frontmatter"
    run_expected_lint_failure "$SELF_ROOT/tests/fixtures/commands/lint_invalid_skill_frontmatter_schema"

    echo "== lint valid_skill_frontmatter_schema ==" >&2
    run_wendao \
      --root "$SELF_ROOT/tests/fixtures/commands/lint_valid_skill_frontmatter_schema" \
      lint markdown docs >/dev/null

    echo "== audit load repo root ==" >&2
    run_wendao \
      --root "$SELF_ROOT/tests/fixtures/frameworks/johnny_decimal" \
      audit --load "$SELF_ROOT" docs >/dev/null

    echo "== audit load manifest file ==" >&2
    run_wendao \
      --root "$SELF_ROOT/tests/fixtures/frameworks/diataxis" \
      audit --load "$SELF_ROOT/episteme.toml" docs >/dev/null

    echo "wendao-episteme command checks passed" >&2

# Source-module lanes: consume installed POO Flow, never build a superproject.
build-scheme:
    cd '{{ self_root }}/../..' && just build-contribute lambda-episteme

test-scheme module="ontology":
    echo "[lambda-episteme-test] phase=module-selected module={{ module }}"
    cd '{{ self_root }}/../..' && just test-contribute lambda-episteme "{{ module }}"

test-scheme-atomic module="ontology" test_file="unit/ontology-test.ss":
    echo "[lambda-episteme-test] phase=file-selected module={{ module }} test={{ test_file }}"
    cd '{{ self_root }}/../..' && just test-contribute-atomic lambda-episteme "{{ module }}" "{{ test_file }}"

test-scheme-all:
    #!/usr/bin/env bash
    set -euo pipefail
    test_root="$(mktemp -d "${TMPDIR:-/tmp}/lambda-episteme-all-test.XXXXXX")"
    trap 'rm -rf -- "$test_root"' EXIT
    cd '{{ self_root }}'
    GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$test_root" GERBIL_LOADPATH="$PWD:$test_root/lib:$PWD/../../.gerbil/lib" env -u SDKROOT gxi ./unit-tests.ss

update-fhir-sources-lock:
    cd '{{ self_root }}/../..' && GERBIL_BUILD_VERBOSE=1 GERBIL_PATH="$PWD/.gerbil/contributions/lambda-episteme/source-lock-tool" GERBIL_LOADPATH="$PWD/packages/lambda-episteme:$PWD/.gerbil/lib" timeout --foreground --signal=TERM --kill-after=3s 30s gerbil interactive packages/lambda-episteme/tools/update-fhir-sources-lock.ss packages/lambda-episteme
