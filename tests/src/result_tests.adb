with Ada.Strings.Unbounded;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Paths;
with Validation.Messages;
with Validation.Provenance;
with Validation.Issues;
with Validation.Errors;
with Validation.Results;
with Validation.Projections;

package body Result_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Paths renames Validation.Paths;
   package Msgs renames Validation.Messages;
   package Prov renames Validation.Provenance;
   package Iss renames Validation.Issues;
   package Errs renames Validation.Errors;
   package Res renames Validation.Results;
   package Proj renames Validation.Projections;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Iss.Severity;
   use type Iss.Issue_Identity;
   use type Res.Semantic_Validity;
   use type Res.Execution_Status;
   use type Errs.Error_Domain;

   V : constant Ids.Validator_Id := Ids.Validator_Ids.Make ("customer");
   R_Email : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("customer.email/required");
   R_Name  : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("customer.name/length");

   function FID (Name : String) return Ids.Field_Id is (Ids.Field_Ids.Make (Name));

   function Email_Path return Paths.Path is
     (Paths.Append_Field (Paths.Root, FID ("email")));
   function Name_Path return Paths.Path is
     (Paths.Append_Field (Paths.Root, FID ("name")));

   function Email_Error return Iss.Issue is
      B : constant Iss.Issue_Builder :=
        Iss.Begin_Issue
          (Ordinal      => 1,
           Validator    => V,
           Rule         => R_Email,
           Level        => Iss.Error,
           Category     => Iss.Category_Presence,
           Primary_Path => Email_Path,
           Message      => Msgs.Make (Msgs.Required),
           Provenance   => Prov.Make_Minimal (V, R_Email, 1));
   begin
      return Iss.Build (B);
   end Email_Error;

   function Name_Warning return Iss.Issue is
      B : constant Iss.Issue_Builder :=
        Iss.Begin_Issue
          (Ordinal      => 2,
           Validator    => V,
           Rule         => R_Name,
           Level        => Iss.Warning,
           Category     => Iss.Category_Length,
           Primary_Path => Name_Path,
           Message      => Msgs.Make (Msgs.Length_Maximum),
           Provenance   => Prov.Make_Minimal (V, R_Name, 2));
   begin
      return Iss.Build (B);
   end Name_Warning;

   --------------------------------------------------------------------------

   procedure Test_Issue_Identity (T : in out Fixture) is
      pragma Unreferenced (T);
      A : constant Iss.Issue := Email_Error;
      B : constant Iss.Issue := Email_Error;
      C : constant Iss.Issue := Name_Warning;
   begin
      Assert (Iss."=" (A, B), "identical issues are exactly equal");
      Assert (Iss.Identity (A) = Iss.Identity (B),
              "identical issues share a deterministic identity");
      Assert (not (Iss.Identity (A) = Iss.Identity (C)),
              "different issues have different identity");
      Assert (Iss.Level (A) = Iss.Error, "severity");
      Assert (Iss.Image (Iss.Identity (A))'Length = 16, "identity is 16 hex");
   end Test_Issue_Identity;

   procedure Test_Related_Paths (T : in out Fixture) is
      pragma Unreferenced (T);
      B     : Iss.Issue_Builder :=
        Iss.Begin_Issue
          (1, V, R_Email, Iss.Error, Iss.Category_Consistency,
           Email_Path, Msgs.Make (Msgs.Fields_Match),
           Prov.Make_Minimal (V, R_Email, 1));
      Added : Boolean;
   begin
      Iss.Add_Related_Path (B, Name_Path, Added);
      Assert (Added, "related path added");
      Iss.Add_Related_Path (B, Name_Path, Added);
      Assert (not Added, "duplicate related path rejected");
      Iss.Add_Related_Path (B, Email_Path, Added);
      Assert (not Added, "related equal to primary rejected");

      declare
         I : constant Iss.Issue := Iss.Build (B);
      begin
         Assert (Iss.Related_Path_Count (I) = 1, "exactly one related path");
      end;
   end Test_Related_Paths;

   procedure Test_Validity_Derivation (T : in out Fixture) is
      pragma Unreferenced (T);

      function Built
        (Status : Res.Execution_Status; With_Error, With_Warning : Boolean)
         return Res.Result is
         B : Res.Result_Builder := Res.Begin_Result (Status);
      begin
         if With_Error then
            Res.Add_Issue (B, Email_Error);
         end if;
         if With_Warning then
            Res.Add_Issue (B, Name_Warning);
         end if;
         return Res.Build (B);
      end Built;
   begin
      Assert (Res.Validity (Built (Res.Completed, False, False)) = Res.Valid,
              "completed + no issues = Valid");
      Assert (Res.Validity (Built (Res.Completed, False, True))
                = Res.Valid_With_Nonerrors,
              "completed + only warning = Valid_With_Nonerrors");
      Assert (Res.Validity (Built (Res.Completed, True, False)) = Res.Invalid,
              "completed + error = Invalid");
      Assert (Res.Validity (Built (Res.Pending, False, False)) = Res.Undetermined,
              "pending + no error = Undetermined");
      Assert (Res.Validity (Built (Res.Pending, True, False)) = Res.Invalid,
              "pending + error = Invalid (errors always win)");
   end Test_Validity_Derivation;

   procedure Test_Result_Queries (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Res.Result_Builder := Res.Begin_Result (Res.Completed);
   begin
      Res.Add_Issue (B, Email_Error);
      Res.Add_Issue (B, Name_Warning);
      declare
         Result : constant Res.Result := Res.Build (B);
      begin
         Assert (Res.Issue_Count (Result) = 2, "two issues");
         Assert (Res.Error_Count (Result) = 1 and then Res.Warning_Count (Result) = 1,
                 "severity counts");
         Assert (Res.Highest_Severity (Result) = Iss.Error, "highest severity");
         Assert (Iss.Count (Res.Issues_From_Rule (Result, R_Email)) = 1,
                 "filter by rule");
         Assert (Iss.Count (Res.Issues_At_Exact_Path (Result, Name_Path)) = 1,
                 "filter by exact path");
         Assert (Iss.Count (Res.Issues_By_Category (Result, Iss.Category_Length))
                   = 1,
                 "filter by category");
         Assert (not Res.Has_Invocation_Failure (Result), "no invocation failure");
      end;
   end Test_Result_Queries;

   procedure Test_Invocation_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Res.Result_Builder := Res.Begin_Result (Res.Invocation_Failed);
      E : constant Errs.Error := Errs.Make (Errs.Missing_Capability);
   begin
      Res.Add_Invocation_Error (B, E);
      declare
         Result : constant Res.Result := Res.Build (B);
      begin
         Assert (Res.Has_Invocation_Failure (Result), "invocation failure flagged");
         Assert (Res.Invocation_Error_Count (Result) = 1, "one invocation error");
         Assert (not Res.Is_Complete (Result), "not complete");
      end;
      Assert (Errs.Key (E) = "invocation.missing_capability",
              "invocation error key");
      Assert (Errs.Key (Errs.Make (Errs.Duplicate_Rule_Id))
                = "definition.duplicate_rule_id",
              "definition error key");
      Assert (Errs.Domain_Of (E) = Errs.Invocation, "domain classified");
   end Test_Invocation_Errors;

   procedure Test_Projections (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Res.Result_Builder := Res.Begin_Result (Res.Completed);

      function Fresh_Result return Res.Result is
         C : Res.Result_Builder := Res.Begin_Result (Res.Completed);
      begin
         Res.Add_Issue (C, Email_Error);
         Res.Add_Issue (C, Name_Warning);
         return Res.Build (C);
      end Fresh_Result;
   begin
      Res.Add_Issue (B, Email_Error);
      Res.Add_Issue (B, Name_Warning);
      declare
         Result  : constant Res.Result := Res.Build (B);
         Compact : constant Proj.Compact_Issue := Proj.Compact (Email_Error);
         Summary : constant Proj.Result_Summary := Proj.Summarize (Result);
      begin
         Assert (Proj.Render (Compact) = "ERROR $.email validation.required",
                 "compact issue renders canonically");
         Assert (Summary.Issue_Count = 2 and then Summary.Error_Count = 1,
                 "summary counts");
         Assert (Summary.Validity = Res.Invalid, "summary validity");
         Assert (Proj.Compact_All (Res.Issues_By_Category
                   (Result, Iss.Category_Presence))'Length = 1,
                 "compact-all over a filtered collection");

         --  Determinism: an identical result yields an identical semantic
         --  fingerprint.
         Assert (Ada.Strings.Unbounded."="
                   (Summary.Semantic_Fingerprint,
                    Proj.Summarize (Fresh_Result).Semantic_Fingerprint),
                 "semantic fingerprint is deterministic");
      end;
   end Test_Projections;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Result: issue identity", Test_Issue_Identity'Access));
      Suite.Add_Test (Caller.Create ("Result: related paths", Test_Related_Paths'Access));
      Suite.Add_Test
        (Caller.Create ("Result: validity derivation", Test_Validity_Derivation'Access));
      Suite.Add_Test (Caller.Create ("Result: queries", Test_Result_Queries'Access));
      Suite.Add_Test
        (Caller.Create ("Result: invocation errors", Test_Invocation_Errors'Access));
      Suite.Add_Test (Caller.Create ("Result: projections", Test_Projections'Access));
   end Add_Tests;

end Result_Tests;
