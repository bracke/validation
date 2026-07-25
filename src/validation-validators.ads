private with Ada.Containers.Vectors;
private with Ada.Containers.Indefinite_Holders;
with Validation.Identifiers;
with Validation.Phases;
with Validation.Paths;
with Validation.Messages;
with Validation.Issues;
with Validation.Errors;
with Validation.Provenance;
with Validation.Contexts;
with Validation.Profiles;
with Validation.Results;
with Validation.Fingerprints;

------------------------------------------------------------------------------
--  Validation.Validators  (generic over the subject type)
--
--  The typed validator engine (§6, §20, §23). A validator is subject-typed,
--  immutable after finalization, deterministic, and fingerprinted. Rules are
--  captured by generic instantiation into immutable class-wide nodes (ADR-014)
--  and emit issues ONLY through the engine-controlled Rule_Output — the engine
--  supplies the validator id, rule id, ordinal, and provenance; a rule supplies
--  only the semantic fields (VAL-INV-007, VAL-INV-026). Rules never construct
--  issues directly and never mutate the subject (VAL-INV-013).
--
--  Phase 4 is the MINIMAL engine: predicate rules, field-accessor rules, and
--  general custom rules; deterministic phase order; Accumulate_All and
--  Stop_On_First_Error; callback-fault handling; a validator fingerprint; and
--  basic introspection. Conditions, prerequisites, nested/collection rules,
--  and profiles arrive in later phases.
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
package Validation.Validators is

   subtype Severity is Issues.Severity;

   ---------------------------------------------------------------------------
   --  Execution options
   ---------------------------------------------------------------------------

   type Execution_Policy is (Accumulate_All, Stop_On_First_Error);
   type Fault_Mode is (Propagate, Convert_To_Invocation_Error);

   type Execution_Options is record
      Policy          : Execution_Policy := Accumulate_All;
      Provenance_Mode : Provenance.Provenance_Mode := Provenance.Standard;
      On_Fault        : Fault_Mode := Propagate;
      --  Active profile set (§34). Empty => no profile filtering (all rules
      --  run). Non-empty => a rule runs iff its group is the default (unlabeled)
      --  or is active in the set; severities are overridden per the set.
      Profiles        : Validation.Profiles.Profile_Set;
   end record;

   function Default_Options return Execution_Options;

   ---------------------------------------------------------------------------
   --  Engine-controlled rule output
   ---------------------------------------------------------------------------

   type Rule_Output is limited private;

   --  Emit an issue at the current path (optionally extended by a relative
   --  path). The engine attributes it to the current rule and assigns the
   --  ordinal and provenance.
   procedure Add_Issue
     (Output        : in out Rule_Output;
      Level         : Severity;
      Category      : Identifiers.Issue_Category_Id;
      Message       : Messages.Message;
      Relative_Path : Paths.Path := Paths.Empty_Relative);

   procedure Add_Issue_At_Field
     (Output   : in out Rule_Output;
      Field    : Identifiers.Field_Id;
      Level    : Severity;
      Category : Identifiers.Issue_Category_Id;
      Message  : Messages.Message);

   ---------------------------------------------------------------------------
   --  Rules
   ---------------------------------------------------------------------------

   type Rule is private;

   --  A whole-subject predicate; on False, emits one issue at the root path.
   generic
      with function Check (Subject : Subject_Type) return Boolean;
   package Predicate_Rules is
      function Make
        (Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id;
         Level    : Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Business_Rule;
         Phase    : Phases.Phase := Phases.Phase_Value) return Rule;
   end Predicate_Rules;

   --  A field-accessor predicate; on False, emits one issue at the field path.
   generic
      type Field_Type is private;
      with function Get (Subject : Subject_Type) return Field_Type;
      with function Check (Value : Field_Type) return Boolean;
   package Field_Rules is
      function Make
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id;
         Level    : Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
         Phase    : Phases.Phase := Phases.Phase_Value) return Rule;
   end Field_Rules;

   --  A general rule that emits issues through Rule_Output.
   generic
      with procedure Apply
        (Subject : Subject_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);
   package Custom_Rules is
      function Make
        (Rule_Id : Identifiers.Rule_Id;
         Phase   : Phases.Phase := Phases.Phase_Value) return Rule;
   end Custom_Rules;

   --  A rule whose behaviour is parameterized by a RUNTIME value stored
   --  immutably in the node. Apply (a library-level subprogram) receives the
   --  subject, the stored params, and the output. This is how standard
   --  validators (min length, range, ...) carry their bounds without an
   --  access-to-subprogram closure.
   generic
      type Params_Type is private;
      with procedure Apply
        (Subject : Subject_Type;
         Params  : Params_Type;
         Context : Contexts.Context;
         Output  : in out Rule_Output);
   package Parameterized_Rules is
      function Make
        (Params  : Params_Type;
         Rule_Id : Identifiers.Rule_Id;
         Phase   : Phases.Phase := Phases.Phase_Value) return Rule;
   end Parameterized_Rules;

   ---------------------------------------------------------------------------
   --  Rule decorators (return a new rule; the original is unchanged)
   ---------------------------------------------------------------------------

   --  Assign the rule to a group (§34). Unlabeled rules belong to the default
   --  group and always run; labeled rules run only when their group is active
   --  in the profile set.
   function In_Group
     (Rule : Validators.Rule; Group : Identifiers.Rule_Group_Id)
      return Validators.Rule;

   --  Run this rule only if another (earlier) local rule ran and passed (§26).
   --  The canonical use: a length/format rule that must not run when the
   --  required-presence rule already failed.
   function Requires
     (Rule : Validators.Rule; Passed : Identifiers.Rule_Id)
      return Validators.Rule;

   --  Condition wrapper (§25): applies the wrapped rule only when Condition
   --  holds (When_Applicable) or does not hold (Unless_Applicable). The
   --  condition is a pure applicability function and emits nothing itself.
   generic
      with function Condition
        (Subject : Subject_Type; Context : Contexts.Context) return Boolean;
   package Conditional is
      function When_Applicable (Rule : Validators.Rule) return Validators.Rule;
      function Unless_Applicable (Rule : Validators.Rule) return Validators.Rule;
   end Conditional;

   ---------------------------------------------------------------------------
   --  Builder and finalization
   ---------------------------------------------------------------------------

   type Builder is private;
   type Validator is private;

   function Start (Id : Identifiers.Validator_Id) return Builder;
   procedure Add (Builder : in out Validators.Builder; Rule : Validators.Rule);

   --  Composition (§43): start a builder pre-loaded with a finalized
   --  validator's rules, and remove rules by id. Component validators are
   --  never mutated.
   function Extend
     (Base : Validator; Id : Identifiers.Validator_Id) return Builder;
   procedure Disable
     (Builder : in out Validators.Builder; Rule_Id : Identifiers.Rule_Id);

   type Finalization is private;

   function Finalize (Builder : Validators.Builder) return Finalization;
   function Is_Success (Item : Finalization) return Boolean;
   function Get_Validator (Item : Finalization) return Validator
     with Pre => Is_Success (Item);
   function Error_Count (Item : Finalization) return Natural;
   function Error_At
     (Item : Finalization; Position : Positive) return Errors.Error
     with Pre => Position <= Error_Count (Item);

   ---------------------------------------------------------------------------
   --  Execution
   ---------------------------------------------------------------------------

   function Validate
     (Subject   : Subject_Type;
      Validator : Validators.Validator;
      Context   : Contexts.Context;
      Options   : Execution_Options := Default_Options) return Results.Result;

   ---------------------------------------------------------------------------
   --  Introspection
   ---------------------------------------------------------------------------

   function Id (Item : Validator) return Identifiers.Validator_Id;
   function Rule_Count (Item : Validator) return Natural;
   function Fingerprint (Item : Validator) return Fingerprints.Fingerprint;

private

   type Rule_Kind is (Predicate_Kind, Field_Kind, Custom_Kind);

   type Prereq_Kind is (Always, Rule_Passed);

   type Prerequisite is record
      Kind : Prereq_Kind := Always;
      Rule : Identifiers.Rule_Id;
   end record;

   type Rule_Config is record
      Rule_Id   : Identifiers.Rule_Id;
      Level     : Severity := Issues.Error;
      Category  : Identifiers.Issue_Category_Id;
      Message   : Identifiers.Message_Id;
      Phase     : Phases.Phase := Phases.Phase_Value;
      Kind      : Rule_Kind := Predicate_Kind;
      Field     : Identifiers.Field_Id;
      --  Group is Null_Id for the default (always-active) group.
      Group     : Identifiers.Rule_Group_Id;
      Prereq    : Prerequisite;
   end record;

   type Rule_Node is abstract tagged record
      Config : Rule_Config;
   end record;

   procedure Apply_Node
     (Node    : Rule_Node;
      Subject : Subject_Type;
      Context : Contexts.Context;
      Output  : in out Rule_Output) is abstract;

   package Node_Holders is new Ada.Containers.Indefinite_Holders
     (Rule_Node'Class);

   type Rule is record
      Held : Node_Holders.Holder;
   end record;

   type Stored_Rule is record
      Held : Node_Holders.Holder;
      Decl : Positive := 1;
   end record;

   package Stored_Vectors is new Ada.Containers.Vectors (Positive, Stored_Rule);

   type Validator is record
      Id    : Identifiers.Validator_Id;
      Rules : Stored_Vectors.Vector;
      FP    : Fingerprints.Fingerprint;
   end record;

   type Builder is record
      Id    : Identifiers.Validator_Id;
      Rules : Stored_Vectors.Vector;
   end record;

   package Error_Vectors is new Ada.Containers.Vectors
     (Positive, Errors.Error, Errors."=");

   type Finalization is record
      Succeeded : Boolean := True;
      Value     : Validator;
      Errors    : Error_Vectors.Vector;
   end record;

   --  Mutable per-invocation engine state, held by value in the limited output
   --  object the engine reuses across rules (never global, VAL-INV-020; no
   --  address identity, VAL-INV-015). A rule receives it as `in out` and may
   --  only accumulate through Add_Issue / Add_Issue_At_Field.
   type Rule_Output is limited record
      Issues        : Validation.Issues.Issue_Collection;
      Ordinal       : Natural := 0;
      Validator_Id  : Identifiers.Validator_Id;
      Stop_On_Error : Boolean := False;
      Stopped       : Boolean := False;
      Prov_Mode     : Provenance.Provenance_Mode := Provenance.Standard;
      Rule          : Identifiers.Rule_Id;
      Phase         : Phases.Phase := Phases.Phase_Value;
      Decl          : Positive := 1;
      Base          : Paths.Path;
      Profiles      : Validation.Profiles.Profile_Set;
   end record;

end Validation.Validators;
