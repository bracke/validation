private with Ada.Containers.Indefinite_Vectors;
private with Ada.Strings.Bounded;

------------------------------------------------------------------------------
--  Proto_Capabilities  (Phase 0 feasibility prototype)
--
--  Proves the storage strategy for Validation.Contexts (ADR-006 typed
--  capability context, ADR-015 capability storage): a finalized immutable
--  heterogeneous container that stores values of UNRELATED types, inserted and
--  retrieved only through matching typed generic instances, with:
--
--    * no public untyped downcast and no application-visible type erasure;
--    * no primary String-to-Any map;
--    * duplicate capability-id rejection at build time;
--    * schema-version incompatibility surfaced as "not found" on retrieval;
--    * no identity derived from an access value or memory address
--      (VAL-INV-015) — recovery is by tag test + checked view conversion.
--
--  Ownership: values are stored BY VALUE in an indefinite vector of the
--  class-wide holder type, so there are no access types, no unchecked
--  conversion, and no manual deallocation. Freezing copies the built value
--  into an immutable container.
------------------------------------------------------------------------------

package Proto_Capabilities is

   --  Finalized immutable capability container.
   type Container is private;

   --  Mutable builder; finalized by Freeze.
   type Builder is private;

   function New_Builder return Builder;

   type Add_Result is (Added, Duplicate_Capability, Empty_Capability_Id);

   function Freeze (B : Builder) return Container;

   function Cardinality (C : Container) return Natural;

   --  One typed capability slot. Instantiate once per (Value_Type,
   --  Capability_Id) pair; Put/Get are type-safe against Value_Type.
   generic
      type Value_Type is private;
      Capability_Id  : String;
      Schema_Version : Positive := 1;
   package Capability is

      procedure Put
        (B      : in out Builder;
         Value  : Value_Type;
         Result : out Add_Result);

      function Present (C : Container) return Boolean;

      --  Found is False when the capability is absent OR its stored schema
      --  version differs from Schema_Version (an incompatible capability is
      --  never silently coerced). Value is meaningful only when Found is True
      --  (it is a scalar-safe out parameter: callers must check Found first).
      procedure Get
        (C     : Container;
         Value : out Value_Type;
         Found : out Boolean);

   end Capability;

private

   package Id_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length (128);

   --  Root of the private holder hierarchy. Carries the capability identity
   --  and schema version shared by every slot; concrete holders (declared in
   --  the Capability body, which sees this private part) add the typed value.
   type Holder is abstract tagged record
      Id      : Id_Strings.Bounded_String;
      Version : Positive := 1;
   end record;

   package Holder_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive, Element_Type => Holder'Class);

   type Container is record
      Items : Holder_Vectors.Vector;
   end record;

   type Builder is record
      Items : Holder_Vectors.Vector;
   end record;

end Proto_Capabilities;
