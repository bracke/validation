package body Proto_Rule_Nodes is

   function Evaluate (R : Rule; Subject : Subject_Type) return Outcome is
      Result : Outcome;
   begin
      if Node_Holders.Is_Empty (R.Held) then
         return Result;
      end if;

      declare
         E      : constant Node'Class := R.Held.Element;
         Passed : constant Boolean := Check (E, Subject);
      begin
         Result.Passed := Passed;
         if not Passed then
            declare
               M : constant String := Msg_Strings.To_String (E.Message);
            begin
               Result.Length := M'Length;
               Result.Message (1 .. M'Length) := M;
            end;
         end if;
      end;
      return Result;
   end Evaluate;

   package body Predicate_Rule is

      type P_Node is new Node with null record;

      overriding function Check
        (N : P_Node; Subject : Subject_Type) return Boolean;

      overriding function Check
        (N : P_Node; Subject : Subject_Type) return Boolean is
         pragma Unreferenced (N);
      begin
         return Predicate (Subject);
      end Check;

      function Make return Rule is
         N : P_Node;
      begin
         N.Message := Msg_Strings.To_Bounded_String (Message_Id);
         return (Held => Node_Holders.To_Holder (N));
      end Make;

   end Predicate_Rule;

   function Empty_Set return Rule_Set is
   begin
      return (Items => Rule_Vectors.Empty_Vector);
   end Empty_Set;

   function Add (Set : Rule_Set; R : Rule) return Rule_Set is
      Result : Rule_Set := Set;
   begin
      Result.Items.Append (R);
      return Result;
   end Add;

   function Length (Set : Rule_Set) return Natural is
   begin
      return Natural (Set.Items.Length);
   end Length;

   function Evaluate_All
     (Set : Rule_Set; Subject : Subject_Type) return Outcome
   is
      Result : Outcome;
   begin
      for R of Set.Items loop
         Result := Evaluate (R, Subject);
         if not Result.Passed then
            return Result;
         end if;
      end loop;
      return Result;
   end Evaluate_All;

end Proto_Rule_Nodes;
