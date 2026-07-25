# Prohibited Patterns

Never do any of these in the Validation core. Each maps to one or more
`VAL-INV-*` invariants (see `invariants.md`).

- **String-only paths.** Paths are structured immutable values; strings are a
  rendering only. (INV-006)
- **Localized text from rules.** Rules return message ids + typed arguments; an
  external renderer localizes. (INV-023, INV-024)
- **SQL / HTTP / file / network inside callbacks.** No I/O anywhere in the core.
  (INV-019)
- **Global mutable registries** of validators, capabilities, executors,
  messages, serializers, or adapters. (INV-020)
- **Missing capability treated as a subject issue.** It is an invocation error.
  (INV-017)
- **Hash-container iteration order as semantic order.** Impose canonical order.
  (INV-021)
- **Temporary callback capture** / storing access-to-local-subprogram with
  unsafe accessibility, or retaining builder-local temporaries. Capture
  predicates by instantiation into immutable class-wide nodes. (INV-027,
  INV-028)
- **Hidden system clock.** Time comes from an explicit clock capability or an
  explicit comparison value. (INV-022)
- **Silent truncation.** Limit exhaustion is explicit controlled incompleteness.
  (INV-016)
- **Secret disclosure.** No passwords/tokens/verifier material in
  values/args/paths/provenance/fingerprints/traces/snapshots/deferred summaries.
  (INV-035)
- **Pointer-derived identity.** No externally observable identity from an
  address. (INV-015)
- **Arbitrary unversioned opaque payloads.** Opaque values/payloads carry a
  semantic type id + schema version. (INV-029)
- **Exception-based ordinary validation failure.** Ordinary failure is a
  structured issue. (INV-005)
- **Passwords or verifier material in `Validation.Values`.** Secrets are
  inspected only through bounded secret-view contracts. (INV-035)
- **Detailed credential rejection through Validation issues.** (INV-034)
- **Authorization decisions represented as Validation validity.** Deny is not an
  Error; Not_Applicable/Indeterminate are not Validation statuses. (INV-033)
- **Authorization obligations represented as ordinary Validation issues.**
  (INV-039)
- **Untrusted proposed values satisfying trusted capability contracts.**
  (INV-036)
- **Authorization-derived descriptive capabilities treated as enforcement.**
  (INV-032)
- **Deferred Validation used for authorization / scope derivation.** (INV-040)
- **Implicit conversion of Identity/Authorization identifiers to generic
  Validation identifiers.** Explicit checked adapters only. (INV-037)
