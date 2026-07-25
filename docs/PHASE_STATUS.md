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
| 4 | Minimal typed validator engine | **complete** |
| 5 | Standard scalar validators | **complete** |
| 6 | Composition, conditions, prerequisites, profiles | **complete** |
| 7 | Collections | **complete** |
| 8 | Recursive objects, patch, transitions | **complete** |
| 9 | Deferred validation | **complete** |
| 10 | Complete diagnostics | **complete** |
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

## Phase 4 — complete

The minimal typed validator engine builds clean; suite green (31/31). An
application-defined record (Customer) validates end to end through the public
API (the phase criterion).

`Validation.Validators` (generic over Subject_Type) provides:

- An engine-controlled `Rule_Output`: rules emit issues only through
  `Add_Issue` / `Add_Issue_At_Field`; the engine supplies validator id, rule id,
  ordinal, and provenance (VAL-INV-007, VAL-INV-026). Rules never construct
  issues directly and never mutate the subject (VAL-INV-013). The per-invocation
  state lives by value in the limited output object (no global state, no address
  identity).
- Three rule constructors, each capturing its callback by generic instantiation
  into an immutable class-wide node (ADR-014): `Predicate_Rules` (whole-subject),
  `Field_Rules` (field accessor + predicate), and `Custom_Rules` (emits through
  Rule_Output).
- `Start` / `Add` / `Finalize`: finalization rejects a duplicate rule id and an
  empty validator id as definition errors.
- `Validate`: deterministic execution order by (phase ordinal, declaration
  ordinal) (VAL-INV-008/009); Accumulate_All and Stop_On_First_Error; callback
  faults optionally converted to an invocation error at the callback boundary
  only (§29); a validator fingerprint; and Result assembly with derived
  validity.
- Introspection: id, rule count, fingerprint.

The rule model was built inside the Validators generic (rather than a separate
`Validation.Rules` package) because rules are subject-typed and tightly coupled
to the engine; documented in docs/ai/package_map.md.

## Phase 5 — standard scalar validators

Builds clean; suite green (35/35). Standard validators are implemented THROUGH
the public rule abstractions, enabled by a new `Validators.Parameterized_Rules`
(a rule whose runtime bounds are stored immutably in the node; the check is a
library-level subprogram — no access-to-subprogram closure).

- `Validation.Standard` — the actual-value disclosure policy (Exclude_Actual by
  default, §42): standard messages carry the configured BOUND, never the actual
  field value (VAL-INV-035).
- `Validation.Standard.UTF_8` — the one audited decoder: Is_Valid (rejects
  overlong, surrogate, out-of-range, truncated, stray-continuation) + a
  code-point Scalar_Count.
- `Validation.Standard.Text` (generic over a String accessor) — Min/Max/Exact
  length, Non_Empty, Non_Blank, Valid_UTF8.
- `Validation.Standard.Numerics` (generic over a signed-integer accessor) —
  Minimum, Maximum, In_Range, Positive_Value, Non_Negative, Non_Zero.

No validator trims, normalizes, or repairs the subject (VAL-INV-014). Deferred
(extensible via the same mechanism): comparisons across fields, enumerations/
membership, temporal (needs the clock capability), relationships, and more
syntax validators (Ada identifier, hex, UUID).

## Phase 6 — composition, conditions, prerequisites, profiles

Builds clean; suite green (40/40). Profiles are now wired into the engine and
rules gain conditions, prerequisites, groups, and composition — all as additions
to `Validation.Validators`.

- **Profile selection**: `Execution_Options` carries a `Profile_Set`. Empty set
  => no filtering (all rules run). Non-empty => a rule runs iff its group is the
  default (unlabeled) or is active in the set. Emitted issues have their severity
  overridden per the set (later profile wins), which also affects
  Stop_On_First_Error. Profiles never reorder rules (VAL-INV-010).
- **Prerequisites** (§26 subset): `Requires (rule, other)` runs a rule only if an
  earlier local rule ran and passed. The engine tracks per-rule outcomes
  (passed/failed/skipped) in execution order — the canonical guard that stops a
  length rule cascading after the required-presence rule already failed.
- **Conditions** (§25): the `Conditional` generic wraps a rule so it applies only
  When_Applicable / Unless_Applicable a pure condition holds. The wrapper copies
  the inner rule's config (so id/phase/group/attribution are preserved) and
  dispatches to the inner node when applicable.
- **Decorators**: `In_Group`, `Requires` — return a new rule with modified config
  (the node is copied and its config tweaked; originals are unchanged).
- **Composition** (§43): `Extend` starts a builder from a finalized validator's
  rules; `Disable` removes rules by id. Component validators are never mutated.

Deferred: `Any_Of` (§44) and `Case` selection — larger branch-evaluation
semantics that belong with a follow-on; noted for a later increment.

## Phase 7 — collections

Builds clean; suite green (45/45). A first engine addition —
`Validators.Add_Issue_With_Related` (+ `Path_Array`) — lets rules attach related
paths (used by uniqueness for the first-occurrence link).

`Validation.Collections` (generic over subject + Validators instance +
collection/element types + `Get`/`Count`/`Item` adapter formals) provides, all
through `Parameterized_Rules`:

- **Cardinality** — Min_Count, Max_Count, Exact_Count.
- **Per-element predicate** (`Each_Element`) — one issue per failing element at
  its zero-based path `field[i]`.
- **Uniqueness** (`Unique`, typed key projection) — one issue per duplicate after
  the first, at the duplicate's path with a related path to the first occurrence.
- **Quantifiers** (`Quantifier`) — At_Least / At_Most / Exactly over an element
  predicate.
- **Aggregate** (`Aggregate`) — Sum_At_Most / Sum_Equals over an integer
  projection.

The adapter is the `Count`+`Item` random-access pair; arrays, vectors, lists,
and ordered/hashed maps and sets are supported by supplying an `Item` accessor
that yields a canonical, deterministic order (hashed containers must not use
bucket order, VAL-INV-021). Tested against an `Ada.Containers.Vectors` adapter.

Deferred: ordering validators, map key/value validation, and full nested-record
element validation (needs the Phase 8 rebasing machinery); collection limits are
carried by the incompleteness model but not yet enforced per-element.

## Phase 8 — recursive objects, nesting, transitions

Builds clean; suite green (49/49). The enabler is issue REBASING —
`Issues.Rebased` (a copy under an absolute prefix with a fresh ordinal) and the
engine hook `Validators.Add_Rebased_Issue`.

- `Validation.Nested` (generic) — runs a sub-validator on a nested record field
  and embeds its issues rebased under the field path (e.g. `$.address.postcode`),
  preserving the nested validator/rule identity. The `Optional` child handles
  §36 presence: absent optional skips the nested validator; absent required
  emits one presence issue.
- `Validation.Recursive` (generic) — validates a recursive structure with
  active-path CYCLE DETECTION keyed on a caller-supplied stable Identity (never a
  pointer, VAL-INV-015). Cycle actions: Report_Issue_And_Skip (a graph.cycle
  issue with a related path to the first occurrence), Skip_Silently,
  Invocation_Failure. Depth and visit limits produce controlled incompleteness
  (VAL-INV-016), never an infinite loop. Node issues are rebased under
  `children[i].children[j]...`.

Object final rules need nothing new — declare a Custom rule with Phase_Final.
Transitions are modelled as an ordinary subject with old/new fields; no
dedicated package. Deferred: change-set-driven selection and a packaged
optional-state adapter (the Optional child covers present/absent).

## Phase 9 — deferred validation

Builds clean; suite green (54/54). `Validation.Deferred` (generic over a
single deferred check family) WRAPS the engine rather than rewiring it:

- `Start` runs the immediate validator, emits one typed request per subject item
  (each targeting a path), and returns a Pending result plus a `Continuation`
  binding the validator fingerprint, a caller subject token, and the context
  fingerprint (§50).
- `Resume` rejects a stale/incompatible continuation as `Stale_Continuation`
  (VAL-INV-030); rejects unknown and duplicate results (VAL-INV-012); then does
  a DETERMINISTIC REPLAY of the immediate validator and interprets each result
  into an issue at the request's path. Result arrival order never affects the
  outcome (VAL-INV-011); a missing result leaves it Pending (Require_All).
- `Synchronous` (§55) runs the whole lifecycle in-process through a caller
  handler — validate → execute every request → resume.

The core deliberately covers one check family with an in-process, Require_All
lifecycle. Documented generalizations (not built): the heterogeneous multi-check
opaque-payload model (§47), batching/splitting (§53), multi-round follow-ups
(§54), deduplication, and externally-serializable continuations (§48).

## Phase 10 — complete diagnostics

Builds clean; suite green (58/58). Extends `Validation.Projections` and
`Validation.Results`:

- `Projections.Standard` — the standard issue projection (compact fields plus
  category, validator/rule ids, and related/argument/metadata counts and
  provenance mode).
- `Projections.Canonical_Order` — a deterministic issue order (by path, then
  severity, then rule, then message, then ordinal) that does not mutate
  execution order (§56/§57).
- `Projections.Distinct_Paths` — the distinct rendered primary paths in sorted
  order; combine with `Results.Issues_At_Exact_Path` for By_Path grouping.
- `Results.Issue_Set_Fingerprint` + `Results.Same_Issue_Set` — an
  order-INDEPENDENT canonical fingerprint (sorts issue identities), distinct from
  the execution-order `Semantic_Fingerprint`.

Deferred: the diagnostic projection with an execution TRACE (the trace itself is
not built — it is non-semantic, §14/§58), the By_Object_Key / By_Source
groupings, related-path mirroring, and in-projection redaction policy knobs
(paths already render redaction-aware).
