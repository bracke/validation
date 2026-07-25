# Invariant Registry (VAL-INV-*)

Authoritative list of the non-negotiable invariants of the Validation library.
Each is enforced at a documented point, owned by a package, and (once the
owning package exists) covered by tests. Status legend:

- **proven** — implemented and covered by a passing test.
- **prototyped** — feasibility proven in a Phase 0 prototype; owning public
  package not yet built.
- **planned** — not yet implemented; owning package listed is the intended home.

| ID | Invariant | Owner (planned) | Status |
|----|-----------|-----------------|--------|
| VAL-INV-001 | Finalized validators are immutable | Validation.Validators | planned |
| VAL-INV-002 | Finalized contexts are immutable | Validation.Contexts | prototyped |
| VAL-INV-003 | Finalized profiles are immutable | Validation.Profiles | planned |
| VAL-INV-004 | Issues and results are immutable | Validation.Issues/Results | planned |
| VAL-INV-005 | Ordinary validation failure never uses exceptions | Validation.Results | planned |
| VAL-INV-006 | Every issue has exactly one valid primary path | Validation.Issues | planned |
| VAL-INV-007 | Every issue identifies its originating validator and rule | Validation.Issues | planned |
| VAL-INV-008 | Execution order is deterministic for identical inputs | Validation.Internal.* | planned |
| VAL-INV-009 | Issue order is deterministic for identical inputs | Validation.Internal.Issue_Accumulation | planned |
| VAL-INV-010 | Profiles suppress/configure but never reorder surviving rules | Validation.Profiles | planned |
| VAL-INV-011 | Deferred result arrival order does not affect output | Validation.Deferred | planned |
| VAL-INV-012 | Unknown/duplicate/stale/incompatible deferred results never silently accepted | Validation.Deferred | planned |
| VAL-INV-013 | Validation never mutates the subject | Validation.Validators | planned |
| VAL-INV-014 | Validation never silently normalizes/repairs/trims/canonicalizes/defaults | Validation.Standard | planned |
| VAL-INV-015 | No externally observable identity from an access value or memory address | Validation.Paths/Contexts | prototyped |
| VAL-INV-016 | Limit exhaustion is explicit controlled incompleteness | Validation.Results | planned |
| VAL-INV-017 | Missing required context capabilities are invocation errors, not issues | Validation.Contexts | planned |
| VAL-INV-018 | Infrastructure failure is not ordinary invalidity unless a rule policy maps it | Validation.Deferred | planned |
| VAL-INV-019 | No HTTP/DB/file/network/scheduler/queue/UI operations | (whole core) | proven* |
| VAL-INV-020 | No global mutable registries of any kind | (whole core) | proven* |
| VAL-INV-021 | Hash-container iteration order never determines semantic output order | Validation.Collections | planned |
| VAL-INV-022 | Time-sensitive rules never read the system clock implicitly | Validation.Standard.Temporal | planned |
| VAL-INV-023 | Localized text is never produced by the core | Validation.Messages | planned |
| VAL-INV-024 | Message ids + typed arguments preserved until an external renderer resolves them | Validation.Messages | planned |
| VAL-INV-025 | Definition / invocation / incompleteness / stop / pending / ordinary-issue stay distinct | Validation.Results/Errors | planned |
| VAL-INV-026 | Rule outcomes derived by the engine from controlled output + state | Validation.Rules | prototyped |
| VAL-INV-027 | A rule callback cannot spoof another rule's validator/rule identity or provenance | Validation.Internal.Rule_Dispatch | planned |
| VAL-INV-028 | Finalized validators do not retain builder-local temporaries | Validation.Validators | prototyped |
| VAL-INV-029 | Deferred request payloads obey explicit ownership rules beyond the call | Validation.Deferred | planned |
| VAL-INV-030 | Continuation compatibility binds fingerprint/subject/context/profiles/options/schema/request ids | Validation.Deferred | planned |
| VAL-INV-031 | Never verifies credentials, authenticates, throttles, issues sessions, or mutates Identity | (whole core) | proven* |
| VAL-INV-032 | Never evaluates authorization, grants access, derives scopes, satisfies obligations | (whole core) | proven* |
| VAL-INV-033 | Authz Deny/Not_Applicable/Indeterminate never represented as Validation issues/validity | Validation.Results | planned |
| VAL-INV-034 | Identity auth failures never decomposed into disclosure-unsafe diagnostics | Validation.Adapters | planned |
| VAL-INV-035 | Secret credential material never enters values/args/paths/provenance/fingerprints/traces/deferred | Validation.Values | planned |
| VAL-INV-036 | Fact trust provenance preserved; untrusted proposed values cannot satisfy trusted requirements | Validation.Contexts | planned |
| VAL-INV-037 | Identity/Authorization identifiers stay distinct; explicit checked adapters only | Validation.Identifiers | planned |
| VAL-INV-038 | Identity/Authz-dependent continuations bind the relevant revisions | Validation.Deferred | planned |
| VAL-INV-039 | Validating obligation data does not prove the obligation satisfied/enforced | Validation.Adapters | planned |
| VAL-INV-040 | Deferred Validation is never a substitute for Authorization/scope/obligation evaluation | Validation.Deferred | planned |

\* Structural invariants (no I/O, no registries, no auth) are guaranteed by the
dependency graph and enforced continuously by the dependency-boundary audit; a
dedicated regression asserts the boundary as packages land.

## Phase 0 evidence

- VAL-INV-002 / VAL-INV-015 / VAL-INV-028: `tests/src/proto_capabilities.*`
  stores unrelated typed values in one immutable container, recovers them by tag
  test + checked view conversion (never by address), and copies built values
  into the frozen container so no builder temporary is retained. Test:
  `Proto: capability typed round-trip`, `Proto: capability rejections`.
- VAL-INV-026: `tests/src/proto_rule_nodes.*` derives pass/fail from a
  dispatching node whose predicate is captured by instantiation, not stored as
  an access-to-local. Test: `Proto: rule-node callbacks`.
