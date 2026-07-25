package body Validation.Identifier_Syntax is

   function Is_First (C : Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9');

   function Is_Rest (C : Character) return Boolean is
     (Is_First (C) or else C in '.' | '_' | '-' | ':' | '/');

   function Is_Valid (Text : String) return Boolean is
   begin
      if Text'Length = 0 or else Text'Length > Max_Length then
         return False;
      end if;
      if not Is_First (Text (Text'First)) then
         return False;
      end if;
      for I in Text'First + 1 .. Text'Last loop
         if not Is_Rest (Text (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

end Validation.Identifier_Syntax;
