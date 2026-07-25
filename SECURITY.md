# Security

## Threat model

Validation processes **untrusted subject data**. It is designed to stay bounded
and deterministic against adversarial input:

- **Huge collections / deep nesting / cycles** — every traversal is bounded
  (collection element, path segment, nesting depth, recursion visit, deferred
  request, and continuation-round limits). Recursive structures use active-path
  cycle detection keyed on a caller-supplied stable identity (never a pointer),
  with configurable cycle actions. Limit exhaustion is *controlled
  incompleteness*, never an infinite loop.
- **Invalid UTF-8 / adversarial keys** — a single audited UTF-8 decoder; keys
  and identities carry per-segment disclosure policy.
- **Malicious or buggy callbacks** — callback faults are caught only at the
  documented callback boundary and converted to an invocation error under the
  `Convert_To_Invocation_Error` fault mode; they are never reported as subject
  invalidity.
- **Stale / forged deferred continuations** — a continuation binds the validator
  fingerprint, subject token, and context fingerprint; a mismatch is rejected as
  an invocation error. Unknown and duplicate deferred results are rejected, never
  silently accepted.
- **Cross-tenant / trust confusion** — context capabilities carry trust
  provenance; a `Proposed_Untrusted_Value` cannot satisfy a request that accepts
  only trusted provenance, even when the Ada value type and id text match.

## Objectives

Bounded execution; strict continuation compatibility; no pointer-derived
identity; no hidden external I/O; no global mutable registries; disclosure-aware
paths/arguments/metadata; controlled issue construction; no silent acceptance of
malformed results. The dependency-boundary audit (`tools/check_dependencies.sh`)
enforces the headless boundary.

## Non-objectives

Validation is **not** a security mechanism. It does not authenticate, authorize,
encrypt, sign, store secrets, or provide transport integrity. **Semantic
fingerprints are compatibility identifiers, not security tokens.** External
continuations that cross a trust boundary require application-provided
integrity, authenticity, confidentiality, replay protection, and expiry.

## Secrets

Secrets (passwords, tokens, verifier material) must never be placed in
`Validation.Values`, issue arguments, metadata, paths, provenance, fingerprints,
traces, or deferred payloads. Values carry a disclosure classification and
`Secret` values are redacted by default in rendering and projections.

## Reporting

This is a component of a larger stack under active development. Report security
concerns to the maintainer listed in `alire.toml`.
