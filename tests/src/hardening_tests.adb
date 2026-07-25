with AUnit.Assertions;
with AUnit.Test_Caller;

with Ada.Containers;

with Validation.Identifiers;
with Validation.Paths;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Standard.Numerics;
with Validation.Standard.UTF_8;
with Validation.Fingerprints;

package body Hardening_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Paths renames Validation.Paths;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;
   package UTF8 renames Validation.Standard.UTF_8;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Ada.Containers.Hash_Type;
   use type Paths.Path;
   use type Res.Execution_Status;
   use type Res.Semantic_Validity;
   use type Validation.Fingerprints.Fingerprint;

   --  Deterministic linear congruential generator (no runtime randomness).
   type U32 is mod 2 ** 32;
   procedure Advance (Seed : in out U32) is
   begin
      Seed := Seed * 1103515245 + 12345;
   end Advance;
   function Byte (Seed : U32) return Natural is (Natural (Seed / 65536 mod 256));

   ---------------------------------------------------------------------------
   --  Subject + validator for determinism / ownership / fault tests
   ---------------------------------------------------------------------------

   type Rec is record
      N : Integer;
   end record;

   function Get_N (Subject : Rec) return Integer is (Subject.N);

   package RV is new Validation.Validators (Rec);
   package Num is new Validation.Standard.Numerics (Rec, RV, Integer, Get_N);

   F_N   : constant Ids.Field_Id := Ids.Field_Ids.Make ("n");
   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   function Build return RV.Validator is
      B : RV.Builder := RV.Start (Ids.Validator_Ids.Make ("rec"));
   begin
      RV.Add (B, Num.Positive_Value (F_N, Ids.Rule_Ids.Make ("n/pos")));
      RV.Add (B, Num.In_Range (F_N, 1, 10, Ids.Rule_Ids.Make ("n/range")));
      return RV.Get_Validator (RV.Finalize (B));
   end Build;

   --------------------------------------------------------------------------

   procedure Test_Determinism (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant RV.Validator := Build;
      Subject : constant Rec := (N => -5);
      Baseline : constant Res.Result := RV.Validate (Subject, V, Empty_Context);
      FP : constant Validation.Fingerprints.Fingerprint :=
        Res.Semantic_Fingerprint (Baseline);
   begin
      for Iteration in 1 .. 50 loop
         declare
            R : constant Res.Result := RV.Validate (Subject, V, Empty_Context);
         begin
            Assert (Res.Issue_Count (R) = Res.Issue_Count (Baseline),
                    "issue count stable across runs");
            Assert (Res.Semantic_Fingerprint (R) = FP,
                    "semantic fingerprint stable across runs");
         end;
      end loop;
   end Test_Determinism;

   procedure Test_Path_Properties (T : in out Fixture) is
      pragma Unreferenced (T);
      Seed : U32 := 987654321;
   begin
      for Iteration in 1 .. 400 loop
         Advance (Seed);
         declare
            --  A valid field name derived deterministically from the seed.
            Name  : constant String :=
              "f" & Character'Val (Character'Pos ('a') + Byte (Seed) mod 26);
            Field : constant Ids.Field_Id := Ids.Field_Ids.Make (Name);
            Base  : constant Paths.Path :=
              Paths.Append_Index (Paths.Root, Paths.Index_Value (Byte (Seed)));
            Child : constant Paths.Path := Paths.Append_Field (Base, Field);
         begin
            --  append then parent returns the original
            Assert (Paths.Parent (Child) = Base, "parent undoes append");
            --  root prefixes every absolute path
            Assert (Paths.Is_Prefix_Of (Paths.Root, Child), "root prefixes all");
            --  equality is reflexive; equal paths hash equally
            Assert (Child = Child, "reflexive equality");
            Assert (Paths.Hash (Child)
                      = Paths.Hash (Paths.Append_Field (Base, Field)),
                    "equal paths hash equally");
            --  prefix is a proper subtree relation
            Assert (Paths.Is_In_Subtree_Of (Child, Base), "child in base subtree");
         end;
      end loop;
   end Test_Path_Properties;

   procedure Test_Result_Properties (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant RV.Validator := Build;
      R : constant Res.Result := RV.Validate ((N => -5), V, Empty_Context);
   begin
      Assert (Res.Error_Count (R) + Res.Warning_Count (R)
                + Res.Information_Count (R) = Res.Issue_Count (R),
              "severity counts partition the issue count");
      Assert
        ((Res.Validity (R) = Res.Invalid) = (Res.Error_Count (R) > 0),
         "invalid iff there is an error");
   end Test_Result_Properties;

   procedure Test_Identifier_Fuzz (T : in out Fixture) is
      pragma Unreferenced (T);
      Seed : U32 := 123456789;
   begin
      for Iteration in 1 .. 800 loop
         Advance (Seed);
         declare
            Length : constant Natural := Byte (Seed) mod 20;
            Text   : String (1 .. Length);
            Id     : Ids.Validator_Id;
            Ok     : Boolean;
         begin
            for K in Text'Range loop
               Advance (Seed);
               Text (K) := Character'Val (Byte (Seed));
            end loop;
            --  Try_Make must never raise on arbitrary bytes, and must agree
            --  with Is_Valid.
            Ok := Ids.Validator_Ids.Try_Make (Text, Id);
            Assert (Ok = Ids.Is_Valid (Text), "try_make agrees with is_valid");
         exception
            when others =>
               Assert (False, "identifier construction raised on fuzz input");
         end;
      end loop;
   end Test_Identifier_Fuzz;

   procedure Test_UTF8_Fuzz (T : in out Fixture) is
      pragma Unreferenced (T);
      Seed : U32 := 555555555;
   begin
      for Iteration in 1 .. 800 loop
         Advance (Seed);
         declare
            Length : constant Natural := Byte (Seed) mod 12;
            Text   : String (1 .. Length);
         begin
            for K in Text'Range loop
               Advance (Seed);
               Text (K) := Character'Val (Byte (Seed));
            end loop;
            if UTF8.Is_Valid (Text) then
               Assert (UTF8.Scalar_Count (Text) <= Text'Length,
                       "scalar count never exceeds byte length");
            end if;
         exception
            when others =>
               Assert (False, "UTF-8 validation raised on fuzz input");
         end;
      end loop;
   end Test_UTF8_Fuzz;

   function Faulty_Condition (Subject : Rec; Context : Ctx.Context) return Boolean;
   function Faulty_Condition
     (Subject : Rec; Context : Ctx.Context) return Boolean
   is
      pragma Unreferenced (Context);
   begin
      raise Constraint_Error;
      return Subject.N > 0;   --  unreachable; satisfies the return contract
   end Faulty_Condition;

   package Faulty is new RV.Conditional (Faulty_Condition);

   procedure Test_Condition_Fault (T : in out Fixture) is
      pragma Unreferenced (T);
      B : RV.Builder := RV.Start (Ids.Validator_Ids.Make ("rec"));
      Opts : constant RV.Execution_Options :=
        (On_Fault => RV.Convert_To_Invocation_Error, others => <>);
   begin
      RV.Add (B, Faulty.When_Applicable
                   (Num.Positive_Value (F_N, Ids.Rule_Ids.Make ("n/pos"))));
      declare
         V : constant RV.Validator := RV.Get_Validator (RV.Finalize (B));
         R : constant Res.Result := RV.Validate ((N => 5), V, Empty_Context, Opts);
      begin
         Assert (Res.Status (R) = Res.Invocation_Failed,
                 "a faulting condition converts to invocation failure");
      end;
   end Test_Condition_Fault;

   procedure Test_Ownership (T : in out Fixture) is
      pragma Unreferenced (T);
      --  The validator is built inside Build (its builder is long gone) and
      --  returned by value; validating with it must still work (finalized
      --  validators do not retain builder-local state, VAL-INV-028).
      V : constant RV.Validator := Build;
   begin
      Assert (RV.Rule_Count (V) = 2, "validator survives its builder");
      Assert (Res.Issue_Count (RV.Validate ((N => 5), V, Empty_Context)) = 0,
              "valid subject passes after builder destruction");
   end Test_Ownership;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Hardening: determinism", Test_Determinism'Access));
      Suite.Add_Test (Caller.Create ("Hardening: path properties", Test_Path_Properties'Access));
      Suite.Add_Test (Caller.Create ("Hardening: result properties", Test_Result_Properties'Access));
      Suite.Add_Test (Caller.Create ("Hardening: identifier fuzz", Test_Identifier_Fuzz'Access));
      Suite.Add_Test (Caller.Create ("Hardening: utf-8 fuzz", Test_UTF8_Fuzz'Access));
      Suite.Add_Test (Caller.Create ("Hardening: condition fault", Test_Condition_Fault'Access));
      Suite.Add_Test (Caller.Create ("Hardening: ownership", Test_Ownership'Access));
   end Add_Tests;

end Hardening_Tests;
