with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Paths;
with Validation.Messages;
with Validation.Provenance;
with Validation.Issues;
with Validation.Results;
with Validation.Projections;
with Validation.Fingerprints;

package body Diagnostics_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Paths renames Validation.Paths;
   package Msgs renames Validation.Messages;
   package Prov renames Validation.Provenance;
   package Iss renames Validation.Issues;
   package Res renames Validation.Results;
   package Proj renames Validation.Projections;

   package Caller is new AUnit.Test_Caller (Fixture);

   V : constant Ids.Validator_Id := Ids.Validator_Ids.Make ("v");

   function FID (Name : String) return Ids.Field_Id is (Ids.Field_Ids.Make (Name));
   function P (Field : String) return Paths.Path is
     (Paths.Append_Field (Paths.Root, FID (Field)));

   function Make_Issue
     (Ordinal : Positive; Rule : String; Level : Iss.Severity;
      At_Path : Paths.Path; Message : Ids.Message_Id) return Iss.Issue
   is
      R : constant Ids.Rule_Id := Ids.Rule_Ids.Make (Rule);
      B : constant Iss.Issue_Builder :=
        Iss.Begin_Issue
          (Ordinal, V, R, Level, Iss.Category_Value, At_Path,
           Msgs.Make (Message), Prov.Make_Minimal (V, R, Ordinal));
   begin
      return Iss.Build (B);
   end Make_Issue;

   I_A : constant Iss.Issue :=
     Make_Issue (1, "r.a", Iss.Error, P ("a"), Msgs.Required);
   I_B : constant Iss.Issue :=
     Make_Issue (2, "r.b", Iss.Warning, P ("b"), Msgs.Not_Blank);

   function Result_Of (First, Second : Iss.Issue) return Res.Result is
      RB : Res.Result_Builder := Res.Begin_Result (Res.Completed);
   begin
      Res.Add_Issue (RB, First);
      Res.Add_Issue (RB, Second);
      return Res.Build (RB);
   end Result_Of;

   --------------------------------------------------------------------------

   procedure Test_Standard_Projection (T : in out Fixture) is
      pragma Unreferenced (T);
      S : constant Proj.Standard_Issue := Proj.Standard (I_A);
   begin
      Assert (To_String (S.Rule_Id) = "r.a", "rule id");
      Assert (To_String (S.Primary_Path) = "$.a", "primary path");
      Assert (To_String (S.Validator_Id) = "v", "validator id");
      Assert (S.Related_Count = 0, "no related paths");
      Assert (not S.Provenance_Standard, "minimal provenance");
   end Test_Standard_Projection;

   procedure Test_Canonical_Order (T : in out Fixture) is
      pragma Unreferenced (T);
      Coll : Iss.Issue_Collection := Iss.Empty_Collection;
   begin
      --  Execution order: B (at $.b) then A (at $.a).
      Iss.Append (Coll, I_B);
      Iss.Append (Coll, I_A);
      declare
         Ordered : constant Proj.Compact_Issue_Array := Proj.Canonical_Order (Coll);
      begin
         --  Canonical order sorts by path: $.a before $.b.
         Assert (Proj.Render (Ordered (1)) = "ERROR $.a validation.required",
                 "canonical order puts $.a first");
         Assert (To_String (Ordered (2).Primary_Path) = "$.b", "then $.b");
      end;
   end Test_Canonical_Order;

   procedure Test_Distinct_Paths (T : in out Fixture) is
      pragma Unreferenced (T);
      Coll : Iss.Issue_Collection := Iss.Empty_Collection;
   begin
      Iss.Append (Coll, I_A);
      Iss.Append (Coll, I_B);
      Iss.Append (Coll, I_A);   --  duplicate path
      declare
         Paths_Found : constant Proj.Path_List := Proj.Distinct_Paths (Coll);
      begin
         Assert (Paths_Found'Length = 2, "two distinct paths");
         Assert (To_String (Paths_Found (1)) = "$.a"
                   and then To_String (Paths_Found (2)) = "$.b",
                 "sorted, deduplicated");
      end;
   end Test_Distinct_Paths;

   procedure Test_Issue_Set_Fingerprint (T : in out Fixture) is
      pragma Unreferenced (T);
      use type Validation.Fingerprints.Fingerprint;
      R1 : constant Res.Result := Result_Of (I_B, I_A);   --  B then A
      R2 : constant Res.Result := Result_Of (I_A, I_B);   --  A then B
   begin
      --  Same issues, different order: issue-set fingerprint is equal, but the
      --  execution-order semantic fingerprint differs.
      Assert (Res.Same_Issue_Set (R1, R2),
              "issue-set fingerprint is order-independent");
      Assert (Res.Semantic_Fingerprint (R1) /= Res.Semantic_Fingerprint (R2),
              "execution-order fingerprint reflects order");
   end Test_Issue_Set_Fingerprint;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Diagnostics: standard projection", Test_Standard_Projection'Access));
      Suite.Add_Test
        (Caller.Create ("Diagnostics: canonical order", Test_Canonical_Order'Access));
      Suite.Add_Test
        (Caller.Create ("Diagnostics: distinct paths", Test_Distinct_Paths'Access));
      Suite.Add_Test
        (Caller.Create ("Diagnostics: issue-set fingerprint", Test_Issue_Set_Fingerprint'Access));
   end Add_Tests;

end Diagnostics_Tests;
