# ADR-007 — Deferred request/result protocol (with deterministic replay)

**Status:** accepted (core; see ADR-008)

## Context

Some checks need external work (uniqueness/existence against a database, a remote
service). The core is headless and must never perform I/O, yet must integrate
such checks deterministically and safely.

## Decision

`Validation.Deferred` *describes* external work but never executes it. `Start`
runs the immediate validator and emits typed requests plus a `Continuation`
binding the validator fingerprint, a caller subject token, and the context
fingerprint (VAL-INV-030). The application executes requests and supplies typed
results. `Resume` rejects a stale/incompatible continuation and unknown/duplicate
results (VAL-INV-012), then interprets results by **deterministic replay** of the
immediate validator (ADR-008). Result arrival order never affects the outcome
(VAL-INV-011). A synchronous adapter runs the whole loop in-process.

## Alternatives

- *Execute checks inline via a context service handle* — rejected: violates the
  headless boundary and hides I/O in the engine.

## Consequences

Deferred validation is safe, replayable, and stale-rejecting. The V1 core covers
one in-process, Require_All check family; heterogeneous opaque payloads,
batching, multi-round, and externally-serializable continuations are documented
generalizations.
