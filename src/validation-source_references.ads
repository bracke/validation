with Validation.Identifiers;
with Validation.Metadata;

------------------------------------------------------------------------------
--  Validation.Source_References
--
--  A compact optional neutral source-reference model (§13). A source reference
--  says WHERE source data came from (a form field, an import row/column, a
--  config line, ...). This is distinct from a Path, which identifies a SEMANTIC
--  location in the typed subject. Validation is not a full provenance
--  framework; adapters attach source references via caller-supplied
--  path-to-source mappings.
--
--  All positional fields are optional; construct a bare reference with Make and
--  layer optional facets with the With_* functions.
------------------------------------------------------------------------------

package Validation.Source_References is

   type Source_Reference is private;

   function Make
     (Source_Kind : Identifiers.Source_Kind_Id;
      Instance    : Identifiers.Source_Instance_Id) return Source_Reference;

   function With_Record_Ordinal
     (Item : Source_Reference; Ordinal : Positive) return Source_Reference;
   function With_Field
     (Item : Source_Reference; Field : Identifiers.Field_Id) return Source_Reference;
   function With_Line
     (Item : Source_Reference; Line : Positive) return Source_Reference;
   function With_Column
     (Item : Source_Reference; Column : Positive) return Source_Reference;
   function With_Byte_Offset
     (Item : Source_Reference; Offset : Natural) return Source_Reference;
   function With_Metadata
     (Item : Source_Reference; Data : Metadata.Metadata) return Source_Reference;

   function Source_Kind
     (Item : Source_Reference) return Identifiers.Source_Kind_Id;
   function Instance
     (Item : Source_Reference) return Identifiers.Source_Instance_Id;

   function Has_Record_Ordinal (Item : Source_Reference) return Boolean;
   function Record_Ordinal (Item : Source_Reference) return Positive
     with Pre => Has_Record_Ordinal (Item);
   function Has_Field (Item : Source_Reference) return Boolean;
   function Field (Item : Source_Reference) return Identifiers.Field_Id
     with Pre => Has_Field (Item);
   function Has_Line (Item : Source_Reference) return Boolean;
   function Line (Item : Source_Reference) return Positive
     with Pre => Has_Line (Item);
   function Has_Column (Item : Source_Reference) return Boolean;
   function Column (Item : Source_Reference) return Positive
     with Pre => Has_Column (Item);
   function Has_Byte_Offset (Item : Source_Reference) return Boolean;
   function Byte_Offset (Item : Source_Reference) return Natural
     with Pre => Has_Byte_Offset (Item);
   function Application_Metadata (Item : Source_Reference) return Metadata.Metadata;

private

   type Source_Reference is record
      Kind         : Identifiers.Source_Kind_Id;
      Instance     : Identifiers.Source_Instance_Id;
      Has_Ordinal  : Boolean := False;
      Ordinal      : Positive := 1;
      Field_Set    : Boolean := False;
      Field_Ref    : Identifiers.Field_Id;
      Line_Set     : Boolean := False;
      Line_No      : Positive := 1;
      Column_Set   : Boolean := False;
      Column_No    : Positive := 1;
      Offset_Set   : Boolean := False;
      Offset       : Natural := 0;
      Meta         : Metadata.Metadata := Metadata.Empty;
   end record;

end Validation.Source_References;
