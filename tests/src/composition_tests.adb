with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Results;
with Validation.Contexts;
with Validation.Profiles;
with Validation.Validators;
with Validation.Standard.Text;
with Validation.Standard.Numerics;

package body Composition_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Iss renames Validation.Issues;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;
   package Prof renames Validation.Profiles;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Res.Semantic_Validity;
   use type Iss.Severity;

   type Account is record
      Name : Unbounded_String;
      Age  : Integer;
   end record;

   function Get_Name (Subject : Account) return String is
     (To_String (Subject.Name));
   function Get_Age (Subject : Account) return Integer is (Subject.Age);

   function Is_Adult
     (Subject : Account; Context : Ctx.Context) return Boolean;
   function Is_Adult
     (Subject : Account; Context : Ctx.Context) return Boolean is
      pragma Unreferenced (Context);
   begin
      return Subject.Age >= 18;
   end Is_Adult;

   package AV is new Validation.Validators (Account);
   package Name_Text is new Validation.Standard.Text (Account, AV, Get_Name);
   package Age_Num is
     new Validation.Standard.Numerics (Account, AV, Integer, Get_Age);
   package Adult_Cond is new AV.Conditional (Is_Adult);

   F_Name : constant Ids.Field_Id := Ids.Field_Ids.Make ("name");
   F_Age  : constant Ids.Field_Id := Ids.Field_Ids.Make ("age");
   R_Req  : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("name/required");
   R_Min  : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("name/minlen");
   R_Age  : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("age/range");
   G_Strict : constant Ids.Rule_Group_Id := Ids.Rule_Group_Ids.Make ("strict");
   G_Basic  : constant Ids.Rule_Group_Id := Ids.Rule_Group_Ids.Make ("basic");

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   function Profile_Activating (Group : Ids.Rule_Group_Id; Name : String)
     return Prof.Profile_Set is
      B : Prof.Profile_Builder := Prof.Begin_Profile (Ids.Profile_Ids.Make (Name));
   begin
      Prof.Include_Group (B, Group);
      return Prof.Add (Prof.Empty_Set, Prof.Get_Profile (Prof.Finalize (B)));
   end Profile_Activating;

   --------------------------------------------------------------------------

   procedure Test_Prerequisite (T : in out Fixture) is
      pragma Unreferenced (T);
      B : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("acct"));
   begin
      AV.Add (B, Name_Text.Non_Empty (F_Name, R_Req));
      AV.Add (B, AV.Requires (Name_Text.Min_Length (F_Name, 3, R_Min), R_Req));
      declare
         V : constant AV.Validator := AV.Get_Validator (AV.Finalize (B));
         Empty_Name : constant Account := (To_Unbounded_String (""), 30);
         Short_Name : constant Account := (To_Unbounded_String ("Al"), 30);
         R1 : constant Res.Result := AV.Validate (Empty_Name, V, Empty_Context);
         R2 : constant Res.Result := AV.Validate (Short_Name, V, Empty_Context);
      begin
         --  Required fails -> min-length prerequisite unmet -> skipped.
         Assert (Iss.Count (Res.Issues_From_Rule (R1, R_Min)) = 0,
                 "min-length skipped when required failed");
         Assert (Res.Issue_Count (R1) = 1, "only the required issue");
         --  Required passes -> min-length runs and fails on \"Al\".
         Assert (Iss.Count (Res.Issues_From_Rule (R2, R_Min)) = 1,
                 "min-length runs when required passed");
      end;
   end Test_Prerequisite;

   procedure Test_Group_Filtering (T : in out Fixture) is
      pragma Unreferenced (T);
      B : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("acct"));
   begin
      AV.Add (B, Name_Text.Non_Empty (F_Name, R_Req));
      AV.Add (B, AV.In_Group (Age_Num.In_Range (F_Age, 0, 150, R_Age), G_Strict));
      declare
         V : constant AV.Validator := AV.Get_Validator (AV.Finalize (B));
         Bad : constant Account := (To_Unbounded_String ("Bob"), -5);
         Basic_Opts : constant AV.Execution_Options :=
           (Profiles => Profile_Activating (G_Basic, "basic"), others => <>);
         Strict_Opts : constant AV.Execution_Options :=
           (Profiles => Profile_Activating (G_Strict, "strict"), others => <>);
      begin
         --  Basic profile does not activate the strict group -> age rule skipped.
         Assert (Iss.Count
                   (Res.Issues_From_Rule
                      (AV.Validate (Bad, V, Empty_Context, Basic_Opts), R_Age))
                   = 0,
                 "labeled rule skipped when its group is inactive");
         --  Strict profile activates it -> age rule runs.
         Assert (Iss.Count
                   (Res.Issues_From_Rule
                      (AV.Validate (Bad, V, Empty_Context, Strict_Opts), R_Age))
                   = 1,
                 "labeled rule runs when its group is active");
      end;
   end Test_Group_Filtering;

   procedure Test_Severity_Override (T : in out Fixture) is
      pragma Unreferenced (T);
      B  : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("acct"));
      PB : Prof.Profile_Builder :=
        Prof.Begin_Profile (Ids.Profile_Ids.Make ("lenient"));
   begin
      AV.Add (B, Name_Text.Non_Empty (F_Name, R_Req));
      Prof.Override_Severity (PB, R_Req, Iss.Warning);
      declare
         V : constant AV.Validator := AV.Get_Validator (AV.Finalize (B));
         Opts : constant AV.Execution_Options :=
           (Profiles =>
              Prof.Add (Prof.Empty_Set, Prof.Get_Profile (Prof.Finalize (PB))),
            others => <>);
         Empty_Name : constant Account := (To_Unbounded_String (""), 30);
         R : constant Res.Result :=
           AV.Validate (Empty_Name, V, Empty_Context, Opts);
      begin
         Assert (Res.Error_Count (R) = 0, "error demoted by profile override");
         Assert (Res.Warning_Count (R) = 1, "now a warning");
         Assert (Res.Validity (R) = Res.Valid_With_Nonerrors,
                 "valid with non-errors after override");
      end;
   end Test_Severity_Override;

   procedure Test_Condition (T : in out Fixture) is
      pragma Unreferenced (T);
      B : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("acct"));
   begin
      AV.Add (B, Adult_Cond.When_Applicable
                   (Name_Text.Min_Length (F_Name, 3, R_Min)));
      declare
         V : constant AV.Validator := AV.Get_Validator (AV.Finalize (B));
         Minor : constant Account := (To_Unbounded_String ("Al"), 10);
         Adult : constant Account := (To_Unbounded_String ("Al"), 30);
      begin
         Assert (Res.Issue_Count (AV.Validate (Minor, V, Empty_Context)) = 0,
                 "rule inapplicable when condition false");
         Assert (Res.Issue_Count (AV.Validate (Adult, V, Empty_Context)) = 1,
                 "rule applies when condition true");
      end;
   end Test_Condition;

   procedure Test_Composition (T : in out Fixture) is
      pragma Unreferenced (T);
      B : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("base"));
   begin
      AV.Add (B, Name_Text.Non_Empty (F_Name, R_Req));
      AV.Add (B, Name_Text.Min_Length (F_Name, 3, R_Min));
      declare
         Base : constant AV.Validator := AV.Get_Validator (AV.Finalize (B));
         EB   : AV.Builder := AV.Extend (Base, Ids.Validator_Ids.Make ("derived"));
      begin
         AV.Disable (EB, R_Min);
         declare
            Derived : constant AV.Validator := AV.Get_Validator (AV.Finalize (EB));
            Empty_Name : constant Account := (To_Unbounded_String (""), 30);
            R : constant Res.Result :=
              AV.Validate (Empty_Name, Derived, Empty_Context);
         begin
            Assert (AV.Rule_Count (Base) = 2, "base has two rules");
            Assert (AV.Rule_Count (Derived) = 1, "derived dropped one rule");
            Assert (Iss.Count (Res.Issues_From_Rule (R, R_Min)) = 0,
                    "disabled rule does not fire");
            Assert (Res.Issue_Count (R) = 1, "remaining rule still fires");
         end;
      end;
   end Test_Composition;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Compose: prerequisite", Test_Prerequisite'Access));
      Suite.Add_Test (Caller.Create ("Compose: group filtering", Test_Group_Filtering'Access));
      Suite.Add_Test
        (Caller.Create ("Compose: severity override", Test_Severity_Override'Access));
      Suite.Add_Test (Caller.Create ("Compose: condition", Test_Condition'Access));
      Suite.Add_Test (Caller.Create ("Compose: extend/disable", Test_Composition'Access));
   end Add_Tests;

end Composition_Tests;
