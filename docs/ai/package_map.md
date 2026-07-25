# Package Map

Downward dependency layering. A package may depend only on packages above it in
this list (and the Ada standard library). The core never depends on adapters or
any ecosystem project. Status: `built` / `planned`.

## Foundational (Phase 1)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation` | Root namespace, library version | built |
| `Validation.Identifier_Syntax` | Shared ASCII identifier syntax rule | built |
| `Validation.Bounded_Identifier` (generic) | Mints one distinct strong id type per category | built |
| `Validation.Identifiers` | The concrete strongly typed id categories | built |
| `Validation.Versions` | Semantic + protocol/schema version types | built |
| `Validation.Outcomes` (generic) | Generic value-or-errors outcome | built |
| `Validation.Values` | Immutable neutral value model (Text, integers, Real w/ NaN/Inf, Decimal, Duration, Instant, ...) + disclosure classification | built |
| `Validation.Fingerprints` | Deterministic FNV-1a/64 fingerprint algorithm/format | built |
| `Validation.Paths` | Structured immutable paths (Field/Index/Key/Object_Identity/Synthetic), rebasing, redaction-aware render | built |
| `Validation.Messages` | Stable message ids + ordered typed arguments | built |
| `Validation.Metadata` | Bounded metadata key/value | built |
| `Validation.Source_References` | Neutral source-reference model | built |
| `Validation.Errors` | Definition/invocation error records | built |
| `Validation.Provenance` | Minimal/Standard provenance | built |
| `Validation.Phases` | Canonical execution phases (shared) | built |
| `Validation.Statistics` | Semantic execution counters | built |

## Issues & results (Phase 2)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Issues` | Immutable issue + engine-controlled builder + collection | built |
| `Validation.Results` | Execution_Status × Semantic_Validity, coverage, queries, semantic fingerprints | built |
| `Validation.Projections` | Compact issue + result summary (v1) built; `.By_Path`/`.By_Object_Key`/`.By_Source` + standard/diagnostic projections planned (Phase 10) | partial |

## Contexts & profiles (Phase 3)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Contexts` | Finalized immutable typed-capability container; contracts; trust provenance; fingerprint (overlays/projections deferred) | built |
| `Validation.Profiles` | Profiles, rule groups, inheritance-by-composition, precedence, severity overrides | built |

## Engine, rules, standard validators (Phases 4–6)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Validators` (generic) | Subject-typed engine: rule model (predicate/field/custom), engine-controlled output, builder/finalize, deterministic Validate, fingerprint, introspection. The rule abstraction lives inside this generic (rules are subject-typed) rather than a separate `Validation.Rules` package. | built (minimal) |
| `Validation.Standard.*` | Presence, comparisons, numerics, text, UTF_8, enumerations, temporal, relationships, syntax | planned |

## Collections, recursion, deferred, diagnostics (Phases 7–10)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Collections` (+ `.Adapters`/`.Cardinality`/`.Uniqueness`/`.Ordering`/`.Quantifiers`/`.Aggregates`) | Deterministic collection validation | planned |
| `Validation.Deferred` (+ `.Requests`/`.Results`/`.Continuations`/`.Batching`/`.Synchronous`) | Externally-executed checks, replay, batching | planned |
| `Validation.Introspection` | Immutable structural introspection | planned |
| `Validation.Adapters.*` | Optional external adapters (never core deps) | planned |

## Private engine

`Validation.Internal.*` — definition checks, plan building, execution state,
rule dispatch, path stacks, issue accumulation, result finalization, profile
resolution, prerequisite graphs, recursive/collection traversal, deferred
replay, fingerprint building, diagnostics, capability storage, rule nodes,
deferred payloads. Not exposed.

## Deliberate differences from sibling conventions

- The library GPR does **not** yet enumerate a `Library_Interface` (unlike the
  mature humanize crate). During the phased build every `src/` unit is compiled
  and visible; a curated `Library_Interface` is deferred to Phase 12 release
  hardening to avoid per-phase churn. Documented per spec §1 "document every
  deliberate difference."
- Per-repo tooling: AUnit lives in the `validation_tests` subcrate;
  `project_tools`-driven release/doc/repo checks will live in a separate
  `check_validation` subcrate (sibling convention), reconciling spec §66's
  "test subcrate depends on project_tools" toward the Tables/Navigation/Forms
  layout named in the same section.
