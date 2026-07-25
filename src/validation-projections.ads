with Ada.Strings.Unbounded;
with Validation.Issues;
with Validation.Results;

------------------------------------------------------------------------------
--  Validation.Projections
--
--  Versioned, serialization-neutral Ada record schemas (§56). External
--  serializers turn these into JSON/XML/text/etc.; the core never chooses an
--  encoding. Projections consume only finalized immutable results and are
--  deterministic. Phase 2 provides the compact issue projection and the result
--  summary; the standard/diagnostic projections and the By_Path/By_Object_Key/
--  By_Source groupings land in Phase 10.
------------------------------------------------------------------------------

package Validation.Projections is

   use Ada.Strings.Unbounded;

   ---------------------------------------------------------------------------
   --  Compact issue projection v1 (§56)
   ---------------------------------------------------------------------------

   type Compact_Issue is record
      Identity_Image   : Unbounded_String;
      Severity         : Issues.Severity;
      Primary_Path     : Unbounded_String;   --  rendered, redaction-aware
      Message_Id       : Unbounded_String;
      Argument_Count   : Natural;
      Has_Machine_Code : Boolean;
      Machine_Code     : Unbounded_String;
   end record;

   function Compact (Item : Issues.Issue) return Compact_Issue;

   type Compact_Issue_Array is array (Positive range <>) of Compact_Issue;

   function Compact_All
     (Collection : Issues.Issue_Collection) return Compact_Issue_Array;

   --  A canonical one-line rendering, handy for deterministic comparison:
   --  "<severity> <primary-path> <message-id>".
   function Render (Item : Compact_Issue) return String;

   ---------------------------------------------------------------------------
   --  Result summary projection v1 (§56)
   ---------------------------------------------------------------------------

   type Result_Summary is record
      Status                 : Results.Execution_Status;
      Validity               : Results.Semantic_Validity;
      Coverage               : Results.Coverage;
      Issue_Count            : Natural;
      Error_Count            : Natural;
      Warning_Count          : Natural;
      Information_Count      : Natural;
      Has_Highest_Severity   : Boolean;
      Highest_Severity       : Issues.Severity;
      Incompleteness_Count   : Natural;
      Invocation_Error_Count : Natural;
      Semantic_Fingerprint   : Unbounded_String;
   end record;

   function Summarize (Item : Results.Result) return Result_Summary;

   ---------------------------------------------------------------------------
   --  Standard issue projection v1 (§56) — compact fields plus category,
   --  validator/rule ids, and related/argument/metadata counts. (Related paths
   --  and metadata entries are enumerated from the source issue when needed.)
   ---------------------------------------------------------------------------

   type Standard_Issue is record
      Identity_Image      : Unbounded_String;
      Severity            : Issues.Severity;
      Primary_Path        : Unbounded_String;
      Message_Id          : Unbounded_String;
      Category            : Unbounded_String;
      Validator_Id        : Unbounded_String;
      Rule_Id             : Unbounded_String;
      Related_Count       : Natural;
      Argument_Count      : Natural;
      Metadata_Count      : Natural;
      Provenance_Standard : Boolean;
   end record;

   function Standard (Item : Issues.Issue) return Standard_Issue;

   ---------------------------------------------------------------------------
   --  Canonical ordering (§56, §57) — a deterministic issue order (by path,
   --  then severity, then rule, then message, then ordinal) that does NOT
   --  mutate execution order.
   ---------------------------------------------------------------------------

   function Canonical_Order
     (Collection : Issues.Issue_Collection) return Compact_Issue_Array;

   ---------------------------------------------------------------------------
   --  Grouping by path (§56) — the distinct rendered primary paths in sorted
   --  order. Combine with Results.Issues_At_Exact_Path to iterate each group.
   ---------------------------------------------------------------------------

   type Path_List is array (Positive range <>) of Unbounded_String;

   function Distinct_Paths
     (Collection : Issues.Issue_Collection) return Path_List;

end Validation.Projections;
