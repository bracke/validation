private with Ada.Containers.Vectors;

------------------------------------------------------------------------------
--  Validation.Outcomes  (generic)
--
--  The one standard value-or-errors abstraction (§18) used for construction and
--  finalization operations: validator/context/profile finalization, checked
--  path construction, projection construction, and so on. An Outcome is either
--  a success carrying an immutable Value, or a failure carrying an immutable
--  ordered, non-empty sequence of Errors. Success is never partial.
--
--  It is generic over both the value and the error type so it does not couple
--  the foundational layer to any particular error representation.
--
--  NOTE: Validation EXECUTION does not return an Outcome — it returns
--  Validation.Results.Result, because invocation errors are part of the
--  execution outcome. Outcomes is for definition-time construction only.
------------------------------------------------------------------------------

generic
   type Value_Type is private;
   type Error_Type is private;
   with function "=" (Left, Right : Error_Type) return Boolean is <>;
package Validation.Outcomes is

   type Error_Array is array (Positive range <>) of Error_Type;

   type Outcome is private;

   function Success (Value : Value_Type) return Outcome;

   --  Requires at least one error: a failure is never empty (mirror of "a
   --  success is never partial").
   function Failure (Errors : Error_Array) return Outcome
     with Pre => Errors'Length >= 1;

   function Failure (Error : Error_Type) return Outcome;

   function Is_Success (Item : Outcome) return Boolean;
   function Is_Failure (Item : Outcome) return Boolean;

   function Value_Of (Item : Outcome) return Value_Type
     with Pre => Is_Success (Item);

   function Error_Count (Item : Outcome) return Natural;

   function Element (Item : Outcome; Index : Positive) return Error_Type
     with Pre => Is_Failure (Item) and then Index <= Error_Count (Item);

   function "=" (Left, Right : Outcome) return Boolean;

private

   package Error_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Error_Type, "=" => "=");

   type Outcome (Succeeded : Boolean := False) is record
      case Succeeded is
         when True =>
            Value : Value_Type;
         when False =>
            Errors : Error_Vectors.Vector;
      end case;
   end record;

end Validation.Outcomes;
