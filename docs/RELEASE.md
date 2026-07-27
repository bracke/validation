# Release

## Protocol / schema versions

Tracked independently in `Validation.Versions` (issue-id format, fingerprint
format, continuation format, and the projection/introspection schema versions).
Cross-release continuation compatibility is **not** promised for V1; a release
may invalidate prior continuations and must say so.

## Release gates

The gates run through the **`check_validation`** subcrate (which depends on
`project_tools`, the sibling-project release-check mechanism):

```sh
cd check_validation && alr build
./bin/check_validation                 # required surface + dependency audit (fast)
./bin/check_validation --release       # + build library, build/run tests, build/run example
./bin/check_validation --release-strict  # + require clean git worktrees
```

`check_validation` verifies, via `project_tools`:

- **Required surface** — README, LICENSE, CHANGELOG, SECURITY, CONTRIBUTING, the
  `docs/` guides and `docs/ai/*` set, the ADR index, the `tools/check_validation`
  tool, and the example source; plus key text (the `gnat_native` pin, `VAL-INV-040`).
- **Dependency boundary** — runs `tools/check_validation` (headless audit).
- **Build/test/example** (`--release`) — builds the library, builds and runs the
  AUnit suite (65/65), and builds and runs the example.
- **Clean worktrees** (`--release-strict`) — validation and project_tools.

Additionally, run `./bin/check_validation --prove` for the GNATprove check on the SPARK_Mode
units, and confirm determinism (semantic snapshots reproducible; hashed
insertion and deferred arrival order independent; no random ids/timestamps/
addresses in semantic output) and artifact hygiene (versions consistent, no
build output/secrets in the source archive).

## Cutting a release

1. Run every gate above.
2. Bump `version` in `alire.toml` and the protocol/schema versions in
   `Validation.Versions` for any breaking change; add a CHANGELOG entry noting
   package, ordering, id, fingerprint, and continuation impact.
3. Tag and publish per the ecosystem Alire workflow.
