with AUnit.Assertions;
with AUnit.Test_Caller;

with Proto_Capabilities;
with Proto_Rule_Nodes;

package body Proto_Tests is

   use AUnit.Assertions;

   package Caller is new AUnit.Test_Caller (Fixture);

   --------------------------------------------------------------------------
   --  Capability prototype
   --------------------------------------------------------------------------

   package PC renames Proto_Capabilities;
   use type PC.Add_Result;

   --  Two UNRELATED value types stored side by side.
   type Locale_Code is record
      Code : String (1 .. 2);
   end record;

   package Cap_Count is new PC.Capability (Integer, "op.count", 1);
   package Cap_Locale is new PC.Capability (Locale_Code, "locale", 1);
   --  Same id as Cap_Count but a different schema version: retrieval through
   --  this instance must report "not found" (incompatible, never coerced).
   package Cap_Count_V2 is new PC.Capability (Integer, "op.count", 2);
   package Cap_Empty is new PC.Capability (Integer, "", 1);

   procedure Test_Capability_Roundtrip (T : in out Fixture) is
      pragma Unreferenced (T);
      B : PC.Builder := PC.New_Builder;
      R : PC.Add_Result;
   begin
      Cap_Count.Put (B, 42, R);
      Assert (R = PC.Added, "count added");
      Cap_Locale.Put (B, (Code => "da"), R);
      Assert (R = PC.Added, "locale added");

      declare
         C     : constant PC.Container := PC.Freeze (B);
         N     : Integer;
         L     : Locale_Code;
         Found : Boolean;
      begin
         Assert (PC.Cardinality (C) = 2, "two capabilities");
         Assert (Cap_Count.Present (C), "count present");

         Cap_Count.Get (C, N, Found);
         Assert (Found and then N = 42, "typed integer round-trips");

         Cap_Locale.Get (C, L, Found);
         Assert (Found and then L.Code = "da", "typed record round-trips");
      end;
   end Test_Capability_Roundtrip;

   procedure Test_Capability_Rejections (T : in out Fixture) is
      pragma Unreferenced (T);
      B : PC.Builder := PC.New_Builder;
      R : PC.Add_Result;
   begin
      Cap_Count.Put (B, 1, R);
      Assert (R = PC.Added, "first add ok");
      Cap_Count.Put (B, 2, R);
      Assert (R = PC.Duplicate_Capability, "duplicate id rejected");

      Cap_Empty.Put (B, 9, R);
      Assert (R = PC.Empty_Capability_Id, "empty id rejected");

      declare
         C     : constant PC.Container := PC.Freeze (B);
         N     : Integer;
         Found : Boolean;
      begin
         --  Schema-version mismatch: same id, different version -> not found.
         Cap_Count_V2.Get (C, N, Found);
         Assert (not Found, "schema-version mismatch is not found");
         Assert (not Cap_Count_V2.Present (C), "mismatched version absent");
      end;
   end Test_Capability_Rejections;

   --------------------------------------------------------------------------
   --  Rule-node (callback storage) prototype
   --------------------------------------------------------------------------

   package Int_Rules is new Proto_Rule_Nodes (Integer);

   function Is_Positive (Subject : Integer) return Boolean is (Subject > 0);
   function Is_Even (Subject : Integer) return Boolean is (Subject mod 2 = 0);

   package R_Pos is new Int_Rules.Predicate_Rule (Is_Positive, "num.positive");
   package R_Even is new Int_Rules.Predicate_Rule (Is_Even, "num.even");

   function Message_Of (O : Int_Rules.Outcome) return String is
     (O.Message (1 .. O.Length));

   procedure Test_Rule_Nodes (T : in out Fixture) is
      pragma Unreferenced (T);
      Set : Int_Rules.Rule_Set := Int_Rules.Empty_Set;
   begin
      Set := Int_Rules.Add (Set, R_Pos.Make);
      Set := Int_Rules.Add (Set, R_Even.Make);
      Assert (Int_Rules.Length (Set) = 2, "two rules stored");

      declare
         Ok : constant Int_Rules.Outcome := Int_Rules.Evaluate_All (Set, 4);
      begin
         Assert (Ok.Passed, "4 passes both rules");
      end;

      declare
         Bad : constant Int_Rules.Outcome := Int_Rules.Evaluate_All (Set, -2);
      begin
         Assert (not Bad.Passed, "-2 fails");
         Assert (Message_Of (Bad) = "num.positive",
                 "first failing rule (declaration order) reported");
      end;

      declare
         Bad : constant Int_Rules.Outcome := Int_Rules.Evaluate_All (Set, 3);
      begin
         Assert (not Bad.Passed, "3 fails evenness");
         Assert (Message_Of (Bad) = "num.even", "even rule reported");
      end;

      declare
         Empty : constant Int_Rules.Outcome :=
           Int_Rules.Evaluate_All (Int_Rules.Empty_Set, 7);
      begin
         Assert (Empty.Passed, "empty set vacuously passes");
      end;
   end Test_Rule_Nodes;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create
           ("Proto: capability typed round-trip",
            Test_Capability_Roundtrip'Access));
      Suite.Add_Test
        (Caller.Create
           ("Proto: capability rejections", Test_Capability_Rejections'Access));
      Suite.Add_Test
        (Caller.Create ("Proto: rule-node callbacks", Test_Rule_Nodes'Access));
   end Add_Tests;

end Proto_Tests;
