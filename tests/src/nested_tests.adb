with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Paths;
with Validation.Results;
with Validation.Contexts;
with Validation.Validators;
with Validation.Standard.Text;
with Validation.Nested;
with Validation.Recursive;

package body Nested_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Iss renames Validation.Issues;
   package Paths renames Validation.Paths;
   package Res renames Validation.Results;
   package Ctx renames Validation.Contexts;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Res.Execution_Status;
   use type Ids.Rule_Id;

   Empty_Context : constant Ctx.Context := Ctx.Freeze (Ctx.New_Builder);

   ---------------------------------------------------------------------------
   --  Nested + optional
   ---------------------------------------------------------------------------

   type Address is record
      Postcode : Unbounded_String;
   end record;

   type Person is record
      Name : Unbounded_String;
      Home : Address;
   end record;

   type Contact is record
      Has_Addr : Boolean;
      Addr     : Address;
   end record;

   function Get_Postcode (Subject : Address) return String is
     (To_String (Subject.Postcode));
   function Get_Home (Subject : Person) return Address is (Subject.Home);
   function Get_Addr (Subject : Contact) return Address is (Subject.Addr);
   function Get_Name (Subject : Person) return String is
     (To_String (Subject.Name));
   function Has_Addr (Subject : Contact) return Boolean is (Subject.Has_Addr);

   package AddrV is new Validation.Validators (Address);
   package Addr_Text is new Validation.Standard.Text (Address, AddrV, Get_Postcode);
   package PersonV is new Validation.Validators (Person);
   package Person_Text is new Validation.Standard.Text (Person, PersonV, Get_Name);
   package ContactV is new Validation.Validators (Contact);

   package Home_Nested is
     new Validation.Nested (Person, PersonV, Address, AddrV, Get_Home);
   package Addr_Nested is
     new Validation.Nested (Contact, ContactV, Address, AddrV, Get_Addr);
   package Addr_Opt is new Addr_Nested.Optional (Has_Addr);

   function Address_Validator return AddrV.Validator is
      B : AddrV.Builder := AddrV.Start (Ids.Validator_Ids.Make ("address"));
   begin
      AddrV.Add (B, Addr_Text.Non_Empty
                      (Ids.Field_Ids.Make ("postcode"),
                       Ids.Rule_Ids.Make ("postcode/req")));
      return AddrV.Get_Validator (AddrV.Finalize (B));
   end Address_Validator;

   procedure Test_Nested (T : in out Fixture) is
      pragma Unreferenced (T);
      B : PersonV.Builder := PersonV.Start (Ids.Validator_Ids.Make ("person"));
   begin
      PersonV.Add (B, Person_Text.Non_Empty
                        (Ids.Field_Ids.Make ("name"),
                         Ids.Rule_Ids.Make ("name/req")));
      PersonV.Add (B, Home_Nested.Rule
                        (Ids.Field_Ids.Make ("address"),
                         Ids.Rule_Ids.Make ("home/nested"), Address_Validator));
      declare
         V : constant PersonV.Validator := PersonV.Get_Validator (PersonV.Finalize (B));
         Bad : constant Person :=
           (Name => To_Unbounded_String ("Bob"),
            Home => (Postcode => Null_Unbounded_String));
         R : constant Res.Result := PersonV.Validate (Bad, V, Empty_Context);
      begin
         Assert (Res.Issue_Count (R) = 1, "one nested issue");
         Assert (Paths.Render (Iss.Primary_Path (Res.Issue_At (R, 1)))
                   = "$.address.postcode",
                 "nested issue rebased under the field path");
         Assert (Ids.Rule_Ids."=" (Iss.Rule (Res.Issue_At (R, 1)),
                                   Ids.Rule_Ids.Make ("postcode/req")),
                 "nested rule identity preserved");
      end;
   end Test_Nested;

   procedure Test_Optional (T : in out Fixture) is
      pragma Unreferenced (T);
      B : ContactV.Builder := ContactV.Start (Ids.Validator_Ids.Make ("contact"));
   begin
      ContactV.Add (B, Addr_Opt.Rule
                         (Ids.Field_Ids.Make ("address"),
                          Ids.Rule_Ids.Make ("addr/opt"), Address_Validator,
                          Required => True));
      declare
         V : constant ContactV.Validator := ContactV.Get_Validator (ContactV.Finalize (B));
         Absent : constant Contact :=
           (Has_Addr => False, Addr => (Postcode => Null_Unbounded_String));
         Present_Bad : constant Contact :=
           (Has_Addr => True, Addr => (Postcode => Null_Unbounded_String));
         Present_Ok : constant Contact :=
           (Has_Addr => True, Addr => (Postcode => To_Unbounded_String ("123")));
         R_Absent : constant Res.Result :=
           ContactV.Validate (Absent, V, Empty_Context);
      begin
         Assert (Res.Issue_Count (R_Absent) = 1
                   and then Paths.Render
                     (Iss.Primary_Path (Res.Issue_At (R_Absent, 1))) = "$.address",
                 "absent required -> presence issue at the field");
         Assert (Res.Issue_Count (ContactV.Validate (Present_Bad, V, Empty_Context)) = 1,
                 "present but invalid -> nested runs");
         Assert (Res.Issue_Count (ContactV.Validate (Present_Ok, V, Empty_Context)) = 0,
                 "present and valid -> no issues");
      end;
   end Test_Optional;

   ---------------------------------------------------------------------------
   --  Recursive
   ---------------------------------------------------------------------------

   type Tree_Node;
   type Tree_Access is access Tree_Node;
   package Child_Vectors is new Ada.Containers.Vectors (Positive, Tree_Access);
   type Tree_Node is record
      Name     : Unbounded_String;
      Node_Id  : Integer;
      Children : Child_Vectors.Vector;
   end record;

   function Node_Name (Node : Tree_Access) return String is
     (To_String (Node.Name));
   function Node_Identity (Node : Tree_Access) return String is
     (Integer'Image (Node.Node_Id));
   function Child_Count (Node : Tree_Access) return Natural is
     (Natural (Node.Children.Length));
   function Get_Child (Node : Tree_Access; Index : Positive) return Tree_Access is
     (Node.Children (Index));

   package TreeV is new Validation.Validators (Tree_Access);
   package Tree_Text is new Validation.Standard.Text (Tree_Access, TreeV, Node_Name);
   package Tree_Rec is new Validation.Recursive
     (Tree_Access, TreeV, Child_Count, Get_Child, Node_Identity,
      Children_Field => Ids.Field_Ids.Make ("children"));

   function Tree_Validator return TreeV.Validator is
      B : TreeV.Builder := TreeV.Start (Ids.Validator_Ids.Make ("tree"));
   begin
      TreeV.Add (B, Tree_Text.Non_Empty
                      (Ids.Field_Ids.Make ("name"),
                       Ids.Rule_Ids.Make ("name/req")));
      return TreeV.Get_Validator (TreeV.Finalize (B));
   end Tree_Validator;

   function New_Node (Name : String; Id : Integer) return Tree_Access is
     (new Tree_Node'(To_Unbounded_String (Name), Id, Child_Vectors.Empty_Vector));

   procedure Test_Recursive_Cycle (T : in out Fixture) is
      pragma Unreferenced (T);
      A : constant Tree_Access := New_Node ("a", 1);
      C : constant Tree_Access := New_Node ("b", 2);
   begin
      A.Children.Append (C);
      C.Children.Append (A);   --  cycle: a -> b -> a
      declare
         R : constant Res.Result :=
           Tree_Rec.Validate_Tree (A, Tree_Validator, Empty_Context);
      begin
         Assert (Res.Status (R) = Res.Completed, "cycle reported, not failed");
         Assert (Res.Issue_Count (R) = 1, "one cycle issue");
         Assert (Ids.Rule_Ids."=" (Iss.Rule (Res.Issue_At (R, 1)),
                                   Ids.Rule_Ids.Make ("graph/cycle")),
                 "graph.cycle rule");
         Assert (Iss.Related_Path_Count (Res.Issue_At (R, 1)) = 1
                   and then Paths.Render
                     (Iss.Related_Path_At (Res.Issue_At (R, 1), 1)) = "$",
                 "related path points at the first occurrence (root)");
      end;

      declare
         R : constant Res.Result :=
           Tree_Rec.Validate_Tree
             (A, Tree_Validator, Empty_Context,
              On_Cycle => Tree_Rec.Skip_Silently);
      begin
         Assert (Res.Issue_Count (R) = 0, "skip-silently drops the cycle issue");
      end;
   end Test_Recursive_Cycle;

   procedure Test_Recursive_Depth (T : in out Fixture) is
      pragma Unreferenced (T);
      A : constant Tree_Access := New_Node ("a", 1);
      C : constant Tree_Access := New_Node ("b", 2);
      D : constant Tree_Access := New_Node ("c", 3);
   begin
      A.Children.Append (C);
      C.Children.Append (D);   --  a -> b -> c, depth 3
      declare
         R : constant Res.Result :=
           Tree_Rec.Validate_Tree
             (A, Tree_Validator, Empty_Context, Max_Depth => 2);
      begin
         Assert (Res.Status (R) = Res.Incomplete,
                 "depth limit yields controlled incompleteness");
         Assert (Res.Incompleteness_Count (R) = 1, "one incompleteness note");
      end;
   end Test_Recursive_Depth;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Nested: nested object", Test_Nested'Access));
      Suite.Add_Test (Caller.Create ("Nested: optional presence", Test_Optional'Access));
      Suite.Add_Test
        (Caller.Create ("Nested: recursive cycle", Test_Recursive_Cycle'Access));
      Suite.Add_Test
        (Caller.Create ("Nested: recursive depth limit", Test_Recursive_Depth'Access));
   end Add_Tests;

end Nested_Tests;
