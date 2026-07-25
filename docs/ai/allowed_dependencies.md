# Allowed Dependencies

## The rule

Dependency direction is always **from consumers toward Validation**. Validation
depends only on the **Ada standard library**.

Allowed to depend on Validation: Forms, Tables, Webframework applications,
Database-oriented code, i18n/Humanize adapters, Identity- and
Authorization-facing input adapters, CLIs, importers, background jobs.

**Validation must not depend on any of them.** Nor on: HTTP, HTML, templates,
WebSockets, JavaScript, logging frameworks, task schedulers, message queues,
serialization libraries, regex engines, or advanced Unicode libraries (except as
an explicit optional adapter *outside* the core dependency graph).

## Internal layering

Foundational packages depend only on `Validation`, lower foundational packages,
and the Ada standard library — never on validators, execution, standard
validators, or adapters. Contexts/Profiles/Rules depend only on foundational
layers. Standard validators depend only on the public Validation API. Adapters
depend on the public API plus their one explicit external dependency. **The core
never depends upward on adapters.**

## Enforcement

- `alire.toml` declares only `gnat_native`. Adding any ecosystem crate to the
  core `alire.toml` is a boundary violation.
- A dependency-boundary audit (project_tools) runs in CI and fails the build if
  a core package `with`s a forbidden unit.

## Identity / Authorization

Validation may validate transport-neutral **typed input** destined for Identity
or Authorization, but never verifies credentials, authenticates, authorizes,
derives scopes, or satisfies obligations. Optional `Validation_Identity` /
`Validation_Authorization` adapter families may exist **outside** the core and
are never core dependencies. See `prohibited_patterns.md`.
