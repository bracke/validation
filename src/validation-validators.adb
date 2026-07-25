package body Validation.Validators is

   package Validator_Ids renames Identifiers.Validator_Ids;
   package Rule_Ids renames Identifiers.Rule_Ids;
   package Category_Ids renames Identifiers.Issue_Category_Ids;
   package Message_Ids renames Identifiers.Message_Ids;
   package Field_Ids renames Identifiers.Field_Ids;
   package Group_Ids renames Identifiers.Rule_Group_Ids;
   package Prof renames Validation.Profiles;

   use type Issues.Severity;
   use type Provenance.Provenance_Mode;

   function Node_Config (Item : Stored_Rule) return Rule_Config is
     (Item.Held.Element.Config);

   function Default_Options return Execution_Options is
     (Policy          => Accumulate_All,
      Provenance_Mode => Provenance.Standard,
      On_Fault        => Propagate,
      Profiles        => Prof.Empty_Set);

   ---------------------------------------------------------------------------
   --  Rule output
   ---------------------------------------------------------------------------

   procedure Emit
     (Output   : in out Rule_Output;
      Level    : Severity;
      Category : Identifiers.Issue_Category_Id;
      Message  : Messages.Message;
      Primary  : Paths.Path;
      Related  : Path_Array)
   is
      --  Apply any active-profile severity override (§34).
      Effective : constant Severity :=
        Prof.Effective_Severity (Output.Profiles, Output.Rule, Level);
      Ord  : constant Positive := Output.Ordinal + 1;
      Prov : Provenance.Provenance;
   begin
      if Output.Prov_Mode = Provenance.Standard then
         declare
            PB : constant Provenance.Provenance_Builder :=
              Provenance.Begin_Standard
                (Output.Validator_Id, Output.Rule, Ord, Output.Phase,
                 Output.Decl);
         begin
            Prov := Provenance.Build (PB);
         end;
      else
         Prov :=
           Provenance.Make_Minimal (Output.Validator_Id, Output.Rule, Ord);
      end if;

      declare
         IB    : Issues.Issue_Builder :=
           Issues.Begin_Issue
             (Ord, Output.Validator_Id, Output.Rule, Effective, Category,
              Primary, Message, Prov);
         Added : Boolean;
      begin
         for Related_Path of Related loop
            Issues.Add_Related_Path (IB, Related_Path, Added);
         end loop;
         Issues.Append (Output.Issues, Issues.Build (IB));
      end;
      Output.Ordinal := Ord;
      if Effective = Issues.Error and then Output.Stop_On_Error then
         Output.Stopped := True;
      end if;
   end Emit;

   procedure Add_Issue
     (Output        : in out Rule_Output;
      Level         : Severity;
      Category      : Identifiers.Issue_Category_Id;
      Message       : Messages.Message;
      Relative_Path : Paths.Path := Paths.Empty_Relative)
   is
      Primary : constant Paths.Path :=
        (if Paths.Segment_Count (Relative_Path) = 0 then Output.Base
         else Paths.Concatenate (Output.Base, Relative_Path));
   begin
      Emit (Output, Level, Category, Message, Primary, []);
   end Add_Issue;

   procedure Add_Issue_At_Field
     (Output   : in out Rule_Output;
      Field    : Identifiers.Field_Id;
      Level    : Severity;
      Category : Identifiers.Issue_Category_Id;
      Message  : Messages.Message) is
   begin
      Emit (Output, Level, Category, Message,
            Paths.Append_Field (Output.Base, Field), []);
   end Add_Issue_At_Field;

   procedure Add_Rebased_Issue
     (Output : in out Rule_Output;
      Source : Issues.Issue;
      Under  : Paths.Path)
   is
      Ord : constant Positive := Output.Ordinal + 1;
   begin
      Issues.Append (Output.Issues, Issues.Rebased (Source, Under, Ord));
      Output.Ordinal := Ord;
      if Issues.Level (Source) = Issues.Error and then Output.Stop_On_Error then
         Output.Stopped := True;
      end if;
   end Add_Rebased_Issue;

   procedure Add_Issue_With_Related
     (Output        : in out Rule_Output;
      Level         : Severity;
      Category      : Identifiers.Issue_Category_Id;
      Message       : Messages.Message;
      Related       : Path_Array;
      Relative_Path : Paths.Path := Paths.Empty_Relative)
   is
      Primary : constant Paths.Path :=
        (if Paths.Segment_Count (Relative_Path) = 0 then Output.Base
         else Paths.Concatenate (Output.Base, Relative_Path));
   begin
      Emit (Output, Level, Category, Message, Primary, Related);
   end Add_Issue_With_Related;

   ---------------------------------------------------------------------------
   --  Rule constructors
   ---------------------------------------------------------------------------

   package body Predicate_Rules is

      type P_Node is new Rule_Node with null record;

      overriding procedure Apply_Node
        (Node    : P_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);

      overriding procedure Apply_Node
        (Node    : P_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output)
      is
         pragma Unreferenced (Context);
      begin
         if not Check (Subject) then
            Add_Issue
              (Output, Node.Config.Level, Node.Config.Category,
               Messages.Make (Node.Config.Message));
         end if;
      end Apply_Node;

      function Make
        (Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id;
         Level    : Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Business_Rule;
         Phase    : Phases.Phase := Phases.Phase_Value) return Rule
      is
         N : P_Node;
      begin
         N.Config :=
           (Rule_Id => Rule_Id, Level => Level, Category => Category,
            Message => Message, Phase => Phase, Kind => Predicate_Kind,
            others => <>);
         return (Held => Node_Holders.To_Holder (N));
      end Make;

   end Predicate_Rules;

   package body Field_Rules is

      type F_Node is new Rule_Node with null record;

      overriding procedure Apply_Node
        (Node    : F_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);

      overriding procedure Apply_Node
        (Node    : F_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output)
      is
         pragma Unreferenced (Context);
      begin
         if not Check (Get (Subject)) then
            Add_Issue_At_Field
              (Output, Node.Config.Field, Node.Config.Level,
               Node.Config.Category, Messages.Make (Node.Config.Message));
         end if;
      end Apply_Node;

      function Make
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id;
         Level    : Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
         Phase    : Phases.Phase := Phases.Phase_Value) return Rule
      is
         N : F_Node;
      begin
         N.Config :=
           (Rule_Id => Rule_Id, Level => Level, Category => Category,
            Message => Message, Phase => Phase, Kind => Field_Kind,
            Field => Field, others => <>);
         return (Held => Node_Holders.To_Holder (N));
      end Make;

   end Field_Rules;

   package body Custom_Rules is

      type C_Node is new Rule_Node with null record;

      overriding procedure Apply_Node
        (Node    : C_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);

      overriding procedure Apply_Node
        (Node    : C_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output)
      is
         pragma Unreferenced (Node);
      begin
         Apply (Subject, Context, Output);
      end Apply_Node;

      function Make
        (Rule_Id : Identifiers.Rule_Id;
         Phase   : Phases.Phase := Phases.Phase_Value) return Rule
      is
         N : C_Node;
      begin
         N.Config :=
           (Rule_Id => Rule_Id, Kind => Custom_Kind, Phase => Phase,
            others => <>);
         return (Held => Node_Holders.To_Holder (N));
      end Make;

   end Custom_Rules;

   package body Parameterized_Rules is

      type PP_Node is new Rule_Node with record
         Params : Params_Type;
      end record;

      overriding procedure Apply_Node
        (Node    : PP_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);

      overriding procedure Apply_Node
        (Node    : PP_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output) is
      begin
         Apply (Subject, Node.Params, Context, Output);
      end Apply_Node;

      function Make
        (Params  : Params_Type;
         Rule_Id : Identifiers.Rule_Id;
         Phase   : Phases.Phase := Phases.Phase_Value) return Rule
      is
         N : PP_Node;
      begin
         N.Config :=
           (Rule_Id => Rule_Id, Kind => Custom_Kind, Phase => Phase,
            others => <>);
         N.Params := Params;
         return (Held => Node_Holders.To_Holder (N));
      end Make;

   end Parameterized_Rules;

   ---------------------------------------------------------------------------
   --  Decorators
   ---------------------------------------------------------------------------

   function With_Config (Rule : Validators.Rule; Config : Rule_Config)
     return Validators.Rule
   is
      Node : Rule_Node'Class := Rule.Held.Element;
   begin
      Node.Config := Config;
      return (Held => Node_Holders.To_Holder (Node));
   end With_Config;

   function In_Group
     (Rule : Validators.Rule; Group : Identifiers.Rule_Group_Id)
      return Validators.Rule
   is
      Config : Rule_Config := Rule.Held.Element.Config;
   begin
      Config.Group := Group;
      return With_Config (Rule, Config);
   end In_Group;

   function Requires
     (Rule : Validators.Rule; Passed : Identifiers.Rule_Id)
      return Validators.Rule
   is
      Config : Rule_Config := Rule.Held.Element.Config;
   begin
      Config.Prereq := (Kind => Rule_Passed, Rule => Passed);
      return With_Config (Rule, Config);
   end Requires;

   package body Conditional is

      type Cond_Node is new Rule_Node with record
         Inner  : Node_Holders.Holder;
         Negate : Boolean := False;
      end record;

      overriding procedure Apply_Node
        (Node    : Cond_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);

      overriding procedure Apply_Node
        (Node    : Cond_Node;
         Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output)
      is
         Applicable : Boolean := Condition (Subject, Context);
      begin
         if Node.Negate then
            Applicable := not Applicable;
         end if;
         if Applicable then
            Apply_Node (Node.Inner.Element, Subject, Context, Output);
         end if;
      end Apply_Node;

      function Wrap (Rule : Validators.Rule; Negate : Boolean)
        return Validators.Rule
      is
         Node : Cond_Node;
      begin
         Node.Config := Rule.Held.Element.Config;
         Node.Inner := Rule.Held;
         Node.Negate := Negate;
         return (Held => Node_Holders.To_Holder (Node));
      end Wrap;

      function When_Applicable (Rule : Validators.Rule) return Validators.Rule is
        (Wrap (Rule, Negate => False));
      function Unless_Applicable (Rule : Validators.Rule) return Validators.Rule is
        (Wrap (Rule, Negate => True));

   end Conditional;

   ---------------------------------------------------------------------------
   --  Builder / finalization
   ---------------------------------------------------------------------------

   function Start (Id : Identifiers.Validator_Id) return Builder is
     (Id => Id, Rules => Stored_Vectors.Empty_Vector);

   procedure Add (Builder : in out Validators.Builder; Rule : Validators.Rule) is
   begin
      Builder.Rules.Append
        (Stored_Rule'(Held => Rule.Held,
                      Decl => Natural (Builder.Rules.Length) + 1));
   end Add;

   function Extend
     (Base : Validator; Id : Identifiers.Validator_Id) return Builder is
     (Id => Id, Rules => Base.Rules);

   procedure Disable
     (Builder : in out Validators.Builder; Rule_Id : Identifiers.Rule_Id)
   is
      Position : Natural := 1;
   begin
      while Position <= Natural (Builder.Rules.Length) loop
         if Rule_Ids."="
              (Node_Config (Builder.Rules (Position)).Rule_Id, Rule_Id)
         then
            Builder.Rules.Delete (Position);
         else
            Position := Position + 1;
         end if;
      end loop;
   end Disable;

   function Compute_Fingerprint (Item : Validator) return Fingerprints.Fingerprint
   is
      B : Fingerprints.Builder := Fingerprints.Start;
   begin
      Fingerprints.Add_Tag (B, "validator");
      Fingerprints.Add_String (B, Validator_Ids.Image (Item.Id));
      for S of Item.Rules loop
         declare
            Cfg : constant Rule_Config := Node_Config (S);
         begin
            Fingerprints.Add_Tag (B, "rule");
            Fingerprints.Add_String (B, Rule_Ids.Image (Cfg.Rule_Id));
            Fingerprints.Add_Natural (B, Rule_Kind'Pos (Cfg.Kind));
            Fingerprints.Add_Natural (B, Phases.Phase'Pos (Cfg.Phase));
            Fingerprints.Add_Natural (B, S.Decl);
            Fingerprints.Add_Natural (B, Severity'Pos (Cfg.Level));
            Fingerprints.Add_String (B, Category_Ids.Image (Cfg.Category));
            Fingerprints.Add_String (B, Message_Ids.Image (Cfg.Message));
            Fingerprints.Add_String (B, Field_Ids.Image (Cfg.Field));
         end;
      end loop;
      return Fingerprints.Finish (B);
   end Compute_Fingerprint;

   function Finalize (Builder : Validators.Builder) return Finalization is
      Result : Finalization;
      Count  : constant Natural := Natural (Builder.Rules.Length);
   begin
      if Validator_Ids.Is_Null (Builder.Id) then
         Result.Succeeded := False;
         Result.Errors.Append (Errors.Make (Errors.Empty_Validator_Id));
         return Result;
      end if;

      for I in 1 .. Count loop
         for J in I + 1 .. Count loop
            if Rule_Ids."="
                 (Node_Config (Builder.Rules (I)).Rule_Id,
                  Node_Config (Builder.Rules (J)).Rule_Id)
            then
               Result.Succeeded := False;
               Result.Errors.Append
                 (Errors.With_Rule
                    (Errors.Make (Errors.Duplicate_Rule_Id),
                     Node_Config (Builder.Rules (J)).Rule_Id));
            end if;
         end loop;
      end loop;

      if not Result.Succeeded then
         return Result;
      end if;

      Result.Value.Id := Builder.Id;
      Result.Value.Rules := Builder.Rules;
      Result.Value.FP := Compute_Fingerprint (Result.Value);
      return Result;
   end Finalize;

   function Is_Success (Item : Finalization) return Boolean is
     (Item.Succeeded);
   function Get_Validator (Item : Finalization) return Validator is
     (Item.Value);
   function Error_Count (Item : Finalization) return Natural is
     (Natural (Item.Errors.Length));
   function Error_At
     (Item : Finalization; Position : Positive) return Errors.Error is
     (Item.Errors (Position));

   ---------------------------------------------------------------------------
   --  Execution
   ---------------------------------------------------------------------------

   function Validate
     (Subject   : Subject_Type;
      Validator : Validators.Validator;
      Context   : Contexts.Context;
      Options   : Execution_Options := Default_Options) return Results.Result
   is
      type Outcome_Kind is (Ran_Passed, Ran_Failed, Was_Skipped);

      Count    : constant Natural := Natural (Validator.Rules.Length);
      Order    : array (1 .. Count) of Positive;
      Outcomes : array (1 .. Count) of Outcome_Kind := [others => Was_Skipped];
      Output   : Rule_Output;
      Fault    : Boolean := False;
      Filtering : constant Boolean := Prof.Count (Options.Profiles) > 0;

      function Less (A, B : Positive) return Boolean is
         Ca : constant Rule_Config := Node_Config (Validator.Rules (A));
         Cb : constant Rule_Config := Node_Config (Validator.Rules (B));
      begin
         if Phases.Phase'Pos (Ca.Phase) /= Phases.Phase'Pos (Cb.Phase) then
            return Phases.Phase'Pos (Ca.Phase) < Phases.Phase'Pos (Cb.Phase);
         end if;
         return Validator.Rules (A).Decl < Validator.Rules (B).Decl;
      end Less;

      function Index_Of (Rule_Id : Identifiers.Rule_Id) return Natural is
      begin
         for I in 1 .. Count loop
            if Rule_Ids."=" (Node_Config (Validator.Rules (I)).Rule_Id, Rule_Id)
            then
               return I;
            end if;
         end loop;
         return 0;
      end Index_Of;

      function Group_Active (Config : Rule_Config) return Boolean is
        (not Filtering
         or else Group_Ids.Is_Null (Config.Group)
         or else Prof.Is_Group_Active (Options.Profiles, Config.Group));

      function Prereq_Met (Config : Rule_Config) return Boolean is
         Index : Natural;
      begin
         if Config.Prereq.Kind = Always then
            return True;
         end if;
         Index := Index_Of (Config.Prereq.Rule);
         return Index /= 0 and then Outcomes (Index) = Ran_Passed;
      end Prereq_Met;
   begin
      Output.Validator_Id := Validator.Id;
      Output.Stop_On_Error := Options.Policy = Stop_On_First_Error;
      Output.Prov_Mode := Options.Provenance_Mode;
      Output.Issues := Issues.Empty_Collection;
      Output.Profiles := Options.Profiles;

      for I in 1 .. Count loop
         Order (I) := I;
      end loop;
      for I in 2 .. Count loop
         declare
            Key : constant Positive := Order (I);
            J   : Integer := I - 1;
         begin
            while J >= 1 and then Less (Key, Order (J)) loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;

      for K in 1 .. Count loop
         exit when Output.Stopped or else Fault;
         declare
            Idx  : constant Positive := Order (K);
            Node : constant Rule_Node'Class :=
              Validator.Rules (Idx).Held.Element;
         begin
            if not (Group_Active (Node.Config)
                    and then Prereq_Met (Node.Config))
            then
               Outcomes (Idx) := Was_Skipped;
            else
               Output.Rule := Node.Config.Rule_Id;
               Output.Phase := Node.Config.Phase;
               Output.Decl := Validator.Rules (Idx).Decl;
               Output.Base := Paths.Root;
               declare
                  Before : constant Natural := Issues.Count (Output.Issues);
               begin
                  if Options.On_Fault = Convert_To_Invocation_Error then
                     begin
                        Apply_Node (Node, Subject, Context, Output);
                     exception
                        when others =>
                           Fault := True;
                     end;
                  else
                     Apply_Node (Node, Subject, Context, Output);
                  end if;
                  if not Fault then
                     Outcomes (Idx) :=
                       (if Issues.Count (Output.Issues) > Before
                        then Ran_Failed else Ran_Passed);
                  end if;
               end;
            end if;
         end;
      end loop;

      declare
         Status : constant Results.Execution_Status :=
           (if Fault then Results.Invocation_Failed
            elsif Output.Stopped then Results.Stopped
            else Results.Completed);
         RB : Results.Result_Builder := Results.Begin_Result (Status);
      begin
         for P in 1 .. Issues.Count (Output.Issues) loop
            Results.Add_Issue (RB, Issues.Element (Output.Issues, P));
         end loop;
         if Fault then
            Results.Add_Invocation_Error
              (RB, Errors.With_Validator
                     (Errors.Make (Errors.Callback_Fault), Validator.Id));
         end if;
         if Output.Stopped then
            Results.Set_Stop
              (RB,
               (Stopped => True, Scope => Results.First_Error,
                Has_Path => False, others => <>));
         end if;
         Results.Set_Validator_Fingerprint (RB, Validator.FP);
         return Results.Build (RB);
      end;
   end Validate;

   ---------------------------------------------------------------------------
   --  Introspection
   ---------------------------------------------------------------------------

   function Id (Item : Validator) return Identifiers.Validator_Id is (Item.Id);
   function Rule_Count (Item : Validator) return Natural is
     (Natural (Item.Rules.Length));
   function Fingerprint (Item : Validator) return Fingerprints.Fingerprint is
     (Item.FP);

end Validation.Validators;
