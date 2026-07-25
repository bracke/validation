with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Paths;
with Validation.Messages;
with Validation.Errors;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Deferred;

package body Deferred_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Iss renames Validation.Issues;
   package Paths renames Validation.Paths;
   package Msgs renames Validation.Messages;
   package Errs renames Validation.Errors;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Res.Execution_Status;
   use type Res.Semantic_Validity;
   use type Errs.Error_Code;

   package Name_Vectors is new Ada.Containers.Vectors (Positive, Unbounded_String);

   type Registration is record
      Usernames : Name_Vectors.Vector;
   end record;

   function Item_Count (Subject : Registration) return Natural is
     (Natural (Subject.Usernames.Length));
   function Request_Of
     (Subject : Registration; Index : Positive) return Unbounded_String is
     (Subject.Usernames (Index));
   function Path_Of
     (Subject : Registration; Index : Positive) return Paths.Path
   is
      pragma Unreferenced (Subject);
   begin
      return Paths.Append_Index
        (Paths.Append_Field (Paths.Root, Ids.Field_Ids.Make ("usernames")),
         Paths.Index_Value (Index - 1));
   end Path_Of;
   function Is_Available (Result : Boolean) return Boolean is (Result);
   function Always (Subject : Registration) return Boolean is
      pragma Unreferenced (Subject);
   begin
      return True;
   end Always;

   package RV is new Validation.Validators (Registration);
   package Always_Rule is new RV.Predicate_Rules (Always);

   package Unique_Check is new Validation.Deferred
     (Registration, RV, Unbounded_String, Boolean, "username.unique",
      Item_Count, Request_Of, Path_Of, Is_Available, Msgs.Value_Forbidden);

   --  "bob" is taken; every other name is available.
   function Availability (Payload : Unbounded_String) return Boolean is
     (To_String (Payload) /= "bob");

   package Sync is new Unique_Check.Synchronous (Availability);

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);
   Token         : constant String := "reg-1";

   function Validator return RV.Validator is
      B : RV.Builder := RV.Start (Ids.Validator_Ids.Make ("registration"));
   begin
      RV.Add (B, Always_Rule.Make (Ids.Rule_Ids.Make ("reg/ok"), Msgs.Required));
      return RV.Get_Validator (RV.Finalize (B));
   end Validator;

   function Reg (A, B : String) return Registration is
      Result : Registration;
   begin
      Result.Usernames.Append (To_Unbounded_String (A));
      Result.Usernames.Append (To_Unbounded_String (B));
      return Result;
   end Reg;

   --------------------------------------------------------------------------

   procedure Test_Synchronous (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant RV.Validator := Validator;
      Taken : constant Res.Result :=
        Sync.Run (Reg ("alice", "bob"), V, Empty_Context, Token);
      Free  : constant Res.Result :=
        Sync.Run (Reg ("alice", "carol"), V, Empty_Context, Token);
   begin
      Assert (Res.Status (Taken) = Res.Completed, "lifecycle completes");
      Assert (Res.Issue_Count (Taken) = 1, "the taken name is flagged");
      Assert (Paths.Render (Iss.Primary_Path (Res.Issue_At (Taken, 1)))
                = "$.usernames[1]",
              "deferred issue at the request's path");
      Assert (Res.Validity (Free) = Res.Valid, "all available -> valid");
   end Test_Synchronous;

   procedure Test_Replay_And_Order (T : in out Fixture) is
      pragma Unreferenced (T);
      V       : constant RV.Validator := Validator;
      Outcome : Res.Result;
      Cont    : Unique_Check.Continuation;
   begin
      Unique_Check.Start
        (Reg ("alice", "bob"), V, Empty_Context, Token, Outcome => Outcome,
         Cont => Cont);
      Assert (Res.Status (Outcome) = Res.Pending, "start is pending");
      Assert (Unique_Check.Request_Count (Cont) = 2, "two requests");

      --  Results supplied in REVERSE order -> identical outcome (VAL-INV-011).
      declare
         Forward : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, Token,
              [(1, True), (2, False)]);
         Reverse_Order : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, Token,
              [(2, False), (1, True)]);
      begin
         Assert (Res.Status (Forward) = Res.Completed
                   and then Res.Issue_Count (Forward) = 1,
                 "resume interprets the failing result");
         Assert (Res.Status (Reverse_Order) = Res.Completed
                   and then Res.Issue_Count (Reverse_Order) = 1,
                 "arrival order does not change the outcome");
         Assert (Paths.Render (Iss.Primary_Path (Res.Issue_At (Forward, 1)))
                   = Paths.Render (Iss.Primary_Path (Res.Issue_At (Reverse_Order, 1))),
                 "same issue path regardless of order");
      end;
   end Test_Replay_And_Order;

   procedure Test_Partial (T : in out Fixture) is
      pragma Unreferenced (T);
      V       : constant RV.Validator := Validator;
      Outcome : Res.Result;
      Cont    : Unique_Check.Continuation;
   begin
      Unique_Check.Start
        (Reg ("alice", "bob"), V, Empty_Context, Token, Outcome => Outcome,
         Cont => Cont);
      declare
         --  Only occurrence 1 supplied; occurrence 2 still pending.
         Partial : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, Token, [1 => (1, True)]);
      begin
         Assert (Res.Status (Partial) = Res.Pending,
                 "missing result keeps the outcome pending (Require_All)");
      end;
   end Test_Partial;

   procedure Test_Stale (T : in out Fixture) is
      pragma Unreferenced (T);
      V       : constant RV.Validator := Validator;
      Outcome : Res.Result;
      Cont    : Unique_Check.Continuation;
   begin
      Unique_Check.Start
        (Reg ("alice", "bob"), V, Empty_Context, Token, Outcome => Outcome,
         Cont => Cont);
      declare
         Stale : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, "other-token",
              [(1, True), (2, True)]);
      begin
         Assert (Res.Status (Stale) = Res.Invocation_Failed,
                 "different subject token -> invocation failure");
         Assert (Errs.Code_Of (Res.Invocation_Error_At (Stale, 1))
                   = Errs.Stale_Continuation,
                 "stale continuation error");
      end;
   end Test_Stale;

   procedure Test_Unknown_And_Duplicate (T : in out Fixture) is
      pragma Unreferenced (T);
      V       : constant RV.Validator := Validator;
      Outcome : Res.Result;
      Cont    : Unique_Check.Continuation;
   begin
      Unique_Check.Start
        (Reg ("alice", "bob"), V, Empty_Context, Token, Outcome => Outcome,
         Cont => Cont);
      declare
         Unknown : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, Token, [1 => (3, True)]);
         Duplicate : constant Res.Result :=
           Unique_Check.Resume
             (Cont, Reg ("alice", "bob"), V, Empty_Context, Token,
              [(1, True), (1, False)]);
      begin
         Assert (Errs.Code_Of (Res.Invocation_Error_At (Unknown, 1))
                   = Errs.Unknown_Deferred_Result,
                 "unknown result rejected");
         Assert (Errs.Code_Of (Res.Invocation_Error_At (Duplicate, 1))
                   = Errs.Duplicate_Deferred_Result,
                 "duplicate result rejected");
      end;
   end Test_Unknown_And_Duplicate;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Deferred: synchronous", Test_Synchronous'Access));
      Suite.Add_Test
        (Caller.Create ("Deferred: replay + order", Test_Replay_And_Order'Access));
      Suite.Add_Test (Caller.Create ("Deferred: partial", Test_Partial'Access));
      Suite.Add_Test (Caller.Create ("Deferred: stale", Test_Stale'Access));
      Suite.Add_Test
        (Caller.Create ("Deferred: unknown/duplicate", Test_Unknown_And_Duplicate'Access));
   end Add_Tests;

end Deferred_Tests;
