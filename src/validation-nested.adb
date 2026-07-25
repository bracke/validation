with Validation.Paths;
with Validation.Issues;
with Validation.Results;
with Validation.Contexts;

package body Validation.Nested is

   procedure Embed
     (Subject   : Subject_Type;
      Field     : Identifiers.Field_Id;
      Validator : Nested_Val.Validator;
      Context   : Validation.Contexts.Context;
      Output    : in out Val.Rule_Output)
   is
      Sub    : constant Results.Result :=
        Nested_Val.Validate (Get (Subject), Validator, Context);
      Prefix : constant Paths.Path := Paths.Append_Field (Paths.Root, Field);
   begin
      for Index in 1 .. Results.Issue_Count (Sub) loop
         Val.Add_Rebased_Issue (Output, Results.Issue_At (Sub, Index), Prefix);
      end loop;
   end Embed;

   type N_Params is record
      Field     : Identifiers.Field_Id;
      Validator : Nested_Val.Validator;
   end record;

   procedure Apply_N
     (Subject : Subject_Type;
      Params  : N_Params;
      Context : Validation.Contexts.Context;
      Output  : in out Val.Rule_Output) is
   begin
      Embed (Subject, Params.Field, Params.Validator, Context, Output);
   end Apply_N;

   package RN is new Val.Parameterized_Rules (N_Params, Apply_N);

   function Rule
     (Field     : Identifiers.Field_Id;
      Rule_Id   : Identifiers.Rule_Id;
      Validator : Nested_Val.Validator;
      Phase     : Phases.Phase := Phases.Phase_Nested) return Val.Rule is
     (RN.Make ((Field, Validator), Rule_Id, Phase));

   package body Optional is

      type O_Params is record
         Field            : Identifiers.Field_Id;
         Validator        : Nested_Val.Validator;
         Required         : Boolean;
         Required_Message : Identifiers.Message_Id;
      end record;

      procedure Apply_O
        (Subject : Subject_Type;
         Params  : O_Params;
         Context : Validation.Contexts.Context;
         Output  : in out Val.Rule_Output) is
      begin
         if Is_Present (Subject) then
            Embed (Subject, Params.Field, Params.Validator, Context, Output);
         elsif Params.Required then
            Val.Add_Issue_At_Field
              (Output, Params.Field, Issues.Error, Issues.Category_Presence,
               Messages.Make (Params.Required_Message));
         end if;
      end Apply_O;

      package RO is new Val.Parameterized_Rules (O_Params, Apply_O);

      function Rule
        (Field            : Identifiers.Field_Id;
         Rule_Id          : Identifiers.Rule_Id;
         Validator        : Nested_Val.Validator;
         Required         : Boolean := False;
         Required_Message : Identifiers.Message_Id := Messages.Required;
         Phase            : Phases.Phase := Phases.Phase_Nested) return Val.Rule
      is
        (RO.Make
           ((Field, Validator, Required, Required_Message), Rule_Id, Phase));

   end Optional;

end Validation.Nested;
