with Validation.Values;
with Validation.Contexts;

package body Validation.Standard.Numerics is

   type Check_Kind is
     (Min_K, Max_K, Range_K, Positive_K, Non_Negative_K, Non_Zero_K);

   type Num_Params is record
      Kind     : Check_Kind;
      Field    : Identifiers.Field_Id;
      Low      : Number := Number'First;
      High     : Number := Number'Last;
      Message  : Identifiers.Message_Id;
      Level    : Issues.Severity;
      Category : Identifiers.Issue_Category_Id;
   end record;

   function As_Value (Item : Number) return Values.Value is
     (Values.Of_Signed (Long_Long_Integer (Item)));

   function Build_Message (Params : Num_Params) return Messages.Message is
      B     : Messages.Message_Builder := Messages.Begin_Message (Params.Message);
      Added : Boolean;
   begin
      case Params.Kind is
         when Min_K =>
            Messages.Add_Argument (B, Messages.Arg_Minimum, As_Value (Params.Low), Added);
         when Max_K =>
            Messages.Add_Argument (B, Messages.Arg_Maximum, As_Value (Params.High), Added);
         when Range_K =>
            Messages.Add_Argument (B, Messages.Arg_Minimum, As_Value (Params.Low), Added);
            Messages.Add_Argument (B, Messages.Arg_Maximum, As_Value (Params.High), Added);
         when others =>
            null;
      end case;
      return Messages.To_Message (B);
   end Build_Message;

   procedure Apply_Num
     (Subject : Subject_Type;
      Params  : Num_Params;
      Context : Validation.Contexts.Context;
      Output  : in out Val.Rule_Output)
   is
      pragma Unreferenced (Context);
      Value  : constant Number := Get (Subject);
      Failed : Boolean := False;
   begin
      case Params.Kind is
         when Min_K          => Failed := Value < Params.Low;
         when Max_K          => Failed := Value > Params.High;
         when Range_K        => Failed := Value < Params.Low or else Value > Params.High;
         when Positive_K     => Failed := Value <= 0;
         when Non_Negative_K => Failed := Value < 0;
         when Non_Zero_K     => Failed := Value = 0;
      end case;
      if Failed then
         Val.Add_Issue_At_Field
           (Output, Params.Field, Params.Level, Params.Category,
            Build_Message (Params));
      end if;
   end Apply_Num;

   package Num_Rules is new Val.Parameterized_Rules (Num_Params, Apply_Num);

   function Minimum
     (Field    : Identifiers.Field_Id;
      Min      : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Min_K, Field, Min, Number'Last, Message, Level, Category),
         Rule_Id, Phase));

   function Maximum
     (Field    : Identifiers.Field_Id;
      Max      : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Max_K, Field, Number'First, Max, Message, Level, Category),
         Rule_Id, Phase));

   function In_Range
     (Field    : Identifiers.Field_Id;
      Low      : Number;
      High     : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Out_Of_Range;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Range_K, Field, Low, High, Message, Level, Category),
         Rule_Id, Phase));

   function Positive_Value
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Positive;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Positive_K, Field, Number'First, Number'Last, Message, Level, Category),
         Rule_Id, Phase));

   function Non_Negative
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Non_Negative;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Non_Negative_K, Field, Number'First, Number'Last, Message, Level,
          Category), Rule_Id, Phase));

   function Non_Zero
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Non_Zero;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule is
     (Num_Rules.Make
        ((Non_Zero_K, Field, Number'First, Number'Last, Message, Level,
          Category), Rule_Id, Phase));

end Validation.Standard.Numerics;
