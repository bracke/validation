private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Paths;
with Validation.Messages;
with Validation.Metadata;
with Validation.Provenance;
with Validation.Source_References;
with Validation.Fingerprints;

------------------------------------------------------------------------------
--  Validation.Issues
--
--  Immutable structured diagnostics (§11). Every issue has exactly one primary
--  path (VAL-INV-006) and identifies its originating validator and rule
--  (VAL-INV-007). Rules do NOT construct issues directly — the engine-owned
--  builder here supplies the engine fields (ordinal, validator, rule,
--  provenance) alongside the semantic fields a rule provides. Issue_Identity is
--  a deterministic occurrence identity (§12) computed from the issue's stable
--  content plus the issue-id format version; it is suitable for stale-state /
--  UI-replacement comparison, not as a permanent business key.
--
--  Related paths are deterministic, immutable, and duplicate-controlled, and
--  are bounded (Max_Related_Paths) per VAL-INV-016.
------------------------------------------------------------------------------

package Validation.Issues is

   type Severity is (Information, Warning, Error);
   --  Ordering: Information < Warning < Error.

   Max_Related_Paths : constant := 32;

   ---------------------------------------------------------------------------
   --  Standard issue categories (§11). Extensible via any Issue_Category_Id.
   ---------------------------------------------------------------------------

   package CAT renames Identifiers.Issue_Category_Ids;

   Category_Presence     : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.presence");
   Category_Value        : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.value");
   Category_Range        : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.range");
   Category_Length       : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.length");
   Category_Format       : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.format");
   Category_Encoding     : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.encoding");
   Category_Membership   : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.membership");
   Category_Consistency  : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.consistency");
   Category_Duplicate    : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.duplicate");
   Category_Ordering     : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.ordering");
   Category_Aggregate    : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.aggregate");
   Category_Transition   : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.transition");
   Category_External_Ref : constant Identifiers.Issue_Category_Id :=
     CAT.Make ("validation.category.external_reference");
   Category_Graph        : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.graph");
   Category_Deferred     : constant Identifiers.Issue_Category_Id := CAT.Make ("validation.category.deferred");
   Category_Business_Rule : constant Identifiers.Issue_Category_Id :=
     CAT.Make ("validation.category.business_rule");

   ---------------------------------------------------------------------------
   --  Issue identity
   ---------------------------------------------------------------------------

   type Issue_Identity is private;
   function Image (Item : Issue_Identity) return String;
   overriding function "=" (Left, Right : Issue_Identity) return Boolean;

   ---------------------------------------------------------------------------
   --  Issue
   ---------------------------------------------------------------------------

   type Issue is private;

   type Issue_Builder is private;

   function Begin_Issue
     (Ordinal      : Positive;
      Validator    : Identifiers.Validator_Id;
      Rule         : Identifiers.Rule_Id;
      Level        : Severity;
      Category     : Identifiers.Issue_Category_Id;
      Primary_Path : Paths.Path;
      Message      : Messages.Message;
      Provenance   : Validation.Provenance.Provenance) return Issue_Builder;

   --  Appends a related path; Added is False when it duplicates the primary or
   --  an existing related path, or when Max_Related_Paths is reached.
   procedure Add_Related_Path
     (Builder : in out Issue_Builder;
      Path    : Paths.Path;
      Added   : out Boolean);

   procedure Set_Machine_Code
     (Builder : in out Issue_Builder; Machine : Identifiers.Machine_Code);
   procedure Set_Metadata
     (Builder : in out Issue_Builder; Data : Metadata.Metadata);
   procedure Set_Source
     (Builder : in out Issue_Builder;
      Source  : Source_References.Source_Reference);

   function Build (Builder : Issue_Builder) return Issue;

   ---------------------------------------------------------------------------
   --  Accessors
   ---------------------------------------------------------------------------

   function Identity (Item : Issue) return Issue_Identity;
   function Ordinal (Item : Issue) return Positive;
   function Validator (Item : Issue) return Identifiers.Validator_Id;
   function Rule (Item : Issue) return Identifiers.Rule_Id;
   function Level (Item : Issue) return Severity;
   function Category (Item : Issue) return Identifiers.Issue_Category_Id;
   function Primary_Path (Item : Issue) return Paths.Path;
   function Message (Item : Issue) return Messages.Message;
   function Related_Path_Count (Item : Issue) return Natural;
   function Related_Path_At
     (Item : Issue; Position : Positive) return Paths.Path
     with Pre => Position <= Related_Path_Count (Item);
   function Has_Machine_Code (Item : Issue) return Boolean;
   function Machine_Code (Item : Issue) return Identifiers.Machine_Code
     with Pre => Has_Machine_Code (Item);
   function Metadata_Of (Item : Issue) return Metadata.Metadata;
   function Provenance_Of (Item : Issue) return Validation.Provenance.Provenance;
   function Has_Source (Item : Issue) return Boolean;
   function Source (Item : Issue) return Source_References.Source_Reference
     with Pre => Has_Source (Item);

   overriding function "=" (Left, Right : Issue) return Boolean;

   ---------------------------------------------------------------------------
   --  Issue collection (ordered, bounded, deterministic)
   ---------------------------------------------------------------------------

   type Issue_Collection is private;

   function Empty_Collection return Issue_Collection;
   procedure Append (Collection : in out Issue_Collection; Item : Issue);
   function Count (Collection : Issue_Collection) return Natural;
   function Element
     (Collection : Issue_Collection; Position : Positive) return Issue
     with Pre => Position <= Count (Collection);

   function Error_Count (Collection : Issue_Collection) return Natural;
   function Warning_Count (Collection : Issue_Collection) return Natural;
   function Information_Count (Collection : Issue_Collection) return Natural;
   function Has_Errors (Collection : Issue_Collection) return Boolean;
   function Highest_Severity (Collection : Issue_Collection) return Severity
     with Pre => Count (Collection) >= 1;

private

   package Path_Vectors is new Ada.Containers.Vectors
     (Positive, Paths.Path, Paths."=");

   type Issue_Identity is record
      Value : Fingerprints.Fingerprint;
   end record;

   type Issue is record
      Ident       : Issue_Identity;
      Ordinal     : Positive := 1;
      Validator   : Identifiers.Validator_Id;
      Rule        : Identifiers.Rule_Id;
      Level       : Severity := Error;
      Category    : Identifiers.Issue_Category_Id;
      Primary     : Paths.Path;
      Related     : Path_Vectors.Vector;
      Message     : Messages.Message;
      Machine_Set : Boolean := False;
      Machine     : Identifiers.Machine_Code;
      Meta        : Metadata.Metadata := Metadata.Empty;
      Prov        : Validation.Provenance.Provenance;
      Source_Set  : Boolean := False;
      Source_Ref  : Source_References.Source_Reference;
   end record;

   type Issue_Builder is record
      Data : Issue;
   end record;

   package Issue_Vectors is new Ada.Containers.Vectors (Positive, Issue, "=");

   type Issue_Collection is record
      Items : Issue_Vectors.Vector;
   end record;

end Validation.Issues;
