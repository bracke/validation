package body Validation.Source_References is

   function Make
     (Source_Kind : Identifiers.Source_Kind_Id;
      Instance    : Identifiers.Source_Instance_Id) return Source_Reference is
   begin
      return R : Source_Reference do
         R.Kind := Source_Kind;
         R.Instance := Instance;
      end return;
   end Make;

   function With_Record_Ordinal
     (Item : Source_Reference; Ordinal : Positive) return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Has_Ordinal := True;
      Result.Ordinal := Ordinal;
      return Result;
   end With_Record_Ordinal;

   function With_Field
     (Item : Source_Reference; Field : Identifiers.Field_Id)
      return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Field_Set := True;
      Result.Field_Ref := Field;
      return Result;
   end With_Field;

   function With_Line
     (Item : Source_Reference; Line : Positive) return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Line_Set := True;
      Result.Line_No := Line;
      return Result;
   end With_Line;

   function With_Column
     (Item : Source_Reference; Column : Positive) return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Column_Set := True;
      Result.Column_No := Column;
      return Result;
   end With_Column;

   function With_Byte_Offset
     (Item : Source_Reference; Offset : Natural) return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Offset_Set := True;
      Result.Offset := Offset;
      return Result;
   end With_Byte_Offset;

   function With_Metadata
     (Item : Source_Reference; Data : Metadata.Metadata) return Source_Reference is
      Result : Source_Reference := Item;
   begin
      Result.Meta := Data;
      return Result;
   end With_Metadata;

   function Source_Kind
     (Item : Source_Reference) return Identifiers.Source_Kind_Id is (Item.Kind);
   function Instance
     (Item : Source_Reference) return Identifiers.Source_Instance_Id is
     (Item.Instance);

   function Has_Record_Ordinal (Item : Source_Reference) return Boolean is
     (Item.Has_Ordinal);
   function Record_Ordinal (Item : Source_Reference) return Positive is
     (Item.Ordinal);
   function Has_Field (Item : Source_Reference) return Boolean is (Item.Field_Set);
   function Field (Item : Source_Reference) return Identifiers.Field_Id is
     (Item.Field_Ref);
   function Has_Line (Item : Source_Reference) return Boolean is (Item.Line_Set);
   function Line (Item : Source_Reference) return Positive is (Item.Line_No);
   function Has_Column (Item : Source_Reference) return Boolean is (Item.Column_Set);
   function Column (Item : Source_Reference) return Positive is (Item.Column_No);
   function Has_Byte_Offset (Item : Source_Reference) return Boolean is
     (Item.Offset_Set);
   function Byte_Offset (Item : Source_Reference) return Natural is (Item.Offset);
   function Application_Metadata
     (Item : Source_Reference) return Metadata.Metadata is (Item.Meta);

end Validation.Source_References;
