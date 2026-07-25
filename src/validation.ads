------------------------------------------------------------------------------
--  Validation
--
--  Root package of the Validation library: a headless, deterministic, strongly
--  typed validation engine for scalar values, records, nested objects,
--  collections, recursive structures, application commands, imports, APIs, CLI
--  applications, background jobs, and service-layer workflows.
--
--  Validation answers exactly one question: given a typed subject, a finalized
--  immutable validator, an immutable context, active profiles, and execution
--  options, what structured issues were found, what work remains unresolved,
--  and was execution complete?
--
--  Validation is HEADLESS. It never performs HTTP, database, file, network,
--  scheduler, task-queue, or UI operations; never authenticates or authorizes;
--  never verifies credentials; never renders localized text; never mutates the
--  subject; and never reads the system clock implicitly. See docs/ai/
--  invariants.md for the authoritative VAL-INV-* registry.
--
--  This root is a pure namespace. Foundational children (Identifiers, Values,
--  Paths, ...) build upward toward Validators, Collections, Deferred, and the
--  projection/introspection surface. See docs/ai/package_map.md.
------------------------------------------------------------------------------

package Validation
  with Pure
is

   --  Semantic library version. Distinct protocol/schema versions (issue-ID
   --  format, fingerprint format, continuation format, projection schemas) are
   --  tracked separately in Validation.Versions.
   Library_Version : constant String := "0.1.0-dev";

end Validation;
