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
| `Validation.Errors` | Definition/invocation error records | planned (Phase 2) |
| `Validation.Provenance` | Minimal/Standard provenance | planned (Phase 2) |

## Issues & results (Phase 2)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Issues` | Immutable issue + engine-controlled builder | planned |
| `Validation.Results` | Execution_Status × Semantic_Validity, scope/coverage, queries, semantic fingerprints | planned |
| `Validation.Projections` (`.By_Path`/`.By_Object_Key`/`.By_Source`) | Versioned neutral projections | planned |

## Contexts & profiles (Phase 3)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Contexts` (+ `.Capabilities`/`.Builders`/`.Overlays`/`.Projections`) | Finalized immutable typed-capability container; contracts; trust provenance | planned (storage **prototyped**) |
| `Validation.Profiles` | Profiles, rule groups, inheritance, precedence, severity overrides | planned |

## Engine, rules, standard validators (Phases 4–6)

| Package | Responsibility | Status |
|---------|----------------|--------|
| `Validation.Rules` | Rule abstraction + engine-controlled output interface | planned (node storage **prototyped**) |
| `Validation.Validators` (+ `.Builders`/`.Fields`/`.Nested`/`.Objects`) | Subject-typed validators; finalization; composition | planned |
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
