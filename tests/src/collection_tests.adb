with Ada.Containers.Vectors;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Paths;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Collections;

package body Collection_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Iss renames Validation.Issues;
   package Paths renames Validation.Paths;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;

   package Caller is new AUnit.Test_Caller (Fixture);

   package Int_Vectors is new Ada.Containers.Vectors (Positive, Integer);

   type Order is record
      Lines : Int_Vectors.Vector;
   end record;

   function Get_Lines (Subject : Order) return Int_Vectors.Vector is
     (Subject.Lines);
   function Count_Lines (Collection : Int_Vectors.Vector) return Natural is
     (Natural (Collection.Length));
   function Item_Lines
     (Collection : Int_Vectors.Vector; Index : Positive) return Integer is
     (Collection (Index));

   package OV is new Validation.Validators (Order);
   package Lines_Coll is new Validation.Collections
     (Order, OV, Int_Vectors.Vector, Integer,
      Get_Lines, Count_Lines, Item_Lines);

   function Is_Positive (Element : Integer) return Boolean is (Element > 0);
   function Is_Even (Element : Integer) return Boolean is (Element mod 2 = 0);
   function Identity_Key (Element : Integer) return Integer is (Element);
   function Int_Equal (Left, Right : Integer) return Boolean is (Left = Right);
   function To_LLI (Element : Integer) return Long_Long_Integer is
     (Long_Long_Integer (Element));

   package Positive_Each is new Lines_Coll.Each_Element (Is_Positive);
   package Unique_Lines is
     new Lines_Coll.Unique (Integer, Identity_Key, Int_Equal);
   package Even_Q is new Lines_Coll.Quantifier (Is_Even);
   package Sum_Agg is new Lines_Coll.Aggregate (To_LLI);

   F_Lines : constant Ids.Field_Id := Ids.Field_Ids.Make ("lines");

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   type Int_List is array (Positive range <>) of Integer;

   function Ord (Items : Int_List) return Order is
      Result : Order;
   begin
      for Element of Items loop
         Result.Lines.Append (Element);
      end loop;
      return Result;
   end Ord;

   function Validator_With (Rule : OV.Rule) return OV.Validator is
      B : OV.Builder := OV.Start (Ids.Validator_Ids.Make ("order"));
   begin
      OV.Add (B, Rule);
      return OV.Get_Validator (OV.Finalize (B));
   end Validator_With;

   --------------------------------------------------------------------------

   procedure Test_Cardinality (T : in out Fixture) is
      pragma Unreferenced (T);
      Min_V : constant OV.Validator :=
        Validator_With
          (Lines_Coll.Min_Count (F_Lines, 1, Ids.Rule_Ids.Make ("lines/min")));
      Max_V : constant OV.Validator :=
        Validator_With
          (Lines_Coll.Max_Count (F_Lines, 3, Ids.Rule_Ids.Make ("lines/max")));
   begin
      Assert (Res.Issue_Count (OV.Validate (Ord ([1 => 5]), Min_V, Empty_Context)) = 0,
              "non-empty passes min");
      Assert (Res.Issue_Count (OV.Validate (Ord ([1 .. 0 => 0]), Min_V, Empty_Context)) = 1,
              "empty fails min-count");
      Assert (Res.Issue_Count (OV.Validate (Ord ([1, 2, 3, 4]), Max_V, Empty_Context)) = 1,
              "over-long fails max-count");
   end Test_Cardinality;

   procedure Test_Each_Element (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant OV.Validator :=
        Validator_With
          (Positive_Each.Rule (F_Lines, Ids.Rule_Ids.Make ("lines/positive")));
      R : constant Res.Result :=
        OV.Validate (Ord ([1, -2, 3]), V, Empty_Context);
   begin
      Assert (Res.Issue_Count (R) = 1, "one failing element");
      Assert (Paths.Render (Iss.Primary_Path (Res.Issue_At (R, 1)))
                = "$.lines[1]",
              "issue at the zero-based element index");
   end Test_Each_Element;

   procedure Test_Uniqueness (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant OV.Validator :=
        Validator_With
          (Unique_Lines.Rule (F_Lines, Ids.Rule_Ids.Make ("lines/unique")));
      R : constant Res.Result :=
        OV.Validate (Ord ([1, 2, 2, 3]), V, Empty_Context);
   begin
      Assert (Res.Issue_Count (R) = 1, "one duplicate after the first");
      declare
         Issue : constant Iss.Issue := Res.Issue_At (R, 1);
      begin
         Assert (Paths.Render (Iss.Primary_Path (Issue)) = "$.lines[2]",
                 "duplicate at its own index");
         Assert (Iss.Related_Path_Count (Issue) = 1
                   and then Paths.Render (Iss.Related_Path_At (Issue, 1))
                            = "$.lines[1]",
                 "related path points at the first occurrence");
      end;
   end Test_Uniqueness;

   procedure Test_Quantifier (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant OV.Validator :=
        Validator_With
          (Even_Q.At_Least (F_Lines, 1, Ids.Rule_Ids.Make ("lines/even")));
   begin
      Assert (Res.Issue_Count (OV.Validate (Ord ([1, 3, 5]), V, Empty_Context)) = 1,
              "no even element fails at-least-one");
      Assert (Res.Issue_Count (OV.Validate (Ord ([1, 2, 3]), V, Empty_Context)) = 0,
              "one even element passes");
   end Test_Quantifier;

   procedure Test_Aggregate (T : in out Fixture) is
      pragma Unreferenced (T);
      V : constant OV.Validator :=
        Validator_With
          (Sum_Agg.Sum_At_Most (F_Lines, 10, Ids.Rule_Ids.Make ("lines/sum")));
   begin
      Assert (Res.Issue_Count (OV.Validate (Ord ([5, 6]), V, Empty_Context)) = 1,
              "sum 11 exceeds 10");
      Assert (Res.Issue_Count (OV.Validate (Ord ([4, 6]), V, Empty_Context)) = 0,
              "sum 10 is within bound");
   end Test_Aggregate;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Collection: cardinality", Test_Cardinality'Access));
      Suite.Add_Test (Caller.Create ("Collection: each element", Test_Each_Element'Access));
      Suite.Add_Test (Caller.Create ("Collection: uniqueness", Test_Uniqueness'Access));
      Suite.Add_Test (Caller.Create ("Collection: quantifier", Test_Quantifier'Access));
      Suite.Add_Test (Caller.Create ("Collection: aggregate", Test_Aggregate'Access));
   end Add_Tests;

end Collection_Tests;
