with Validation.Identifiers;
with Validation.Phases;
with Validation.Issues;
with Validation.Messages;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Standard.Text  (generic)
--
--  Standard text validators over a String field accessor (§41), producing rules
--  for a specific Validators instance. Length checks use the Ada String
--  element count (bytes). Valid_UTF8 is the encoding check; the actual field
--  value is never placed in issue arguments (only the configured bound).
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
   with package Val is new Validation.Validators (Subject_Type);
   with function Get (Subject : Subject_Type) return String;
package Validation.Standard.Text is

   function Min_Length
     (Field    : Identifiers.Field_Id;
      Min      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Max_Length
     (Field    : Identifiers.Field_Id;
      Max      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Exact_Length
     (Field    : Identifiers.Field_Id;
      Length   : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Length_Exact;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Length;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Non_Empty
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Not_Empty;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Presence;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Non_Blank
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Not_Blank;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Presence;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

   function Valid_UTF8
     (Field    : Identifiers.Field_Id;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Invalid_UTF8;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Encoding;
      Phase    : Phases.Phase := Phases.Phase_Value) return Val.Rule;

end Validation.Standard.Text;
