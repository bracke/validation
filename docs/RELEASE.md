# Release

## Protocol / schema versions

Tracked independently in `Validation.Versions` (issue-id format, fingerprint
format, continuation format, and the projection/introspection schema versions).
Cross-release continuation compatibility is **not** promised for V1; a release
may invalidate prior continuations and must say so.

## Release gates

A release is valid only when all of these pass:

- **Build** — `alr build` (library) and `cd tests && alr build` and
  `cd examples && alr build`, all clean under the strict switches.
- **Test** — `./tests/bin/tests` green (currently 65/65), including the
  determinism, fuzz, fault-injection, and ownership tests.
- **Quality** — `./tools/check_dependencies.sh` clean (headless boundary);
  `./tools/prove.sh` clean (GNATprove on the SPARK_Mode units).
- **Docs** — README, QUICKSTART, ARCHITECTURE, VALIDATOR_CATALOG, SECURITY, the
  `docs/ai/*` set, ADRs, and CHANGELOG current; the example compiles and runs.
- **Determinism** — semantic snapshots reproducible; hashed insertion order and
  deferred arrival order independent; no random ids/timestamps/addresses in
  semantic output.
- **Artifacts** — version consistent across `alire.toml` files; CHANGELOG entry;
  no build output / secrets in the source archive.

## project_tools integration (pending)

The sibling projects (Tables/Navigation/Forms/humanize) run release, doc, and
repository checks through a dedicated `check_<crate>` subcrate that depends on
`project_tools`. Validation should gain a `check_validation` subcrate wired the
same way; until then the gates above are run via the scripts in `tools/` and the
test subcrate. This is the one remaining release-integration task.

## Cutting a release

1. Run every gate above.
2. Bump `version` in `alire.toml` and the protocol/schema versions in
   `Validation.Versions` for any breaking change; add a CHANGELOG entry noting
   package, ordering, id, fingerprint, and continuation impact.
3. Tag and publish per the ecosystem Alire workflow.
