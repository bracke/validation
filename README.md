# Validation

A headless, deterministic, strongly typed **validation engine** for Ada 2022.

Validation answers one question:

> Given a typed subject, a finalized immutable validator, an immutable context,
> active profiles, and execution options — what structured issues were found,
> what work remains unresolved, and was execution complete?

It validates scalars, records, nested and recursive objects, optional values,
collections (cardinality, elements, uniqueness, ordering, quantifiers,
aggregates), cross-field and whole-object rules, conditional rules, profiles and
rule groups, and deferred (externally executed) checks with deterministic
replay.

## What it is not

Validation is **headless** and does exactly one job. It never:

- performs HTTP, database, file, network, scheduler, task-queue, or UI work;
- authenticates or verifies credentials (that is Identity);
- authorizes, derives scopes, or satisfies obligations (that is Authorization);
- renders localized text (it returns stable message ids + typed arguments);
- mutates, trims, normalizes, or repairs the subject;
- reads the system clock implicitly.

Consumers (Forms, Tables, Webframework apps, services, importers, CLIs, jobs)
depend on Validation; Validation depends on none of them. See
[`docs/ai/allowed_dependencies.md`](docs/ai/allowed_dependencies.md).

## Status

Under construction, built in vertical slices (see
[`docs/PHASE_STATUS.md`](docs/PHASE_STATUS.md)).

- **Phase 0 — repository & feasibility prototypes: complete.** The two riskiest
  Ada design questions are proven to compile and behave under the strict switch
  set: heterogeneous typed **capability storage** (no exposed type erasure, no
  address identity, schema-checked recovery) and safe **callback storage**
  (predicates captured by instantiation into immutable class-wide nodes — no
  stored access-to-local). See [`docs/adr/`](docs/adr/).

## Building and testing

```sh
alr build                       # build the library
cd tests && alr build && ./bin/tests   # build and run the AUnit suite
```

## Layout

```
validation/
├── src/                 library sources (Validation.*)
├── tests/               AUnit test subcrate (+ Phase 0 prototypes)
├── docs/                guides, ADRs, AI-oriented docs
│   ├── adr/             architecture decision records
│   └── ai/              package map, invariants, prohibited patterns, ...
└── .github/workflows/   CI
```

## License

MIT OR Apache-2.0 WITH LLVM-exception.
