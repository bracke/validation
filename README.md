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

## Example

```ada
package CV is new Validation.Validators (Customer);
package Email_Text is new Validation.Standard.Text (Customer, CV, Get_Email);
package Age_Num is new Validation.Standard.Numerics (Customer, CV, Integer, Get_Age);

B : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("customer"));
--  ...
CV.Add (B, Email_Text.Non_Empty (F_Email, Ids.Rule_Ids.Make ("email/required")));
CV.Add (B, Age_Num.In_Range     (F_Age, 0, 130, Ids.Rule_Ids.Make ("age/range")));

Result : constant Res.Result :=
  CV.Validate (Subject, CV.Get_Validator (CV.Finalize (B)), Context);
--  Result.Validity, Result.Issue_Count, Projections.Canonical_Order (...), ...
```

Full runnable version: [`examples/src/quickstart.adb`](examples/src/quickstart.adb).

## Status

Feature-complete V1; **65 tests green**. Scalars,
records, nested and recursive objects, collections, profiles/conditions/
prerequisites, deferred validation with replay, and the diagnostics/projection
surface are all built and tested. The one open release-integration task is the
`check_validation` / `project_tools` wiring (see [`docs/RELEASE.md`](docs/RELEASE.md)).

## Documentation

- [Quickstart](docs/QUICKSTART.md) · [Architecture](docs/ARCHITECTURE.md) ·
  [Validator catalog](docs/VALIDATOR_CATALOG.md) · [Security](SECURITY.md) ·
  [Release](docs/RELEASE.md)
- AI-oriented: [package map](docs/ai/package_map.md),
  [invariants](docs/ai/invariants.md),
  [prohibited patterns](docs/ai/prohibited_patterns.md),
  [allowed dependencies](docs/ai/allowed_dependencies.md)
- [Architecture Decision Records](docs/adr/)

## Building and testing

```sh
alr build                                    # build the library
cd tests && alr build && ./bin/tests         # AUnit suite (65 tests)
cd examples && alr build && ./bin/quickstart # runnable example
cd tools/check_validation && alr build       # the Ada release/check tool
./bin/check_validation                       # headless dependency-boundary audit
./bin/check_validation --prove               # + GNATprove on the SPARK_Mode units
```

## Layout

```
validation/
├── src/                 library sources (Validation.*)
├── tests/               AUnit test subcrate
├── examples/            compilable example programs
├── check_validation/    project_tools release guard
├── tools/               dependency audit + proof scripts
├── docs/                guides, ADRs, AI-oriented docs
│   ├── adr/             architecture decision records
│   └── ai/              package map, invariants, prohibited patterns, ...
└── .github/workflows/   CI
```

## License

MIT OR Apache-2.0 WITH LLVM-exception. See [LICENSE](LICENSE).
