package body Validation.Metadata is

   package MKeys renames Identifiers.Metadata_Keys;
   use type Values.Value;
   use type Ada.Containers.Count_Type;

   function Begin_Metadata return Metadata_Builder is
     (Entries => Entry_Vectors.Empty_Vector);

   procedure Add
     (Builder : in out Metadata_Builder;
      Key     : Identifiers.Metadata_Key;
      Value   : Values.Value;
      Added   : out Boolean) is
   begin
      for Existing of Builder.Entries loop
         if MKeys."=" (Existing.Key, Key) then
            Added := False;
            return;
         end if;
      end loop;
      Builder.Entries.Append (Entry_Pair'(Key => Key, Value => Value));
      Added := True;
   end Add;

   function To_Metadata (Builder : Metadata_Builder) return Metadata is
     (Entries => Builder.Entries);

   function Empty return Metadata is (Entries => Entry_Vectors.Empty_Vector);

   function Count (Item : Metadata) return Natural is
     (Natural (Item.Entries.Length));

   function Key_At
     (Item : Metadata; Position : Positive) return Identifiers.Metadata_Key is
     (Item.Entries (Position).Key);

   function Value_At (Item : Metadata; Position : Positive) return Values.Value is
     (Item.Entries (Position).Value);

   function Has_Key
     (Item : Metadata; Key : Identifiers.Metadata_Key) return Boolean is
   begin
      for Existing of Item.Entries loop
         if MKeys."=" (Existing.Key, Key) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Key;

   function "=" (Left, Right : Metadata) return Boolean is
   begin
      if Left.Entries.Length /= Right.Entries.Length then
         return False;
      end if;
      for I in 1 .. Natural (Left.Entries.Length) loop
         if not MKeys."=" (Left.Entries (I).Key, Right.Entries (I).Key)
           or else Left.Entries (I).Value /= Right.Entries (I).Value
         then
            return False;
         end if;
      end loop;
      return True;
   end "=";

end Validation.Metadata;
