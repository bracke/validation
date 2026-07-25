# Phase Status

The library is built in vertical slices (spec §83). Each phase delivers a
compilable API, implementation, tests, docs, invariant updates, a dependency
check, and an example/fixture.

| Phase | Title | Status |
|-------|-------|--------|
| 0 | Repository & feasibility prototypes | **complete** |
| 1 | Foundational value layer | **complete** |
| 2 | Issues, results, and projections | **complete** |
| 3 | Contexts, profiles, structural metadata | **complete** |
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

## Phase 2 — complete

Issues, results, and the neutral projections build clean; suite green (19/19).
Tests build and compare complete deterministic outputs before any engine exists
(the phase completion criterion). Packages delivered:

- `Validation.Phases` — the canonical execution phases (shared).
- `Validation.Provenance` — Minimal + Standard provenance (validator/rule/
  ordinal, plus root/nested-chain/phase/declaration-ordinal/profiles).
- `Validation.Statistics` — deterministic semantic execution counters.
- `Validation.Errors` — definition/invocation error records with a stable
  dotted key (e.g. `invocation.missing_capability`), strictly distinct from
  ordinary issues (VAL-INV-025).
- `Validation.Issues` — immutable issue with exactly one primary path
  (VAL-INV-006), originating validator+rule (VAL-INV-007), an engine-controlled
  builder (rules never construct issues directly), deterministic Issue_Identity
  (FNV-1a over stable content + issue-id format version, §12), duplicate-
  controlled bounded related paths, standard category constants, and a bounded
  ordered issue collection with severity counts.
- `Validation.Results` — Execution_Status × Semantic_Validity (validity DERIVED
  from status + issues so the dimensions can't disagree), coverage, stop and
  incompleteness descriptors, statistics, fingerprints; the §57 query surface
  (counts, severity, path/rule/validator/category filters, invocation-error and
  incompleteness accessors) and a deterministic semantic fingerprint.
- `Validation.Projections` — compact issue projection + result summary (v1),
  the deterministic outputs external serializers consume. Standard/diagnostic
  projections and By_Path/By_Object_Key/By_Source groupings land in Phase 10.

## Phase 3 — complete

Contexts and profiles build clean; suite green (24/24). Both resolve
deterministically and are independently testable (the phase criterion).

- `Validation.Contexts` — promotes the Phase 0 storage prototype (ADR-015) to
  the real typed-capability container. Each capability carries capability id,
  schema id + version, TRUST PROVENANCE, sensitivity, ownership, fingerprint-
  contribution policy, and continuation-safety. Retrieval is trust-aware: a
  `Proposed_Untrusted_Value` cannot satisfy a `Trusted_Facts` request even when
  the Ada type and id text match (VAL-INV-036, tested). Duplicate-id and
  schema-version rejection; an insertion-order-independent deterministic
  fingerprint (VAL-INV-021); context token; and a context-contract check that
  reports missing / version-mismatch / trust-mismatch as invocation errors.
- `Validation.Profiles` — profiles activate rule groups and override rule
  severities; never reorder rules (VAL-INV-010). Inheritance is by COMPOSITION
  (Extend from a finalized parent), which makes inheritance cycles impossible by
  construction (a documented simplification of §34's id-based-inheritance model;
  the retained definition error is Conflicting_Override, detected at Finalize).
  A Profile_Set resolves severity by "later profile wins" precedence and group
  activation by union; profile fingerprints are deterministic.

Deferred to later phases: context overlays (§33) and context projections; the
standard capability patterns (clock/locale/tenant/...) are application-defined
instances, not core packages, per §33.
