package body Validation.Standard.UTF_8 is

   type U8 is mod 256;

   function Byte (Item : String; K : Positive) return U8 is
     (U8 (Character'Pos (Item (K))));

   function Is_Continuation (B : U8) return Boolean is
     ((B and 2#1100_0000#) = 2#1000_0000#);

   function Is_Valid (Item : String) return Boolean is
      I : Integer := Item'First;
   begin
      while I <= Item'Last loop
         declare
            C : constant U8 := Byte (Item, I);
         begin
            if C < 16#80# then
               I := I + 1;
            elsif C < 16#C2# then
               --  Stray continuation byte or overlong 2-byte lead.
               return False;
            elsif C < 16#E0# then
               if I + 1 > Item'Last
                 or else not Is_Continuation (Byte (Item, I + 1))
               then
                  return False;
               end if;
               I := I + 2;
            elsif C < 16#F0# then
               if I + 2 > Item'Last then
                  return False;
               end if;
               declare
                  C1 : constant U8 := Byte (Item, I + 1);
                  C2 : constant U8 := Byte (Item, I + 2);
               begin
                  if not Is_Continuation (C1) or else not Is_Continuation (C2)
                    or else (C = 16#E0# and then C1 < 16#A0#)   --  overlong
                    or else (C = 16#ED# and then C1 >= 16#A0#)  --  surrogate
                  then
                     return False;
                  end if;
               end;
               I := I + 3;
            elsif C < 16#F5# then
               if I + 3 > Item'Last then
                  return False;
               end if;
               declare
                  C1 : constant U8 := Byte (Item, I + 1);
                  C2 : constant U8 := Byte (Item, I + 2);
                  C3 : constant U8 := Byte (Item, I + 3);
               begin
                  if not Is_Continuation (C1) or else not Is_Continuation (C2)
                    or else not Is_Continuation (C3)
                    or else (C = 16#F0# and then C1 < 16#90#)   --  overlong
                    or else (C = 16#F4# and then C1 >= 16#90#)  --  > U+10FFFF
                  then
                     return False;
                  end if;
               end;
               I := I + 4;
            else
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Valid;

   function Scalar_Count (Item : String) return Natural is
      I     : Integer := Item'First;
      Count : Natural := 0;
   begin
      while I <= Item'Last loop
         declare
            C : constant U8 := Byte (Item, I);
         begin
            if C < 16#80# then
               I := I + 1;
            elsif C < 16#E0# then
               I := I + 2;
            elsif C < 16#F0# then
               I := I + 3;
            else
               I := I + 4;
            end if;
         end;
         Count := Count + 1;
      end loop;
      return Count;
   end Scalar_Count;

end Validation.Standard.UTF_8;
