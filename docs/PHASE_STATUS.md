# Phase Status

The library is built in vertical slices (spec §83). Each phase delivers a
compilable API, implementation, tests, docs, invariant updates, a dependency
check, and an example/fixture.

| Phase | Title | Status |
|-------|-------|--------|
| 0 | Repository & feasibility prototypes | **complete** |
| 1 | Foundational value layer | **complete** |
| 2 | Issues, results, and projections | not started |
| 3 | Contexts, profiles, structural metadata | not started |
| 4 | Minimal typed validator engine | not started |
| 5 | Standard scalar validators | not started |
| 6 | Composition, conditions, prerequisites, profiles | not started |
| 7 | Collections | not started |
| 8 | Recursive objects, patch, transitions | not started |
| 9 | Deferred validation | not started |
| 10 | Complete diagnostics | not started |
| 11 | Hardening | not started |
| 12 | Documentation and release | not started |

## Phase 0 — complete

Repository scaffolded as an Alire leaf library (`validation`) with an AUnit test
subcrate (`validation_tests`). The bare library and the test suite build clean
under the strict switch set (`-gnat2022 -gnata -gnatyM120 -gnatX` plus the
generated `-gnaty`/`-gnatwa`/`-gnatVa` development set), and the suite runs green
(3/3).

Two feasibility prototypes de-risk the hardest Ada design questions and drive
ADR-014 and ADR-015:

- **`proto_capabilities`** — heterogeneous typed immutable capability storage:
  unrelated value types in one frozen container, type-safe recovery by tag test
  + checked view conversion (no address identity), duplicate-id and
  schema-version rejection. By-value indefinite storage → no access types, no
  unchecked conversion, no manual deallocation.
- **`proto_rule_nodes`** — safe callback storage: predicates captured by generic
  instantiation into immutable class-wide dispatching nodes (no
  access-to-local), engine-derived outcomes, ordered deterministic evaluation.

Deferred within Phase 0 (structurally identical to the capability pattern; will
land with Phase 9): the opaque deferred-payload + typed-interpreter prototype.

Documented Phase 0 decisions: ADR-014 (callback ownership), ADR-015 (capability
storage). See `docs/adr/`. Deliberate deviations from sibling conventions are
recorded in `docs/ai/package_map.md`.

## Phase 1 — complete

The foundational value layer builds clean and the suite is green (13/13,
including the Phase 0 prototypes). Packages delivered:

- `Validation.Identifier_Syntax` / `Validation.Bounded_Identifier` (generic) /
  `Validation.Identifiers` — one ASCII syntax rule; a generic that mints a
  DISTINCT strong id type per category (checked Make + non-raising Try_Make,
  validity, null, equality, total order, hashing, bounded image); ~18 concrete
  id categories.
- `Validation.Versions` — Semantic_Version + independent Schema_Version streams.
- `Validation.Outcomes` (generic) — the one value-or-errors abstraction
  (success never partial, failure never empty).
- `Validation.Values` — neutral immutable value model: Text, signed/unsigned,
  Boolean, Real (finite/NaN/±Inf, signed zero), Decimal (sign/coefficient/
  scale), Count, Identifier, Enumeration, Duration, Instant, Civil_Date, Path,
  Opaque; every value carries a disclosure class; Secret redacts in Image.
- `Validation.Paths` — structured immutable paths (Field/Index/Key/
  Object_Identity/Synthetic), append/parent/prefix/subtree/concatenate/rebase,
  total order + hashing, deterministic redaction-aware dot/bracket render.
- `Validation.Messages` — message id + ordered typed arguments, duplicate names
  rejected; standard message-id and argument-name constants.
- `Validation.Metadata` — bounded ordered duplicate-controlled key/value.
- `Validation.Source_References` — optional neutral source-reference model.
- `Validation.Fingerprints` — deterministic FNV-1a/64 with length-prefixed
  contributions; 16-hex format (non-cryptographic, documented).

Deferred to Phase 2 (where they are actually consumed, alongside Issues and
Results, which they are shaped around): `Validation.Provenance`, the Stopping /
Incompleteness / Statistics descriptors, and the concrete definition/invocation
error records (the generic `Outcomes` carrier already exists to hold them).
