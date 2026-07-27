# Changelog

All notable changes to the Validation library are documented here. Categories:
Added, Changed, Deprecated, Removed, Fixed, Security, Compatibility.

## [Unreleased]

### Added

- **Phase 12 — documentation and release.** A runnable `examples/` subcrate
  (`quickstart.adb`); guides (`docs/QUICKSTART.md`, `docs/ARCHITECTURE.md`,
  `docs/VALIDATOR_CATALOG.md`, `SECURITY.md`, `docs/RELEASE.md`); dedicated ADRs
  for 002/005/007/018 (plus the existing 014/015); `LICENSE`, `CONTRIBUTING.md`,
  an expanded `README.md`; and CI extended to build the example and run the
  dependency-boundary audit.
- **Release guard.** A `check_validation/` subcrate wired to `project_tools`
  verifies the required release surface and dependency boundary (default), builds
  and runs the tests + example (`--release`), and requires clean git worktrees
  (`--release-strict`). Wired into CI.
- **Phase 11 — hardening.** A `hardening_tests` suite: determinism (stable
  fingerprint over repeated runs), path-algebra and result property tests,
  deterministic-LCG fuzz targets for identifier construction and UTF-8
  validation (never raise), condition-fault injection, and ownership. Tooling:
  `tools/check_validation` runs the core dependency-boundary audit and, with
  `--prove`, GNATprove on the SPARK_Mode `Identifier_Syntax` (proved free of
  run-time errors — which caught and fixed a latent `Text'First + 1` overflow).
  Suite green 65/65.

### Fixed

- `Identifier_Syntax.Is_Valid` no longer computes `Text'First + 1` (a latent
  overflow for a pathological lower bound), found by GNATprove.

- **Phase 10 — complete diagnostics.** `Projections.Standard` (standard issue
  projection), `Projections.Canonical_Order` (deterministic issue ordering
  without mutating execution order), `Projections.Distinct_Paths` (sorted
  distinct primary paths for By_Path grouping), and `Results.Issue_Set_Fingerprint`
  / `Results.Same_Issue_Set` (order-independent canonical fingerprint). Suite
  green 58/58.
- **Phase 9 — deferred validation.** `Validation.Deferred` (generic, one check
  family) wraps the engine: `Start` runs the immediate validator, emits typed
  requests, and returns Pending + a continuation binding the validator/context
  fingerprints and a subject token; `Resume` rejects stale/unknown/duplicate
  results and interprets supplied results by deterministic replay (arrival order
  independent, Require_All); a `Synchronous` adapter runs the whole lifecycle
  in-process. Suite green 54/54.
- **Phase 8 — recursive objects, nesting, transitions.** Issue rebasing —
  `Issues.Rebased` + the engine hook `Validators.Add_Rebased_Issue`.
  `Validation.Nested` (generic) embeds a sub-validator's issues under a nested
  field path, with an `Optional` child for §36 presence semantics.
  `Validation.Recursive` (generic) validates recursive structures with
  active-path cycle detection (caller-supplied stable identity, never a pointer),
  cycle actions (report/skip/fail), and depth/visit limits that yield controlled
  incompleteness. Suite green 49/49.
- **Phase 7 — collections.** `Validation.Collections` (generic, adapter-driven):
  cardinality (min/max/exact count), per-element predicate (issue per failing
  element at `field[i]`), uniqueness (typed key projection, one issue per
  duplicate with a related path to the first occurrence), quantifiers
  (at-least/at-most/exactly), and a sum aggregate — all through
  `Parameterized_Rules`. A supporting engine addition,
  `Validators.Add_Issue_With_Related` (+ `Path_Array`), attaches related paths.
  Hashed containers must supply a canonical `Item` order (VAL-INV-021). Suite
  green 45/45.
- **Phase 6 — composition, conditions, prerequisites, profiles.**
  `Validation.Validators` gains: profile selection in `Validate` (an
  `Execution_Options.Profiles` set filters rules by group and overrides
  severities, later-profile-wins); prerequisites (`Requires` runs a rule only
  when an earlier local rule passed, via per-rule outcome tracking); conditions
  (the `Conditional` generic wraps a rule as When_/Unless_Applicable);
  decorators `In_Group` / `Requires`; and composition `Extend` / `Disable`.
  `Any_Of`/`Case` deferred. Suite green 40/40.
- **Phase 5 — standard scalar validators.** A new
  `Validators.Parameterized_Rules` (runtime bounds stored immutably in the node)
  enables standard validators built through the public rule abstractions.
  `Validation.Standard` (actual-value disclosure policy, exclude-by-default),
  `Validation.Standard.UTF_8` (audited Is_Valid + Scalar_Count),
  `Validation.Standard.Text` (min/max/exact length, non-empty, non-blank,
  valid-UTF8), and `Validation.Standard.Numerics` (minimum, maximum, in-range,
  positive, non-negative, non-zero). Standard messages carry the configured
  bound, never the actual value. Suite green 35/35.
- **Phase 4 — minimal typed validator engine.** `Validation.Validators`
  (generic over the subject type): an engine-controlled `Rule_Output` (rules
  emit only through Add_Issue/Add_Issue_At_Field; the engine supplies validator/
  rule/ordinal/provenance); predicate, field-accessor, and custom rule
  constructors captured by generic instantiation into immutable class-wide
  nodes; builder + finalize (rejecting duplicate rule id and empty validator
  id); deterministic Validate by (phase, declaration) order with Accumulate_All
  and Stop_On_First_Error; callback-fault conversion at the callback boundary; a
  validator fingerprint; and introspection. An application record validates end
  to end through the public API. Suite green 31/31.
- **Phase 3 — contexts and profiles.** `Validation.Contexts` — the real typed-
  capability container (promoting the Phase 0 prototype): trust provenance,
  schema/ownership/sensitivity/continuation metadata, trust-aware retrieval
  (untrusted values cannot satisfy trusted requests, VAL-INV-036), duplicate/
  version rejection, insertion-order-independent fingerprint, context token, and
  contract checking. `Validation.Profiles` — group activation, severity
  overrides, inheritance by composition (cycles impossible by construction),
  Conflicting_Override detection at Finalize, and a Profile_Set with
  later-profile-wins precedence and union group activation. Suite green 24/24.
- **Phase 2 — issues, results, projections.** `Validation.Phases`,
  `Validation.Provenance` (Minimal/Standard), `Validation.Statistics`,
  `Validation.Errors` (definition/invocation domains with stable dotted keys),
  `Validation.Issues` (immutable issue, engine-controlled builder, deterministic
  Issue_Identity, duplicate-controlled related paths, standard categories,
  bounded collection), `Validation.Results` (Execution_Status ×
  Semantic_Validity with validity DERIVED from status+issues, coverage, stop/
  incompleteness descriptors, the §57 query surface, semantic fingerprint), and
  `Validation.Projections` (compact issue + result summary v1). Suite green
  19/19.
- **Phase 1 — foundational value layer.** `Validation.Identifiers` (distinct
  strong id types via a generic bounded-identifier kind + shared ASCII syntax),
  `Validation.Versions` (semantic + independent schema-version streams),
  `Validation.Outcomes` (generic value-or-errors), `Validation.Values` (neutral
  immutable value model with disclosure classification and Real NaN/Inf
  handling), `Validation.Paths` (structured immutable paths with total order,
  hashing, and redaction-aware rendering), `Validation.Messages` (message ids +
  ordered typed arguments, duplicate names rejected, standard constants),
  `Validation.Metadata`, `Validation.Source_References`, and
  `Validation.Fingerprints` (FNV-1a/64, length-prefixed, 16-hex). Suite green
  13/13.
- **Phase 0 — repository & feasibility prototypes.** Alire leaf-library crate
  (`validation`) plus AUnit test subcrate (`validation_tests`); both build under
  the strict switch set and the suite runs green.
- Feasibility prototypes proving the two riskiest designs: heterogeneous typed
  immutable capability storage (`proto_capabilities`) and safe callback storage
  via generic instantiation into immutable class-wide nodes (`proto_rule_nodes`).
- Documentation skeleton: invariant registry (VAL-INV-001..040), package map,
  allowed-dependencies and prohibited-patterns guides, ADR index with ADR-014
  (callback ownership) and ADR-015 (capability storage) accepted, phase tracker.

### Compatibility

- No public protocol/schema versions are frozen yet. Continuation compatibility
  is not promised until the deferred subsystem (Phase 9) lands.
