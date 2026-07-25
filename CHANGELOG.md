# Changelog

All notable changes to the Validation library are documented here. Categories:
Added, Changed, Deprecated, Removed, Fixed, Security, Compatibility.

## [Unreleased]

### Added

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
