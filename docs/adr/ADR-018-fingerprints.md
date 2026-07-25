# ADR-018 — Fingerprint algorithm and format

**Status:** accepted

## Context

Validators, contexts, profiles, results, and issue identities need cheap,
deterministic, semantic-compatibility fingerprints — for stale-continuation
rejection, issue-identity computation, and result comparison. A callback's code
body cannot be portably hashed.

## Decision

`Validation.Fingerprints` uses **FNV-1a over a 64-bit accumulator**, with every
contribution **length-prefixed** so `(a, bc)` and `(ab, c)` cannot collide, and
`Add_Tag` discriminators so structurally similar sequences with different meaning
do not collide. Format: 16 lowercase hex digits. Only *semantic* content is
contributed — never addresses, callback pointers, elaboration/allocation order,
or non-semantic text. Because code bodies are unhashable, every executable rule
carries a stable `Implementation_Version_Id`.

## Consequences

Deterministic and reproducible; **not cryptographic** and carries no security
guarantee (VAL-INV: fingerprints are not signatures). Two fingerprint uses are
distinguished on results: `Semantic_Fingerprint` (execution order) and
`Issue_Set_Fingerprint` (order-independent, sorts issue identities).
