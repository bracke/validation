# Architecture

## What Validation is

A headless, deterministic, strongly typed validation engine. Given a typed
subject, a finalized immutable validator, an immutable context, active profiles,
and execution options, it answers: what structured issues were found, what work
remains unresolved, and was execution complete? Nothing else — see
[`ai/prohibited_patterns.md`](ai/prohibited_patterns.md).

## Layers (downward dependency)

1. **Foundational values** — `Identifiers`, `Versions`, `Outcomes`, `Values`,
   `Paths`, `Messages`, `Metadata`, `Source_References`, `Fingerprints`.
   Immutable, deterministic, no engine knowledge.
2. **Diagnostics** — `Provenance`, `Statistics`, `Errors`, `Issues`, `Results`,
   `Projections`. The issue/result model and neutral projections.
3. **Context & profiles** — `Contexts` (typed capability container with trust
   provenance), `Profiles` (groups + severity overrides).
4. **Engine** — `Validators` (generic over the subject type): the rule model,
   engine-controlled output, builder/finalize, deterministic `Validate`,
   conditions/prerequisites/groups, composition, fingerprint.
5. **Standard validators & structure** — `Standard.*` (text, numerics, UTF-8),
   `Collections`, `Nested`, `Recursive`, `Deferred`.

Full map and per-package status: [`ai/package_map.md`](ai/package_map.md).

## Key design decisions

- **Immutable definitions, structured results.** Builders finalize into
  immutable validators/contexts/profiles. Ordinary failure is a structured
  `Issue`, never an exception (ADR-002). Definition and invocation errors are a
  separate domain (`Validation.Errors`), never mixed into the issue collection.

- **Two result dimensions.** `Execution_Status` (Completed / Pending / Stopped /
  Incomplete / Invocation_Failed / Cancelled) × `Semantic_Validity` (Valid /
  Valid_With_Nonerrors / Invalid / Undetermined). Validity is *derived* from the
  status and issues, so the two can never disagree.

- **Structured paths.** A `Path` is a typed segment sequence (Field / Index /
  Key / Object_Identity / Synthetic), not a string; rendering is a separate,
  deterministic, redaction-aware projection (ADR-005). No identity ever derives
  from a memory address.

- **Rules captured by instantiation (ADR-014).** A rule's callback is captured
  by a generic instantiation into an immutable class-wide node — never stored as
  an access-to-local-subprogram. The engine-controlled `Rule_Output` supplies
  the validator id, rule id, ordinal, and provenance; a rule supplies only the
  semantic fields. Rules never construct issues directly and never mutate the
  subject.

- **Typed capability context (ADR-006/015).** Capabilities are stored by value
  in a private class-wide holder and recovered by tag test + checked view
  conversion — no exposed type erasure, no address identity. Retrieval is
  trust-aware: a `Proposed_Untrusted_Value` cannot satisfy a request that
  accepts only trusted provenance.

- **Deterministic execution (ADR-004).** Rules run in (phase ordinal,
  declaration ordinal) order; issue order and issue identities are deterministic
  for identical inputs. Hashed containers must impose a canonical order.

## Deferred validation (ADR-007/008)

`Validation.Deferred` describes external work but never executes it. `Start`
runs immediate rules and emits requests + a continuation binding the validator
fingerprint, subject token, and context fingerprint. The application executes
requests and supplies results; `Resume` rejects a stale/unknown/duplicate result
and interprets results by *deterministic replay*. Arrival order never changes
the outcome.

## Identity / Authorization boundary

Validation checks the structural and semantic validity of typed values only. It
never authenticates, verifies credentials, authorizes, derives scopes, or
satisfies obligations. Trust provenance on context capabilities keeps untrusted
proposed values from satisfying trusted requirements. See the VAL-INV-031..040
invariants in [`ai/invariants.md`](ai/invariants.md).
