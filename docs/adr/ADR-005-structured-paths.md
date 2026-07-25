# ADR-005 — Structured validation paths

**Status:** accepted

## Context

An issue must say *where* in the typed subject a problem is, in a way that
adapters (Forms, Tables, APIs) can map without parsing text, and that never
leaks memory addresses or sensitive key values.

## Decision

A `Validation.Paths.Path` is an immutable sequence of typed segments — Field,
Index (with an explicit index convention), Key, Object_Identity, Synthetic —
plus an absolute/relative flag. It supports append/parent/prefix/subtree/
concatenate/rebase, a deterministic total order, and hashing. Rendering (dot/
bracket) is a *separate*, deterministic, redaction-aware projection; Key and
Object_Identity segments carry a per-segment disclosure policy (Include / Redact
/ Opaque_Hash / Omit_Value). No identity derives from an address (VAL-INV-015).

## Consequences

Adapters consume the structured segments; sensitive keys redact at render time
without losing the structured location. Path rebasing (`Issues.Rebased`) is what
lets nested/recursive sub-validator issues embed under a parent path.
