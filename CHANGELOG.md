# Changelog

All notable changes to the Validation library are documented here. Categories:
Added, Changed, Deprecated, Removed, Fixed, Security, Compatibility.

## [Unreleased]

### Added

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
