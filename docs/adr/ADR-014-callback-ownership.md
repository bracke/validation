# ADR-014 — Callback ownership strategy

**Status:** accepted (Phase 0)

## Context

Rules carry logic: predicates, conditions, comparators, accessors, argument
factories, key projections, deferred request builders/interpreters, fingerprint
contributors. A finalized validator must store this logic **immutably and
safely**. Storing anonymous `access`-to-subprogram values risks accessibility
violations (dangling references to procedure-local subprograms) and Ada
accessibility-check failures. A global callback registry is prohibited
(VAL-INV-020).

## Decision

Capture callbacks **by generic instantiation into immutable class-wide rule
nodes**, never as stored access-to-local-subprogram:

- A private root `Node` (tagged) holds immutable configuration (e.g. the failure
  message id) and declares an abstract primitive (`Check`).
- A nested generic (e.g. `Predicate_Rule (Predicate, Message_Id)`) declares, in
  its body, a concrete node type whose overriding `Check` **calls the generic
  formal subprogram directly**. The predicate is therefore baked into a concrete
  type by the instantiation — there is no access value to dangle.
- Finalized rules store the node as a class-wide value in an
  `Ada.Containers.Indefinite_Holders (Node'Class)`; a validator stores an
  ordered vector of such rules. Evaluation dispatches on the node.

Rule outcomes (pass/fail + message) are **derived by the engine** from the
dispatching call (VAL-INV-026); a callback cannot return an independent verdict
that contradicts its output.

## Alternatives considered

- **`access function` stored in the node** — rejected: accessibility hazards,
  and the reference cannot be portably fingerprinted; requires every rule to
  supply an explicit implementation-version id anyway.
- **A single dispatching interface implemented by application types** — viable
  but pushes boilerplate onto callers; the generic wrapper keeps the public API
  a simple `Predicate`+`Message_Id` while producing the same immutable node.

## Consequences

- No accessibility hazard, no dangling, no global registry; nodes are immutable
  and copyable by value.
- Because code bodies cannot be portably hashed, every executable rule must
  carry a stable `Implementation_Version_Id` for fingerprinting (ADR-018). The
  generic-node model gives standard rules a natural place to supply it.
- Proven by `tests/src/proto_rule_nodes.*` and the `Proto: rule-node callbacks`
  test. Phase 4 `Validation.Rules` adopts this model (extended with phases,
  categories, context contracts, and the engine-controlled output interface).
