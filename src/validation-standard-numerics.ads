with Validation.Identifiers;
with Validation.Phases;
with Validation.Issues;
with Validation.Messages;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Standard.Numerics  (generic)
--
--  Standard numeric validators over a signed-integer field accessor (§41). The
--  configured bound is included as a message argument; the actual field value
--  is excluded by default (§42).
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
   with package Val is new Validation.Validators (Subject_Type);
   type Number is range <>;
   with function Get (Subject : Subject_Type) return Number;
package Validation.Standard.Numerics is

   function Minimum
     (Field    : Identifiers.Field_Id;
      Min      : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Maximum
     (Field    : Identifiers.Field_Id;
      Max      : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function In_Range
     (Field    : Identifiers.Field_Id;
      Low      : Number;
      High     : Number;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Out_Of_Range;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Range;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule
     with Pre => Low <= High;

   function Positive_Value
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Positive;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Non_Negative
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Non_Negative;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Non_Zero
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Number_Non_Zero;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

end Validation.Standard.Numerics;
