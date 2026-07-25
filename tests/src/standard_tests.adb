with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Messages;
with Validation.Values;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Standard.Text;
with Validation.Standard.Numerics;
with Validation.Standard.UTF_8;

package body Standard_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Iss renames Validation.Issues;
   package Msgs renames Validation.Messages;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;
   package UTF8 renames Validation.Standard.UTF_8;
   package Values renames Validation.Values;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Res.Semantic_Validity;
   use type Ids.Message_Id;

   type Account is record
      Name : Unbounded_String;
      Age  : Integer;
   end record;

   function Get_Name (Subject : Account) return String is
     (To_String (Subject.Name));
   function Get_Age (Subject : Account) return Integer is (Subject.Age);

   package AV is new Validation.Validators (Account);
   package Name_Text is new Validation.Standard.Text (Account, AV, Get_Name);
   package Age_Num is
     new Validation.Standard.Numerics (Account, AV, Integer, Get_Age);

   F_Name : constant Ids.Field_Id := Ids.Field_Ids.Make ("name");
   F_Age  : constant Ids.Field_Id := Ids.Field_Ids.Make ("age");
   R_MinLen : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("name/minlen");

   function Build return AV.Validator is
      B : AV.Builder := AV.Start (Ids.Validator_Ids.Make ("account"));
   begin
      AV.Add (B, Name_Text.Non_Empty (F_Name, Ids.Rule_Ids.Make ("name/required")));
      AV.Add (B, Name_Text.Min_Length (F_Name, 3, R_MinLen));
      AV.Add (B, Name_Text.Valid_UTF8 (F_Name, Ids.Rule_Ids.Make ("name/utf8")));
      AV.Add (B, Age_Num.In_Range (F_Age, 0, 150, Ids.Rule_Ids.Make ("age/range")));
      AV.Add (B, Age_Num.Positive_Value (F_Age, Ids.Rule_Ids.Make ("age/positive")));
      return AV.Get_Validator (AV.Finalize (B));
   end Build;

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   --------------------------------------------------------------------------

   procedure Test_UTF8 (T : in out Fixture) is
      pragma Unreferenced (T);
      E_Acute : constant String := Character'Val (16#C3#) & Character'Val (16#A9#);
      Bad     : constant String := Character'Val (16#C3#) & Character'Val (16#28#);
      Stray   : constant String := String'(1 => Character'Val (16#80#));
   begin
      Assert (UTF8.Is_Valid ("hello"), "ascii is valid");
      Assert (UTF8.Is_Valid (E_Acute), "2-byte sequence valid");
      Assert (not UTF8.Is_Valid (Bad), "bad continuation rejected");
      Assert (not UTF8.Is_Valid (Stray), "stray continuation rejected");
      Assert (UTF8.Scalar_Count ("a" & E_Acute & "b") = 3,
              "scalar count over multibyte");
   end Test_UTF8;

   procedure Test_Text_Rules (T : in out Fixture) is
      pragma Unreferenced (T);
      V     : constant AV.Validator := Build;
      Valid : constant Account := (Name => To_Unbounded_String ("Alice"), Age => 30);
      Short : constant Account := (Name => To_Unbounded_String ("Al"), Age => 30);
   begin
      Assert (Res.Validity (AV.Validate (Valid, V, Empty_Context)) = Res.Valid,
              "valid account passes");
      declare
         R : constant Res.Result := AV.Validate (Short, V, Empty_Context);
      begin
         --  "Al" is non-empty and valid UTF-8, but shorter than 3.
         Assert (Res.Validity (R) = Res.Invalid, "short name invalid");
         Assert (Iss.Count (Res.Issues_From_Rule (R, R_MinLen)) = 1,
                 "min-length rule fires");
      end;
   end Test_Text_Rules;

   procedure Test_Numeric_Rules (T : in out Fixture) is
      pragma Unreferenced (T);
      V   : constant AV.Validator := Build;
      Bad : constant Account := (Name => To_Unbounded_String ("Bob"), Age => -5);
   begin
      declare
         R : constant Res.Result := AV.Validate (Bad, V, Empty_Context);
      begin
         --  -5 fails both In_Range (< 0) and Positive_Value (<= 0).
         Assert (Res.Error_Count (R) = 2, "both numeric rules fire");
         Assert (Iss.Count
                   (Res.Issues_From_Validator (R, AV.Id (V))) = 2,
                 "issues attributed to the validator");
      end;
   end Test_Numeric_Rules;

   procedure Test_Message_Arguments (T : in out Fixture) is
      pragma Unreferenced (T);
      V     : constant AV.Validator := Build;
      Short : constant Account := (Name => To_Unbounded_String ("Al"), Age => 30);
      R     : constant Res.Result := AV.Validate (Short, V, Empty_Context);
      Coll  : constant Iss.Issue_Collection := Res.Issues_From_Rule (R, R_MinLen);
   begin
      Assert (Iss.Count (Coll) = 1, "one min-length issue");
      declare
         M : constant Msgs.Message := Iss.Message (Iss.Element (Coll, 1));
      begin
         Assert (Msgs.Id_Of (M) = Msgs.Length_Minimum, "standard message id");
         --  The configured bound (3) is disclosed; the actual value ("Al") is
         --  NOT (excluded by default).
         Assert (Msgs.Has_Argument (M, Msgs.Arg_Minimum), "minimum argument present");
         Assert (Values.Image (Msgs.Value_At (M, 1)) = "3", "bound is 3");
         Assert (not Msgs.Has_Argument (M, Msgs.Arg_Actual),
                 "actual value not disclosed");
      end;
   end Test_Message_Arguments;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Standard: utf-8", Test_UTF8'Access));
      Suite.Add_Test (Caller.Create ("Standard: text rules", Test_Text_Rules'Access));
      Suite.Add_Test
        (Caller.Create ("Standard: numeric rules", Test_Numeric_Rules'Access));
      Suite.Add_Test
        (Caller.Create ("Standard: message arguments", Test_Message_Arguments'Access));
   end Add_Tests;

end Standard_Tests;
