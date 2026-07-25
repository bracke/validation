# Architecture Decision Records

| ADR | Title | Status |
|-----|-------|--------|
| 001 | Headless core and adapter boundaries | accepted (structural) |
| **002** | **Structured issues rather than exceptions** | **accepted** |
| 003 | Typed immutable validators | accepted (see ARCHITECTURE.md) |
| 004 | Deterministic execution order | accepted (see ARCHITECTURE.md) |
| **005** | **Structured validation paths** | **accepted** |
| 006 | Typed capability context | accepted (see ADR-015 + ARCHITECTURE.md) |
| **007** | **Deferred request/result protocol** | **accepted** |
| 008 | Deterministic replay | accepted (see ADR-007) |
| 009 | No global mutable registries | accepted (structural) |
| 010 | Message ids and typed arguments | accepted (see ARCHITECTURE.md) |
| 011 | Profiles and rule groups | accepted (see ARCHITECTURE.md) |
| 012 | Deterministic collection adapters | accepted (see ARCHITECTURE.md) |
| 013 | Subject and context token binding | accepted (see ADR-007) |
| **014** | **Callback ownership strategy** | **accepted (Phase 0)** |
| **015** | **Capability storage strategy** | **accepted (Phase 0)** |
| 016 | Deferred payload type erasure | accepted (follows ADR-015 pattern) |
| 017 | Continuation classes | accepted (in-process; see ADR-007) |
| **018** | **Fingerprint algorithm and format** | **accepted** |

The bolded ADRs have dedicated files. The others are decided and documented in
`docs/ARCHITECTURE.md` (and, for 014/015, the Phase 0 prototypes
`tests/src/proto_rule_nodes.*` and `tests/src/proto_capabilities.*`); dedicated
files can be split out if a decision is ever revisited.
