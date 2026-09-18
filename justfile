set shell := ["bash", "-uc"]

self_root := justfile_directory()

default:
    @just --justfile '{{ self_root }}/justfile' --list

# Canonical repository acceptance: native Gerbil tests only. Production build
# remains a separate command and runs only after tests have passed.
test: test-scheme-all

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
