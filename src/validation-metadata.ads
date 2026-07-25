private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Values;

------------------------------------------------------------------------------
--  Validation.Metadata
--
--  Bounded, ordered, duplicate-controlled metadata: named typed Values keyed by
--  Metadata_Key. Used for optional issue/context diagnostic metadata. Order is
--  deterministic (insertion order); duplicate keys are rejected by default.
--  Secret values remain redacted through Validation.Values (VAL-INV-035).
------------------------------------------------------------------------------

package Validation.Metadata is

   type Metadata is private;

   type Metadata_Builder is private;

   function Begin_Metadata return Metadata_Builder;

   procedure Add
     (Builder : in out Metadata_Builder;
      Key     : Identifiers.Metadata_Key;
      Value   : Values.Value;
      Added   : out Boolean);

   function To_Metadata (Builder : Metadata_Builder) return Metadata;

   function Empty return Metadata;

   function Count (Item : Metadata) return Natural;

   function Key_At
     (Item : Metadata; Position : Positive) return Identifiers.Metadata_Key
     with Pre => Position <= Count (Item);
   function Value_At (Item : Metadata; Position : Positive) return Values.Value
     with Pre => Position <= Count (Item);

   function Has_Key
     (Item : Metadata; Key : Identifiers.Metadata_Key) return Boolean;

   function "=" (Left, Right : Metadata) return Boolean;

private

   type Entry_Pair is record
      Key   : Identifiers.Metadata_Key;
      Value : Values.Value;
   end record;

   package Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Entry_Pair);

   type Metadata is record
      Entries : Entry_Vectors.Vector;
   end record;

   type Metadata_Builder is record
      Entries : Entry_Vectors.Vector;
   end record;

end Validation.Metadata;
