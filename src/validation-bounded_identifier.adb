with Ada.Strings.Hash;

package body Validation.Bounded_Identifier is

   use type BS.Bounded_String;

   function Make (Text : String) return Id is
     (Value => BS.To_Bounded_String (Text));

   function Try_Make (Text : String; Result : out Id) return Boolean is
   begin
      if Is_Valid (Text) then
         Result := (Value => BS.To_Bounded_String (Text));
         return True;
      else
         Result := Null_Id;
         return False;
      end if;
   end Try_Make;

   function Is_Null (Item : Id) return Boolean is
     (Item.Value = BS.Null_Bounded_String);

   function Image (Item : Id) return String is
     (BS.To_String (Item.Value));

   function Length (Item : Id) return Natural is
     (BS.Length (Item.Value));

   function "=" (Left, Right : Id) return Boolean is
     (Left.Value = Right.Value);

   function "<" (Left, Right : Id) return Boolean is
     (BS."<" (Left.Value, Right.Value));

   function Hash (Item : Id) return Ada.Containers.Hash_Type is
     (Ada.Strings.Hash (BS.To_String (Item.Value)));

end Validation.Bounded_Identifier;
