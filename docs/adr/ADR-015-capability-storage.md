# ADR-015 — Capability storage strategy

**Status:** accepted (Phase 0)

## Context

`Validation.Contexts` must be a finalized immutable container holding
capabilities of **unrelated** value types, inserted and retrieved only through
matching typed generic instances, with: no application-visible type erasure, no
primary String-to-Any map, duplicate-id rejection, schema-version checks, and no
identity derived from an access value or memory address (VAL-INV-015). It must
also be lifetime-safe (no dangling, no retained builder temporaries) and free of
manual memory management hazards.

## Decision

Store capabilities **by value** in an indefinite vector of a private, class-wide
holder type:

- A private root `Holder` (tagged) carries the shared capability id + schema
  version. Concrete holders that add the typed value are declared in the body of
  a nested generic `Capability (Value_Type, Capability_Id, Schema_Version)`,
  which sees the parent's private part — so the type erasure never leaves the
  package.
- Insertion copies the concrete holder into an
  `Ada.Containers.Indefinite_Vectors (Positive, Holder'Class)`; freezing copies
  the vector into the immutable container. No access types, no
  `Unchecked_Conversion`, no manual deallocation, no retained builder temporary.
- Retrieval matches by capability id, then requires **both** the schema version
  and the concrete tag to agree (`E in Value_Holder'Class`) before a *checked*
  view conversion recovers the value. Identity is by id + tag, never by address.
- A schema-version or type mismatch surfaces as "not found" — an incompatible
  capability is never silently coerced.

## Alternatives considered

- **`Unchecked_Conversion` from a generic payload** — rejected: reintroduces the
  exact unsafety this design removes; would need an audited isolation package.
- **Access-to-`Holder'Class` + controlled container** — workable but adds manual
  deallocation and deep-copy (`Adjust`) burden with no benefit over by-value
  indefinite storage.
- **String-to-Any map** — prohibited (service-locator anti-pattern, INV-020,
  no type safety).

## Consequences

- Fully type-safe public API; type erasure is confined to the private body.
- Scalar `out` retrieval is by-copy: `Value` is meaningful only when `Found` is
  True (callers check `Found` first). Documented in the API.
- Proven by `tests/src/proto_capabilities.*` and the `Proto: capability *`
  tests. This is the storage model Phase 3 `Validation.Contexts` will adopt
  (extended with ownership policy, sensitivity, and trust provenance).
