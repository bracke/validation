package body Validation.Identifier_Syntax
  with SPARK_Mode => On
is

   function Is_First (C : Character) return Boolean is
     (C in 'A' .. 'Z' | 'a' .. 'z' | '0' .. '9');

   function Is_Rest (C : Character) return Boolean is
     (Is_First (C) or else C in '.' | '_' | '-' | ':' | '/');

   function Is_Valid (Text : String) return Boolean is
   begin
      if Text'Length = 0 or else Text'Length > Max_Length then
         return False;
      end if;
      --  Single pass over the range (no Text'First + 1, which could overflow a
      --  pathological lower bound) — first character then the rest.
      for I in Text'Range loop
         if I = Text'First then
            if not Is_First (Text (I)) then
               return False;
            end if;
         elsif not Is_Rest (Text (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

end Validation.Identifier_Syntax;
