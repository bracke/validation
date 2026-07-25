# ADR-002 — Structured issues rather than exceptions

**Status:** accepted

## Context

Ordinary validation failure (a subject violating a rule) is a normal, expected
outcome, often producing many failures at once. Exceptions are unsuited: they
unwind, carry no structured multi-issue payload, and conflate programming errors
with domain outcomes.

## Decision

Ordinary failure is a structured, immutable `Validation.Issues.Issue` collected
into a `Validation.Results.Result` (VAL-INV-005). Exceptions are reserved for
programming errors. Distinct error domains stay separate (VAL-INV-025):
*definition errors* (malformed validator) via `Validation.Outcomes` at
finalization; *invocation errors* (missing capability, stale continuation,
callback fault) in the result's invocation-error list — never in the ordinary
issue collection.

## Consequences

All failures at once, with stable message ids, structured paths, and typed
arguments. Callback faults are caught only at the documented boundary and
converted to an invocation error (never subject invalidity). Semantic validity
is derived from status + issues so the two result dimensions cannot disagree.
