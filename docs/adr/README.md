# Architecture Decision Records

| ADR | Title | Status |
|-----|-------|--------|
| 001 | Headless core and adapter boundaries | accepted (structural) |
| 002 | Structured issues rather than exceptions | proposed |
| 003 | Typed immutable validators | proposed |
| 004 | Deterministic execution order | proposed |
| 005 | Structured validation paths | proposed |
| 006 | Typed capability context | proposed |
| 007 | Deferred request/result protocol | proposed |
| 008 | Deterministic replay | proposed |
| 009 | No global mutable registries | accepted (structural) |
| 010 | Message ids and typed arguments | proposed |
| 011 | Profiles and rule groups | proposed |
| 012 | Deterministic collection adapters | proposed |
| 013 | Subject and context token binding | proposed |
| **014** | **Callback ownership strategy** | **accepted (Phase 0)** |
| **015** | **Capability storage strategy** | **accepted (Phase 0)** |
| 016 | Deferred payload type erasure | proposed |
| 017 | Continuation classes | proposed |
| 018 | Fingerprint algorithm and format | proposed |

ADRs 014 and 015 are decided because Phase 0 built and tested working
prototypes of both (`tests/src/proto_rule_nodes.*`, `tests/src/proto_capabilities.*`).
The remaining "proposed" ADRs are decided as their owning packages are built in
the corresponding phases.
