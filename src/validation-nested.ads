with Validation.Identifiers;
with Validation.Phases;
with Validation.Messages;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Nested  (generic)
--
--  Nested object validation (§35, §37): run a sub-validator on a nested record
--  field and embed its issues into the parent result, rebased under the field
--  path (e.g. $.address.postcode). The nested validator keeps its own validator
--  and rule identities; only the paths are rebased.
--
--  The Optional child handles §36 presence semantics: an absent optional value
--  skips the nested validator; an absent required value emits one presence
--  issue and does not run the nested validator.
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
   with package Val is new Validation.Validators (Subject_Type);
   type Nested_Type is private;
   with package Nested_Val is new Validation.Validators (Nested_Type);
   with function Get (Subject : Subject_Type) return Nested_Type;
package Validation.Nested is

   function Rule
     (Field     : Identifiers.Field_Id;
      Rule_Id   : Identifiers.Rule_Id;
      Validator : Nested_Val.Validator;
      Phase     : Phases.Phase := Phases.Phase_Nested) return Val.Rule;

   generic
      with function Is_Present (Subject : Subject_Type) return Boolean;
   package Optional is
      function Rule
        (Field            : Identifiers.Field_Id;
         Rule_Id          : Identifiers.Rule_Id;
         Validator        : Nested_Val.Validator;
         Required         : Boolean := False;
         Required_Message : Identifiers.Message_Id := Messages.Required;
         Phase            : Phases.Phase := Phases.Phase_Nested) return Val.Rule;
   end Optional;

end Validation.Nested;
