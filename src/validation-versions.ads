------------------------------------------------------------------------------
--  Validation.Versions
--
--  Version types kept deliberately separate (§79). The library has one
--  Semantic_Version; each externally observable protocol/schema has its own
--  Schema_Version stream so they can advance independently. Schema_Version is a
--  distinct type so a projection-schema version cannot be confused with, say,
--  the continuation-format version.
------------------------------------------------------------------------------

package Validation.Versions
  with Pure
is

   type Version_Component is range 0 .. 2**16 - 1;

   type Semantic_Version is record
      Major : Version_Component := 0;
      Minor : Version_Component := 0;
      Patch : Version_Component := 0;
   end record;

   function Image (V : Semantic_Version) return String;

   function "<" (Left, Right : Semantic_Version) return Boolean;
   function "<=" (Left, Right : Semantic_Version) return Boolean;

   Library_Version : constant Semantic_Version := (0, 1, 0);

   --  Protocol/schema version streams. Each is independent (§79). Distinct
   --  type so streams cannot be cross-assigned.
   type Schema_Version is new Positive;

   Issue_Id_Format_Version           : constant Schema_Version := 1;
   Fingerprint_Format_Version        : constant Schema_Version := 1;
   Continuation_Format_Version       : constant Schema_Version := 1;
   Path_Projection_Schema_Version    : constant Schema_Version := 1;
   Issue_Projection_Schema_Version   : constant Schema_Version := 1;
   Message_Argument_Schema_Version   : constant Schema_Version := 1;
   Introspection_Schema_Version      : constant Schema_Version := 1;

end Validation.Versions;
