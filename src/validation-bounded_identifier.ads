private with Ada.Strings.Bounded;
with Ada.Containers;
with Validation.Identifier_Syntax;

------------------------------------------------------------------------------
--  Validation.Bounded_Identifier  (generic)
--
--  Mints one strongly typed identifier category. Each instantiation produces a
--  DISTINCT private type Id, so identifiers of different categories cannot be
--  assigned to one another by accident (§7). Every category supports checked
--  construction (raising Make and non-raising Try_Make), a validity query, a
--  null value, equality, a deterministic total order, hashing, bounded
--  rendering, and conversion to String.
------------------------------------------------------------------------------

generic
   Kind_Name : String;
package Validation.Bounded_Identifier is

   type Id is private;

   Null_Id : constant Id;

   --  The category name, for diagnostics only (never part of Id identity).
   function Kind return String is (Kind_Name);

   function Is_Valid (Text : String) return Boolean
     renames Validation.Identifier_Syntax.Is_Valid;

   --  Checked construction from a literal or known-valid text. Raises
   --  Constraint_Error via its precondition on invalid syntax; use for
   --  compile-time-known identifiers, where invalidity is a programming error.
   function Make (Text : String) return Id
     with Pre => Is_Valid (Text);

   --  Non-raising construction from untrusted text. Returns False and sets
   --  Result to Null_Id when Text is not a valid identifier.
   function Try_Make (Text : String; Result : out Id) return Boolean;

   function Is_Null (Item : Id) return Boolean;

   function Image (Item : Id) return String;

   function Length (Item : Id) return Natural;

   function "=" (Left, Right : Id) return Boolean;

   function "<" (Left, Right : Id) return Boolean;

   function Hash (Item : Id) return Ada.Containers.Hash_Type;

private

   package BS is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Validation.Identifier_Syntax.Max_Length);

   type Id is record
      Value : BS.Bounded_String := BS.Null_Bounded_String;
   end record;

   Null_Id : constant Id := (Value => BS.Null_Bounded_String);

end Validation.Bounded_Identifier;
