with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Validation.Identifiers;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Standard.Text;
with Validation.Standard.Numerics;
with Validation.Projections;

--  A complete, runnable quickstart: define a subject, build a validator from
--  standard validators, validate a good and a bad value, and print the compact
--  projection of the result.
procedure Quickstart is

   package Ids renames Validation.Identifiers;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;
   package Proj renames Validation.Projections;

   --  1. The subject: a customer registration.
   type Customer is record
      Email : Unbounded_String;
      Age   : Integer;
   end record;

   function Get_Email (Subject : Customer) return String is
     (To_String (Subject.Email));
   function Get_Age (Subject : Customer) return Integer is (Subject.Age);

   --  2. Instantiate the engine and the standard-validator families.
   package CV is new Validation.Validators (Customer);
   package Email_Text is new Validation.Standard.Text (Customer, CV, Get_Email);
   package Age_Num is
     new Validation.Standard.Numerics (Customer, CV, Integer, Get_Age);

   F_Email : constant Ids.Field_Id := Ids.Field_Ids.Make ("email");
   F_Age   : constant Ids.Field_Id := Ids.Field_Ids.Make ("age");

   --  3. Build and finalize the validator.
   function Customer_Validator return CV.Validator is
      B : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("customer"));
   begin
      CV.Add (B, Email_Text.Non_Empty (F_Email, Ids.Rule_Ids.Make ("email/required")));
      CV.Add (B, Email_Text.Max_Length (F_Email, 254, Ids.Rule_Ids.Make ("email/maxlen")));
      CV.Add (B, Age_Num.In_Range (F_Age, 0, 130, Ids.Rule_Ids.Make ("age/range")));
      return CV.Get_Validator (CV.Finalize (B));
   end Customer_Validator;

   Validator : constant CV.Validator := Customer_Validator;
   Context   : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   procedure Report (Label : String; Subject : Customer) is
      Result  : constant Res.Result := CV.Validate (Subject, Validator, Context);
      Summary : constant Proj.Result_Summary := Proj.Summarize (Result);
   begin
      Put_Line (Label & ":");
      Put_Line ("  validity : " & Res.Semantic_Validity'Image (Summary.Validity));
      Put_Line ("  issues   :" & Natural'Image (Summary.Issue_Count));
      for Compact of Proj.Canonical_Order
        (Res.Issues_From_Validator (Result, CV.Id (Validator)))
      loop
         Put_Line ("    - " & Proj.Render (Compact));
      end loop;
      New_Line;
   end Report;

begin
   Report ("valid customer",
           (Email => To_Unbounded_String ("a@b.example"), Age => 30));
   Report ("invalid customer",
           (Email => Null_Unbounded_String, Age => 200));
end Quickstart;
