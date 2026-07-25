package body Validation.Messages is

   package ANames renames Identifiers.Argument_Names;
   package MIds renames Identifiers.Message_Ids;
   use type Values.Value;
   use type Ada.Containers.Count_Type;

   function Begin_Message
     (Id : Identifiers.Message_Id) return Message_Builder is
     (Id => Id, Arguments => Argument_Vectors.Empty_Vector);

   procedure Add_Argument
     (Builder : in out Message_Builder;
      Name    : Identifiers.Argument_Name;
      Value   : Values.Value;
      Added   : out Boolean) is
   begin
      for Existing of Builder.Arguments loop
         if ANames."=" (Existing.Name, Name) then
            Added := False;
            return;
         end if;
      end loop;
      Builder.Arguments.Append (Argument'(Name => Name, Value => Value));
      Added := True;
   end Add_Argument;

   function To_Message (Builder : Message_Builder) return Message is
     (Id => Builder.Id, Arguments => Builder.Arguments);

   function Make (Id : Identifiers.Message_Id) return Message is
     (Id => Id, Arguments => Argument_Vectors.Empty_Vector);

   function Id_Of (Item : Message) return Identifiers.Message_Id is (Item.Id);

   function Argument_Count (Item : Message) return Natural is
     (Natural (Item.Arguments.Length));

   function Name_At
     (Item : Message; Position : Positive) return Identifiers.Argument_Name is
     (Item.Arguments (Position).Name);

   function Value_At (Item : Message; Position : Positive) return Values.Value is
     (Item.Arguments (Position).Value);

   function Has_Argument
     (Item : Message; Name : Identifiers.Argument_Name) return Boolean is
   begin
      for Existing of Item.Arguments loop
         if ANames."=" (Existing.Name, Name) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Argument;

   overriding function "=" (Left, Right : Message) return Boolean is
   begin
      if not MIds."=" (Left.Id, Right.Id)
        or else Left.Arguments.Length /= Right.Arguments.Length
      then
         return False;
      end if;
      for I in 1 .. Natural (Left.Arguments.Length) loop
         if not ANames."=" (Left.Arguments (I).Name, Right.Arguments (I).Name)
           or else Left.Arguments (I).Value /= Right.Arguments (I).Value
         then
            return False;
         end if;
      end loop;
      return True;
   end "=";

end Validation.Messages;
