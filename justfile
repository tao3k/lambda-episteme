set shell := ["bash", "-uc"]

self_root := justfile_directory()
gerbil_parser_root := env_var_or_default("GERBIL_PARSER_ROOT", "")

default:
    @just --justfile '{{ self_root }}/justfile' --list

# The contributor owns its test interface. Every native Scheme test enters
# through `gerbil test`; the profiled runner emits observable worker receipts.
[group('test')]
test: test-scheme-all test-proof-impact test-proof

[group('test')]
test-scheme-all:
    cd '{{ self_root }}' && GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 180s gerbil test -v ./profiled-unit-tests.ss

[group('test')]
test-scheme module="ontology":
    cd '{{ self_root }}' && GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 60s gerbil test -v "t/{{ module }}/build-root.ss"

[group('test')]
test-scheme-atomic test_file:
    cd '{{ self_root }}' && LAMBDA_EPISTEME_TEST_PATH='{{ test_file }}' GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 60s gerbil test -v ./selected-test.ss

[group('test')]
test-proof-impact:
    cd '{{ self_root }}' && LAMBDA_EPISTEME_TEST_PATH='t/qualification/healthcare-standard-migration-assurance/impact-test.ss' GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 60s gerbil test -v ./selected-test.ss

[group('test')]
test-proof:
    cd '{{ self_root }}/proof/lean' && if test -d .lake/build; then lake build EpistemeHealthcareProof; else lake --try-cache build EpistemeHealthcareProof; fi

[group('test')]
test-proof-temporal:
    cd '{{ self_root }}/proof/lean' && if test -d .lake/build; then lake build EpistemeHealthcareTemporalProof; else lake --try-cache build EpistemeHealthcareTemporalProof; fi

[group('test')]
test-proof-cedar:
    cd '{{ self_root }}/proof/lean' && if test -d .lake/build; then lake build EpistemeHealthcareCedarProof; else lake --try-cache build EpistemeHealthcareCedarProof; fi

# Builds are deliberately separate and depend on the complete native test
# surface. std/make owns build concurrency and verbose compiler diagnostics.
[group('build')]
build: test
    cd '{{ self_root }}' && GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" gerbil build

[group('build')]
build-scheme:
    cd '{{ self_root }}' && GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" gerbil build

[group('qualification')]
qualify-healthcare-hl7v2:
    test -n '{{ gerbil_parser_root }}'
    cd '{{ self_root }}' && LAMBDA_EPISTEME_TEST_PATH='t/qualification/healthcare-hl7v2-migration/parser-receipt-test.ss' GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="{{ gerbil_parser_root }}:$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 60s gerbil test -v ./selected-test.ss

[group('qualification')]
qualify-healthcare-fhirpath:
    test -n '{{ gerbil_parser_root }}'
    cd '{{ self_root }}' && LAMBDA_EPISTEME_TEST_PATH='t/qualification/healthcare-fhirpath-syntax/parser-receipt-test.ss' GERBIL_BUILD_VERBOSE=1 GERBIL_PARSER_DIR='{{ gerbil_parser_root }}' GERBIL_LOADPATH="{{ gerbil_parser_root }}:$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 60s gerbil test -v ./selected-test.ss

[group('qualification')]
qualify-healthcare-fhir-reference-validator:
    cd '{{ self_root }}' && LAMBDA_EPISTEME_TEST_PATH='t/qualification/healthcare-fhir-reference-validator/replay-test.ss' GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=5s 120s gerbil test -v ./selected-test.ss

[group('maintenance')]
update-fhir-sources-lock:
    cd '{{ self_root }}' && GERBIL_BUILD_VERBOSE=1 GERBIL_LOADPATH="$PWD${GERBIL_LOADPATH:+:$GERBIL_LOADPATH}" timeout --foreground --signal=TERM --kill-after=3s 30s gerbil interactive tools/update-fhir-sources-lock.ss .
