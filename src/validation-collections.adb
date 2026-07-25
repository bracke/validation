with Validation.Paths;
with Validation.Values;
with Validation.Contexts;

package body Validation.Collections is

   subtype Field_Id is Identifiers.Field_Id;

   function Element_Rel (Field : Field_Id; Index : Positive) return Paths.Path is
     (Paths.Append_Index
        (Paths.Append_Field (Paths.Empty_Relative, Field),
         Paths.Index_Value (Index - 1)));

   function Element_Abs (Field : Field_Id; Index : Positive) return Paths.Path is
     (Paths.Append_Index
        (Paths.Append_Field (Paths.Root, Field),
         Paths.Index_Value (Index - 1)));

   function Of_Count (Value : Natural) return Values.Value is
     (Values.Of_Count (Values.Count_Number (Value)));

   ---------------------------------------------------------------------------
   --  Cardinality
   ---------------------------------------------------------------------------

   type Card_Kind is (Min_C, Max_C, Exact_C);

   type Card_Params is record
      Kind     : Card_Kind;
      Field    : Field_Id;
      Bound    : Natural;
      Message  : Identifiers.Message_Id;
      Level    : Issues.Severity;
      Category : Identifiers.Issue_Category_Id;
   end record;

   function Card_Message (Params : Card_Params) return Messages.Message is
      B     : Messages.Message_Builder := Messages.Begin_Message (Params.Message);
      Added : Boolean;
   begin
      case Params.Kind is
         when Min_C =>
            Messages.Add_Argument (B, Messages.Arg_Minimum, Of_Count (Params.Bound), Added);
         when Max_C =>
            Messages.Add_Argument (B, Messages.Arg_Maximum, Of_Count (Params.Bound), Added);
         when Exact_C =>
            Messages.Add_Argument (B, Messages.Arg_Expected, Of_Count (Params.Bound), Added);
      end case;
      return Messages.To_Message (B);
   end Card_Message;

   procedure Apply_Card
     (Subject : Subject_Type;
      Params  : Card_Params;
      Context : Validation.Contexts.Context;
      Output  : in out Val.Rule_Output)
   is
      pragma Unreferenced (Context);
      N      : constant Natural := Count (Get (Subject));
      Failed : Boolean;
   begin
      case Params.Kind is
         when Min_C   => Failed := N < Params.Bound;
         when Max_C   => Failed := N > Params.Bound;
         when Exact_C => Failed := N /= Params.Bound;
      end case;
      if Failed then
         Val.Add_Issue_At_Field
           (Output, Params.Field, Params.Level, Params.Category,
            Card_Message (Params));
      end if;
   end Apply_Card;

   package Card_Rules is new Val.Parameterized_Rules (Card_Params, Apply_Card);

   function Min_Count
     (Field    : Identifiers.Field_Id;
      Min      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
     (Card_Rules.Make ((Min_C, Field, Min, Message, Level, Category),
      Rule_Id, Phase));

   function Max_Count
     (Field    : Identifiers.Field_Id;
      Max      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
     (Card_Rules.Make ((Max_C, Field, Max, Message, Level, Category),
      Rule_Id, Phase));

   function Exact_Count
     (Field    : Identifiers.Field_Id;
      Expected : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Exact;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
     (Card_Rules.Make ((Exact_C, Field, Expected, Message, Level, Category),
      Rule_Id, Phase));

   ---------------------------------------------------------------------------
   --  Per-element predicate
   ---------------------------------------------------------------------------

   package body Each_Element is

      type EE_Params is record
         Field    : Field_Id;
         Message  : Identifiers.Message_Id;
         Level    : Issues.Severity;
         Category : Identifiers.Issue_Category_Id;
      end record;

      procedure Apply_EE
        (Subject : Subject_Type;
         Params  : EE_Params;
         Context : Validation.Contexts.Context;
         Output  : in out Val.Rule_Output)
      is
         pragma Unreferenced (Context);
         Collection : constant Collection_Type := Get (Subject);
      begin
         for Index in 1 .. Count (Collection) loop
            if not Check (Item (Collection, Index)) then
               Val.Add_Issue
                 (Output, Params.Level, Params.Category,
                  Messages.Make (Params.Message),
                  Element_Rel (Params.Field, Index));
            end if;
         end loop;
      end Apply_EE;

      package R is new Val.Parameterized_Rules (EE_Params, Apply_EE);

      function Rule
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Element;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (R.Make ((Field, Message, Level, Category), Rule_Id, Phase));

   end Each_Element;

   ---------------------------------------------------------------------------
   --  Uniqueness
   ---------------------------------------------------------------------------

   package body Unique is

      type U_Params is record
         Field    : Field_Id;
         Message  : Identifiers.Message_Id;
         Level    : Issues.Severity;
         Category : Identifiers.Issue_Category_Id;
      end record;

      procedure Apply_U
        (Subject : Subject_Type;
         Params  : U_Params;
         Context : Validation.Contexts.Context;
         Output  : in out Val.Rule_Output)
      is
         pragma Unreferenced (Context);
         Collection : constant Collection_Type := Get (Subject);
      begin
         for Index in 1 .. Count (Collection) loop
            declare
               Key   : constant Key_Type := Key_Of (Item (Collection, Index));
               First : Natural := 0;
            begin
               for Prior in 1 .. Index - 1 loop
                  if Key_Equal (Key_Of (Item (Collection, Prior)), Key) then
                     First := Prior;
                     exit;
                  end if;
               end loop;
               if First /= 0 then
                  Val.Add_Issue_With_Related
                    (Output, Params.Level, Params.Category,
                     Messages.Make (Params.Message),
                     Related       => [Element_Abs (Params.Field, First)],
                     Relative_Path => Element_Rel (Params.Field, Index));
               end if;
            end;
         end loop;
      end Apply_U;

      package R is new Val.Parameterized_Rules (U_Params, Apply_U);

      function Rule
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Duplicate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Duplicate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (R.Make ((Field, Message, Level, Category), Rule_Id, Phase));

   end Unique;

   ---------------------------------------------------------------------------
   --  Quantifiers
   ---------------------------------------------------------------------------

   package body Quantifier is

      type Q_Kind is (At_Least_K, At_Most_K, Exactly_K);

      type Q_Params is record
         Kind     : Q_Kind;
         Field    : Field_Id;
         N        : Natural;
         Message  : Identifiers.Message_Id;
         Level    : Issues.Severity;
         Category : Identifiers.Issue_Category_Id;
      end record;

      procedure Apply_Q
        (Subject : Subject_Type;
         Params  : Q_Params;
         Context : Validation.Contexts.Context;
         Output  : in out Val.Rule_Output)
      is
         pragma Unreferenced (Context);
         Collection : constant Collection_Type := Get (Subject);
         Matches    : Natural := 0;
         Failed     : Boolean;
      begin
         for Index in 1 .. Count (Collection) loop
            if Check (Item (Collection, Index)) then
               Matches := Matches + 1;
            end if;
         end loop;
         case Params.Kind is
            when At_Least_K => Failed := Matches < Params.N;
            when At_Most_K  => Failed := Matches > Params.N;
            when Exactly_K  => Failed := Matches /= Params.N;
         end case;
         if Failed then
            declare
               B     : Messages.Message_Builder :=
                 Messages.Begin_Message (Params.Message);
               Added : Boolean;
            begin
               Messages.Add_Argument
                 (B, Messages.Arg_Expected, Of_Count (Params.N), Added);
               Val.Add_Issue_At_Field
                 (Output, Params.Field, Params.Level, Params.Category,
                  Messages.To_Message (B));
            end;
         end if;
      end Apply_Q;

      package R is new Val.Parameterized_Rules (Q_Params, Apply_Q);

      function Make_Rule
        (Kind : Q_Kind; Field : Field_Id; N : Natural;
         Rule_Id : Identifiers.Rule_Id; Message : Identifiers.Message_Id;
         Level : Issues.Severity; Category : Identifiers.Issue_Category_Id;
         Phase : Phases.Phase) return Val.Rule is
        (R.Make ((Kind, Field, N, Message, Level, Category), Rule_Id, Phase));

      function At_Least
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (Make_Rule (At_Least_K, Field, N, Rule_Id, Message, Level, Category, Phase));

      function At_Most
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (Make_Rule (At_Most_K, Field, N, Rule_Id, Message, Level, Category, Phase));

      function Exactly
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (Make_Rule (Exactly_K, Field, N, Rule_Id, Message, Level, Category, Phase));

   end Quantifier;

   ---------------------------------------------------------------------------
   --  Aggregate
   ---------------------------------------------------------------------------

   package body Aggregate is

      type A_Kind is (Sum_At_Most_K, Sum_Equals_K);

      type A_Params is record
         Kind     : A_Kind;
         Field    : Field_Id;
         Bound    : Long_Long_Integer;
         Message  : Identifiers.Message_Id;
         Level    : Issues.Severity;
         Category : Identifiers.Issue_Category_Id;
      end record;

      procedure Apply_A
        (Subject : Subject_Type;
         Params  : A_Params;
         Context : Validation.Contexts.Context;
         Output  : in out Val.Rule_Output)
      is
         pragma Unreferenced (Context);
         Collection : constant Collection_Type := Get (Subject);
         Total      : Long_Long_Integer := 0;
         Failed     : Boolean;
      begin
         for Index in 1 .. Count (Collection) loop
            Total := Total + Project (Item (Collection, Index));
         end loop;
         case Params.Kind is
            when Sum_At_Most_K => Failed := Total > Params.Bound;
            when Sum_Equals_K  => Failed := Total /= Params.Bound;
         end case;
         if Failed then
            declare
               B     : Messages.Message_Builder :=
                 Messages.Begin_Message (Params.Message);
               Added : Boolean;
            begin
               Messages.Add_Argument
                 (B, Messages.Arg_Expected, Values.Of_Signed (Params.Bound), Added);
               Val.Add_Issue_At_Field
                 (Output, Params.Field, Params.Level, Params.Category,
                  Messages.To_Message (B));
            end;
         end if;
      end Apply_A;

      package R is new Val.Parameterized_Rules (A_Params, Apply_A);

      function Sum_At_Most
        (Field    : Identifiers.Field_Id;
         Max      : Long_Long_Integer;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Aggregate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (R.Make ((Sum_At_Most_K, Field, Max, Message, Level, Category),
         Rule_Id, Phase));

      function Sum_Equals
        (Field    : Identifiers.Field_Id;
         Expected : Long_Long_Integer;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Aggregate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule is
        (R.Make ((Sum_Equals_K, Field, Expected, Message, Level, Category),
         Rule_Id, Phase));

   end Aggregate;

end Validation.Collections;
