# Contributing

## Build, test, prove, audit

```sh
alr build                                   # build the library
cd tests && alr build && ./bin/tests        # AUnit suite (must stay green)
cd examples && alr build && ./bin/quickstart
./tools/check_dependencies.sh               # headless dependency-boundary audit
./tools/prove.sh                            # GNATprove on the SPARK_Mode units
```

## Coding standard

Ada 2022 under the strict switch set (`-gnat2022 -gnata -gnatyM120 -gnatX` plus
the generated `-gnaty`/`-gnatwa`/`-gnatVa` development set). Three-space
indentation; comments follow `-gnatyc`; array aggregates use `[...]`. A
user-defined `"="` on a record whose components have their own primitive `"="`
needs an explicit `overriding` marker.

## Design rules (non-negotiable)

- The core is **headless**: no I/O, clock, randomness, sockets, or ecosystem
  dependencies (`tools/check_dependencies.sh` enforces this). See
  [`docs/ai/prohibited_patterns.md`](docs/ai/prohibited_patterns.md).
- Ordinary failure is a structured issue, never an exception.
- No global mutable state; no address-derived identity; every attacker-facing
  dimension is bounded.
- Adding a public unit: add it to `src/`, extend the relevant
  [`docs/ai/package_map.md`](docs/ai/package_map.md) row, cover it with tests,
  and update [`docs/ai/invariants.md`](docs/ai/invariants.md) if it touches an
  invariant.

## How this library was built

In vertical slices (phases 0–12); each phase delivered a compiling, tested
increment. See [`docs/PHASE_STATUS.md`](docs/PHASE_STATUS.md) and the AI docs in
[`docs/ai/`](docs/ai/).
