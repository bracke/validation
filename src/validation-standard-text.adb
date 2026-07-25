with Validation.Values;
with Validation.Contexts;
with Validation.Standard.UTF_8;

package body Validation.Standard.Text is

   type Check_Kind is
     (Min_Len, Max_Len, Exact_Len, Non_Empty_K, Non_Blank_K, UTF8_K);

   type Text_Params is record
      Kind     : Check_Kind;
      Field    : Identifiers.Field_Id;
      Bound    : Natural := 0;
      Message  : Identifiers.Message_Id;
      Level    : Issues.Severity;
      Category : Identifiers.Issue_Category_Id;
   end record;

   function Is_Blank (Item : String) return Boolean is
   begin
      for C of Item loop
         if C not in ' ' | Character'Val (9) | Character'Val (10)
                     | Character'Val (11) | Character'Val (12)
                     | Character'Val (13)
         then
            return False;
         end if;
      end loop;
      return True;
   end Is_Blank;

   function Build_Message (Params : Text_Params) return Messages.Message is
      B     : Messages.Message_Builder := Messages.Begin_Message (Params.Message);
      Added : Boolean;
   begin
      case Params.Kind is
         when Min_Len =>
            Messages.Add_Argument
              (B, Messages.Arg_Minimum,
               Values.Of_Count (Values.Count_Number (Params.Bound)), Added);
         when Max_Len =>
            Messages.Add_Argument
              (B, Messages.Arg_Maximum,
               Values.Of_Count (Values.Count_Number (Params.Bound)), Added);
         when Exact_Len =>
            Messages.Add_Argument
              (B, Messages.Arg_Expected,
               Values.Of_Count (Values.Count_Number (Params.Bound)), Added);
         when others =>
            null;
      end case;
      return Messages.To_Message (B);
   end Build_Message;

   procedure Apply_Text
     (Subject : Subject_Type;
      Params  : Text_Params;
      Context : Validation.Contexts.Context;
      Output  : in out Val.Rule_Output)
   is
      pragma Unreferenced (Context);
      Value  : constant String := Get (Subject);
      Failed : Boolean := False;
   begin
      case Params.Kind is
         when Min_Len     => Failed := Value'Length < Params.Bound;
         when Max_Len     => Failed := Value'Length > Params.Bound;
         when Exact_Len   => Failed := Value'Length /= Params.Bound;
         when Non_Empty_K => Failed := Value'Length = 0;
         when Non_Blank_K => Failed := Is_Blank (Value);
         when UTF8_K      => Failed := not UTF_8.Is_Valid (Value);
      end case;
      if Failed then
         Val.Add_Issue_At_Field
           (Output, Params.Field, Params.Level, Params.Category,
            Build_Message (Params));
      end if;
   end Apply_Text;

   package Text_Rules is new Val.Parameterized_Rules (Text_Params, Apply_Text);

   function Rule_Of
     (Params : Text_Params; Rule_Id : Identifiers.Rule_Id;
      Phase : Phases.Phase) return Val.Rule is
     (Text_Rules.Make (Params, Rule_Id, Phase));

   function Min_Length
     (Field    : Identifiers.Field_Id;
      Min      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((Min_Len, Field, Min, Message, Level, Category), Rule_Id, Phase));

   function Max_Length
     (Field    : Identifiers.Field_Id;
      Max      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((Max_Len, Field, Max, Message, Level, Category), Rule_Id, Phase));

   function Exact_Length
     (Field    : Identifiers.Field_Id;
      Length   : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Exact;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((Exact_Len, Field, Length, Message, Level, Category),
      Rule_Id, Phase));

   function Non_Empty
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Not_Empty;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Presence;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((Non_Empty_K, Field, 0, Message, Level, Category),
      Rule_Id, Phase));

   function Non_Blank
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Not_Blank;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Presence;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((Non_Blank_K, Field, 0, Message, Level, Category),
      Rule_Id, Phase));

   function Valid_UTF8
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Invalid_UTF8;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Encoding;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Rule_Of ((UTF8_K, Field, 0, Message, Level, Category), Rule_Id, Phase));

end Validation.Standard.Text;
