with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Phases;
with Validation.Issues;
with Validation.Messages;
with Validation.Errors;
with Validation.Results;
with Validation.Contexts;
with Validation.Fingerprints;
with Validation.Validators;

package body Engine_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Msgs renames Validation.Messages;
   package Iss renames Validation.Issues;
   package Res renames Validation.Results;
   package Errs renames Validation.Errors;
   package Ctx renames Validation.Contexts;
   package FP renames Validation.Fingerprints;
   use Validation.Phases;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Res.Execution_Status;
   use type Res.Semantic_Validity;
   use type Iss.Severity;
   use type Errs.Error_Code;
   use type FP.Fingerprint;
   use type Ids.Rule_Id;

   --  Application-defined subject.
   type Customer is record
      Email    : Unbounded_String;
      Age      : Integer;
      Accepted : Boolean;
   end record;

   package CV is new Validation.Validators (Customer);

   --  Rule logic.
   function Get_Email (Subject : Customer) return Unbounded_String is
     (Subject.Email);
   function Nonempty (Value : Unbounded_String) return Boolean is
     (Length (Value) > 0);
   function Terms_Ok (Subject : Customer) return Boolean is (Subject.Accepted);

   procedure Check_Age
     (Subject : Customer;
      Context : Ctx.Context;
      Output  : in out CV.Rule_Output)
   is
      pragma Unreferenced (Context);
   begin
      if Subject.Age < 18 then
         CV.Add_Issue_At_Field
           (Output, Ids.Field_Ids.Make ("age"), Iss.Warning,
            Iss.Category_Range, Msgs.Make (Msgs.Minimum));
      end if;
   end Check_Age;

   procedure Boom
     (Subject : Customer;
      Context : Ctx.Context;
      Output  : in out CV.Rule_Output)
   is
      pragma Unreferenced (Subject, Context, Output);
   begin
      raise Constraint_Error;
   end Boom;

   package Email_Rule is new CV.Field_Rules (Unbounded_String, Get_Email, Nonempty);
   package Terms_Rule is new CV.Predicate_Rules (Terms_Ok);
   package Age_Rule is new CV.Custom_Rules (Check_Age);
   package Boom_Rule is new CV.Custom_Rules (Boom);

   R_Email : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("email/required");
   R_Terms : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("terms/required");
   R_Age   : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("age/minimum");

   function Build_Validator return CV.Validator is
      B : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("customer"));
   begin
      --  Declared: email (Value), terms (Presence), age (Value). Presence runs
      --  before Value regardless of declaration order.
      CV.Add (B, Email_Rule.Make
                   (Ids.Field_Ids.Make ("email"), R_Email, Msgs.Required,
                    Phase => Phase_Value));
      CV.Add (B, Terms_Rule.Make
                   (R_Terms, Msgs.Required, Phase => Phase_Presence));
      CV.Add (B, Age_Rule.Make (R_Age, Phase => Phase_Value));
      return CV.Get_Validator (CV.Finalize (B));
   end Build_Validator;

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   Valid_Customer : constant Customer :=
     (Email => To_Unbounded_String ("a@b.c"), Age => 30, Accepted => True);
   Invalid_Customer : constant Customer :=
     (Email => Null_Unbounded_String, Age => 15, Accepted => False);

   --------------------------------------------------------------------------

   procedure Test_Valid_Subject (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant CV.Validator := Build_Validator;
      R : constant Res.Result :=
        CV.Validate (Valid_Customer, V, Empty_Context);
   begin
      Assert (Res.Status (R) = Res.Completed, "completed");
      Assert (Res.Validity (R) = Res.Valid, "valid subject has no issues");
      Assert (Res.Issue_Count (R) = 0, "no issues");
   end Test_Valid_Subject;

   procedure Test_Invalid_Subject (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant CV.Validator := Build_Validator;
      R : constant Res.Result :=
        CV.Validate (Invalid_Customer, V, Empty_Context);
   begin
      Assert (Res.Status (R) = Res.Completed, "completed (accumulate all)");
      Assert (Res.Validity (R) = Res.Invalid, "invalid (has errors)");
      Assert (Res.Issue_Count (R) = 3, "three issues");
      Assert (Res.Error_Count (R) = 2 and then Res.Warning_Count (R) = 1,
              "two errors (email, terms) + one warning (age)");
   end Test_Invalid_Subject;

   procedure Test_Phase_Order (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant CV.Validator := Build_Validator;
      R : constant Res.Result :=
        CV.Validate (Invalid_Customer, V, Empty_Context);
   begin
      --  Terms is a Presence-phase rule declared AFTER the Value-phase email
      --  rule, yet it executes first: its issue is ordinal 1.
      Assert (Iss.Rule (Res.Issue_At (R, 1)) = R_Terms,
              "presence phase runs before value phase");
      Assert (Iss.Ordinal (Res.Issue_At (R, 1)) = 1, "first ordinal");
   end Test_Phase_Order;

   procedure Test_Stop_On_First_Error (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant CV.Validator := Build_Validator;
      Opts : constant CV.Execution_Options :=
        (Policy => CV.Stop_On_First_Error, others => <>);
      R : constant Res.Result :=
        CV.Validate (Invalid_Customer, V, Empty_Context, Opts);
   begin
      Assert (Res.Status (R) = Res.Stopped, "stopped on first error");
      Assert (Res.Issue_Count (R) = 1, "only the first error");
      Assert (Res.Validity (R) = Res.Invalid, "still invalid");
   end Test_Stop_On_First_Error;

   procedure Test_Finalize_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      --  Duplicate rule id.
      Dup : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("dup"));
      --  Empty validator id.
      Emp : constant CV.Builder := CV.Start (Ids.Validator_Ids.Null_Id);
   begin
      CV.Add (Dup, Terms_Rule.Make (R_Terms, Msgs.Required));
      CV.Add (Dup, Terms_Rule.Make (R_Terms, Msgs.Not_Blank));
      declare
         F : constant CV.Finalization := CV.Finalize (Dup);
      begin
         Assert (not CV.Is_Success (F), "duplicate rule id fails finalize");
         Assert (Errs.Code_Of (CV.Error_At (F, 1)) = Errs.Duplicate_Rule_Id,
                 "duplicate rule id reported");
      end;
      declare
         F : constant CV.Finalization := CV.Finalize (Emp);
      begin
         Assert (not CV.Is_Success (F), "empty validator id fails finalize");
         Assert (Errs.Code_Of (CV.Error_At (F, 1)) = Errs.Empty_Validator_Id,
                 "empty validator id reported");
      end;
   end Test_Finalize_Errors;

   procedure Test_Callback_Fault (T : in out Fixture) is
      pragma Unreferenced (T);
      B : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("faulty"));
      Opts : constant CV.Execution_Options :=
        (On_Fault => CV.Convert_To_Invocation_Error, others => <>);
   begin
      CV.Add (B, Boom_Rule.Make (Ids.Rule_Ids.Make ("boom")));
      declare
         V : constant CV.Validator := CV.Get_Validator (CV.Finalize (B));
         R : constant Res.Result :=
           CV.Validate (Valid_Customer, V, Empty_Context, Opts);
      begin
         Assert (Res.Status (R) = Res.Invocation_Failed,
                 "callback fault converts to invocation failure");
         Assert (Res.Has_Invocation_Failure (R), "invocation failure flagged");
         Assert (Errs.Code_Of (Res.Invocation_Error_At (R, 1))
                   = Errs.Callback_Fault,
                 "callback fault error");
      end;
   end Test_Callback_Fault;

   procedure Test_Fingerprint (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (CV.Fingerprint (Build_Validator) = CV.Fingerprint (Build_Validator),
              "validator fingerprint is deterministic");
      Assert (CV.Rule_Count (Build_Validator) = 3, "three rules");
   end Test_Fingerprint;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Engine: valid subject", Test_Valid_Subject'Access));
      Suite.Add_Test (Caller.Create ("Engine: invalid subject", Test_Invalid_Subject'Access));
      Suite.Add_Test (Caller.Create ("Engine: phase order", Test_Phase_Order'Access));
      Suite.Add_Test
        (Caller.Create ("Engine: stop on first error", Test_Stop_On_First_Error'Access));
      Suite.Add_Test (Caller.Create ("Engine: finalize errors", Test_Finalize_Errors'Access));
      Suite.Add_Test (Caller.Create ("Engine: callback fault", Test_Callback_Fault'Access));
      Suite.Add_Test (Caller.Create ("Engine: fingerprint", Test_Fingerprint'Access));
   end Add_Tests;

end Engine_Tests;
