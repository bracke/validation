with Ada.Containers;

with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Versions;
with Validation.Outcomes;
with Validation.Paths;
with Validation.Values;
with Validation.Messages;
with Validation.Metadata;
with Validation.Source_References;
with Validation.Fingerprints;

package body Foundation_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Paths renames Validation.Paths;
   package Values renames Validation.Values;
   package Vers renames Validation.Versions;
   package Msgs renames Validation.Messages;
   package Meta renames Validation.Metadata;
   package SRef renames Validation.Source_References;
   package FP renames Validation.Fingerprints;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Ada.Containers.Hash_Type;
   use type Ids.Validator_Ids.Id;
   use type Paths.Path;
   use type Paths.Segment_Kind;
   use type Vers.Semantic_Version;
   use type Values.Value;
   use type Values.Value_Kind;
   use type Values.Real_Class;

   --------------------------------------------------------------------------

   procedure Test_Identifiers (T : in out Fixture) is
      pragma Unreferenced (T);
      A, B : Ids.Validator_Id;
      Ok   : Boolean;
   begin
      Assert (Ids.Is_Valid ("validator.login/step-1"), "valid id accepted");
      Assert (not Ids.Is_Valid (""), "empty rejected");
      Assert (not Ids.Is_Valid (".leading"), "leading dot rejected");
      Assert (not Ids.Is_Valid ("has space"), "space rejected");
      Assert (not Ids.Is_Valid ("bad" & Character'Val (9)), "tab rejected");

      A := Ids.Validator_Ids.Make ("customer.email");
      Assert (Ids.Validator_Ids.Image (A) = "customer.email", "image round-trips");
      Assert (Ids.Validator_Ids.Length (A) = 14, "length");

      Ok := Ids.Validator_Ids.Try_Make ("in valid", B);
      Assert (not Ok and then Ids.Validator_Ids.Is_Null (B),
              "try_make fails on invalid");

      Ok := Ids.Validator_Ids.Try_Make ("customer.email", B);
      Assert (Ok and then A = B, "equal ids compare equal");
      Assert (Ids.Validator_Ids.Hash (A) = Ids.Validator_Ids.Hash (B),
              "equal ids hash equally");
   end Test_Identifiers;

   --------------------------------------------------------------------------

   procedure Test_Versions (T : in out Fixture) is
      pragma Unreferenced (T);
      V1 : constant Vers.Semantic_Version := (0, 1, 0);
      V2 : constant Vers.Semantic_Version := (0, 2, 0);
      V3 : constant Vers.Semantic_Version := (1, 0, 0);
   begin
      Assert (Vers.Image (V1) = "0.1.0", "image");
      Assert (V1 < V2 and then V2 < V3, "ordering across components");
      Assert (Vers."<=" (V1, V1), "reflexive <=");
   end Test_Versions;

   --------------------------------------------------------------------------

   package Int_Outcomes is new Validation.Outcomes (Integer, Integer);

   procedure Test_Outcomes (T : in out Fixture) is
      pragma Unreferenced (T);
      S : constant Int_Outcomes.Outcome := Int_Outcomes.Success (42);
      F : constant Int_Outcomes.Outcome := Int_Outcomes.Failure ([7, 8, 9]);
   begin
      Assert (Int_Outcomes.Is_Success (S), "success");
      Assert (Int_Outcomes.Value_Of (S) = 42, "value");
      Assert (Int_Outcomes.Error_Count (S) = 0, "no errors on success");

      Assert (Int_Outcomes.Is_Failure (F), "failure");
      Assert (Int_Outcomes.Error_Count (F) = 3, "three errors");
      Assert (Int_Outcomes.Element (F, 1) = 7
                and then Int_Outcomes.Element (F, 3) = 9,
              "ordered errors preserved");

      Assert (Int_Outcomes."=" (S, Int_Outcomes.Success (42)),
              "deterministic equality");
      Assert (not Int_Outcomes."=" (S, F), "success /= failure");
   end Test_Outcomes;

   --------------------------------------------------------------------------

   function FID (Name : String) return Ids.Field_Id is
     (Ids.Field_Ids.Make (Name));

   procedure Test_Paths (T : in out Fixture) is
      pragma Unreferenced (T);
      P_User  : constant Paths.Path := Paths.Append_Field (Paths.Root, FID ("user"));
      P_Roles : constant Paths.Path := Paths.Append_Field (P_User, FID ("roles"));
      P_Elem  : constant Paths.Path := Paths.Append_Index (P_Roles, 0);
      Again   : constant Paths.Path := Paths.Append_Field (P_User, FID ("roles"));
   begin
      Assert (Paths.Segment_Count (P_Elem) = 3, "three segments");
      Assert (Paths.Is_Absolute (P_Elem) and then not Paths.Is_Root (P_Elem),
              "absolute non-root");
      Assert (Paths.Is_Root (Paths.Root), "root is root");

      --  append then parent returns the original
      Assert (Paths.Parent (P_Roles) = P_User, "parent undoes append");
      Assert (Paths.Kind_At (P_Elem, 3) = Paths.Index, "last is an index");
      Assert (Paths.Last_Name (P_Roles) = "roles", "leaf field name");
      Assert (Paths.Last_Name (P_Elem) = "", "index leaf has no name");

      --  root prefixes everything; prefix + subtree
      Assert (Paths.Is_Prefix_Of (Paths.Root, P_Elem), "root prefixes all");
      Assert (Paths.Is_Prefix_Of (P_User, P_Elem), "user prefixes elem");
      Assert (Paths.Is_In_Subtree_Of (P_Elem, P_User), "elem in user subtree");
      Assert (not Paths.Is_Prefix_Of (P_Elem, P_User), "not the other way");

      --  determinism: equal construction is equal and hashes equal
      Assert (P_Roles = Again, "structurally equal paths compare equal");
      Assert (Paths.Hash (P_Roles) = Paths.Hash (Again), "equal paths hash equal");
      Assert (Paths."<" (P_User, P_Elem), "shorter prefix sorts first");
   end Test_Paths;

   --------------------------------------------------------------------------

   procedure Test_Path_Rendering (T : in out Fixture) is
      pragma Unreferenced (T);
      Base   : constant Paths.Path := Paths.Append_Field (Paths.Root, FID ("user"));
      Elem   : constant Paths.Path :=
        Paths.Append_Index (Paths.Append_Field (Base, FID ("roles")), 0);
      Secret : constant Paths.Path :=
        Paths.Append_Key (Paths.Root, Paths.Text_Key, "ssn", Paths.Redact);
      Hashed : constant Paths.Path :=
        Paths.Append_Key (Paths.Root, Paths.Text_Key, "token", Paths.Opaque_Hash);
   begin
      Assert (Paths.Render (Elem) = "$.user.roles[0]", "dot/bracket render");
      Assert (Paths.Render (Secret) = "$[REDACTED]", "redacted key");
      declare
         R : constant String := Paths.Render (Hashed);
      begin
         Assert (R (R'First .. R'First + 2) = "$[#", "opaque-hash prefix");
         Assert (R'Length = 3 + 8 + 1, "opaque-hash is 8 hex digits");
      end;
   end Test_Path_Rendering;

   --------------------------------------------------------------------------

   procedure Test_Values (T : in out Fixture) is
      pragma Unreferenced (T);
      Secret_Text : constant Values.Value :=
        Values.Of_Text ("hunter2", Values.Secret);
      NaN1 : constant Values.Value := Values.Of_Real_Special (Values.Not_A_Number);
      NaN2 : constant Values.Value := Values.Of_Real_Special (Values.Not_A_Number);
      Dec  : constant Values.Value := Values.Of_Decimal (True, "1234", 2);
      PathV : constant Values.Value :=
        Values.Of_Path (Paths.Append_Field (Paths.Root, FID ("user")));
   begin
      Assert (Values.Image (Values.Of_Signed (-5)) = "-5", "signed image");
      Assert (Values.Image (Values.Of_Boolean (True)) = "true", "boolean image");
      Assert (Values.Image (Dec) = "-1234E-2", "decimal image");
      Assert (Values.Kind (NaN1) = Values.Real_Value
                and then Values.Real_Category (NaN1) = Values.Not_A_Number,
              "NaN classified");
      Assert (Values.Image (NaN1) = "NaN", "NaN renders NaN");

      --  neutral representational equality: NaN = NaN in this model
      Assert (NaN1 = NaN2, "neutral NaN equality is representational");

      Assert (Values.Is_Secret (Secret_Text), "secret classified");
      Assert (Values.Image (Secret_Text) = "<secret>", "secret redacted in image");

      Assert (Values.Image (PathV) = "$.user", "path value renders path");
      Assert (Values.As_Signed (Values.Of_Signed (99)) = 99, "signed round-trip");
   end Test_Values;

   --------------------------------------------------------------------------

   procedure Test_Messages (T : in out Fixture) is
      pragma Unreferenced (T);
      B     : Msgs.Message_Builder := Msgs.Begin_Message (Msgs.Minimum);
      Added : Boolean;
   begin
      Msgs.Add_Argument (B, Msgs.Arg_Minimum, Values.Of_Signed (3), Added);
      Assert (Added, "first argument added");
      Msgs.Add_Argument (B, Msgs.Arg_Minimum, Values.Of_Signed (9), Added);
      Assert (not Added, "duplicate argument name rejected");
      Msgs.Add_Argument (B, Msgs.Arg_Actual, Values.Of_Signed (1), Added);
      Assert (Added, "second distinct argument added");

      declare
         M : constant Msgs.Message := Msgs.To_Message (B);
      begin
         Assert (Ids.Message_Ids."=" (Msgs.Id_Of (M), Msgs.Minimum), "id preserved");
         Assert (Msgs.Argument_Count (M) = 2, "two arguments, order preserved");
         Assert (Ids.Argument_Names."="
                   (Msgs.Name_At (M, 1), Msgs.Arg_Minimum),
                 "first arg is minimum");
         Assert (Msgs.Has_Argument (M, Msgs.Arg_Actual), "has actual");
         Assert (Msgs.Argument_Count (Msgs.Make (Msgs.Required)) = 0,
                 "no-arg message");
      end;
   end Test_Messages;

   procedure Test_Metadata (T : in out Fixture) is
      pragma Unreferenced (T);
      Key   : constant Ids.Metadata_Key := Ids.Metadata_Keys.Make ("trace.id");
      B     : Meta.Metadata_Builder := Meta.Begin_Metadata;
      Added : Boolean;
   begin
      Meta.Add (B, Key, Values.Of_Text ("abc123"), Added);
      Assert (Added, "metadata added");
      Meta.Add (B, Key, Values.Of_Text ("other"), Added);
      Assert (not Added, "duplicate key rejected");

      declare
         D : constant Meta.Metadata := Meta.To_Metadata (B);
      begin
         Assert (Meta.Count (D) = 1, "one entry");
         Assert (Meta.Has_Key (D, Key), "has key");
         Assert (Values.As_Text (Meta.Value_At (D, 1)) = "abc123", "value kept");
         Assert (Meta.Count (Meta.Empty) = 0, "empty metadata");
      end;
   end Test_Metadata;

   procedure Test_Source_References (T : in out Fixture) is
      pragma Unreferenced (T);
      Kind : constant Ids.Source_Kind_Id := Ids.Source_Kind_Ids.Make ("import.csv");
      Inst : constant Ids.Source_Instance_Id :=
        Ids.Source_Instance_Ids.Make ("upload-42");
      R : constant SRef.Source_Reference :=
        SRef.With_Column
          (SRef.With_Line (SRef.Make (Kind, Inst), 5), 2);
   begin
      Assert (Ids.Source_Kind_Ids."=" (SRef.Source_Kind (R), Kind), "kind");
      Assert (SRef.Has_Line (R) and then SRef.Line (R) = 5, "line set");
      Assert (SRef.Has_Column (R) and then SRef.Column (R) = 2, "column set");
      Assert (not SRef.Has_Byte_Offset (R), "offset unset by default");
      Assert (not SRef.Has_Field (R), "field unset by default");
   end Test_Source_References;

   procedure Test_Fingerprints (T : in out Fixture) is
      pragma Unreferenced (T);
      use type FP.Fingerprint;

      function Two (A, B : String) return FP.Fingerprint is
         Bld : FP.Builder := FP.Start;
      begin
         FP.Add_String (Bld, A);
         FP.Add_String (Bld, B);
         return FP.Finish (Bld);
      end Two;

      X : constant FP.Fingerprint := Two ("ab", "c");
      Y : constant FP.Fingerprint := Two ("ab", "c");
      Z : constant FP.Fingerprint := Two ("a", "bc");
   begin
      Assert (X = Y, "same contributions -> same fingerprint");
      Assert (FP.Image (X) = FP.Image (Y), "same image");
      Assert (FP.Image (X)'Length = 16, "16 hex digits");
      Assert (X /= Z, "length-prefixing prevents (ab,c)=(a,bc) collision");
      Assert (FP.Of_String ("x") = FP.Of_String ("x"), "Of_String deterministic");
   end Test_Fingerprints;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Foundation: identifiers", Test_Identifiers'Access));
      Suite.Add_Test (Caller.Create ("Foundation: versions", Test_Versions'Access));
      Suite.Add_Test (Caller.Create ("Foundation: outcomes", Test_Outcomes'Access));
      Suite.Add_Test (Caller.Create ("Foundation: paths", Test_Paths'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: path rendering", Test_Path_Rendering'Access));
      Suite.Add_Test (Caller.Create ("Foundation: values", Test_Values'Access));
      Suite.Add_Test (Caller.Create ("Foundation: messages", Test_Messages'Access));
      Suite.Add_Test (Caller.Create ("Foundation: metadata", Test_Metadata'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: source references", Test_Source_References'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: fingerprints", Test_Fingerprints'Access));
   end Add_Tests;

end Foundation_Tests;
