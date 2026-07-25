with Validation.Identifiers;
with Validation.Phases;
with Validation.Issues;
with Validation.Messages;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Collections  (generic)
--
--  Generic, adapter-driven collection validation (§38-40) producing rules for a
--  specific Validators instance. The adapter is the three iteration formals
--  (Count + Item over a random-access collection) plus the field accessor;
--  arrays, vectors, lists, and ordered/hashed maps and sets are supported by
--  supplying an Item accessor that yields elements in a CANONICAL, deterministic
--  order (VAL-INV-021 — hashed containers must not use bucket order).
--
--  Element paths use zero-based ordinal indices: field[0], field[1], ....
--
--  Phase 7 provides cardinality, per-element predicates, uniqueness (typed key
--  projection with a related path to the first occurrence), quantifiers, and a
--  sum aggregate. Ordering and full nested-record element validation arrive with
--  Phase 8.
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
   with package Val is new Validation.Validators (Subject_Type);
   type Collection_Type is private;
   type Element_Type is private;
   with function Get (Subject : Subject_Type) return Collection_Type;
   with function Count (Collection : Collection_Type) return Natural;
   with function Item
     (Collection : Collection_Type; Index : Positive) return Element_Type;
package Validation.Collections is

   ---------------------------------------------------------------------------
   --  Cardinality (§40)
   ---------------------------------------------------------------------------

   function Min_Count
     (Field    : Identifiers.Field_Id;
      Min      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Minimum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;

   function Max_Count
     (Field    : Identifiers.Field_Id;
      Max      : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Maximum;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;

   function Exact_Count
     (Field    : Identifiers.Field_Id;
      Expected : Natural;
      Rule_Id  : Identifiers.Rule_Id;
      Message  : Identifiers.Message_Id := Messages.Collection_Exact;
      Level    : Issues.Severity := Issues.Error;
      Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
      Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;

   ---------------------------------------------------------------------------
   --  Per-element predicate (§40)
   ---------------------------------------------------------------------------

   generic
      with function Check (Element : Element_Type) return Boolean;
   package Each_Element is
      function Rule
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Element;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Value;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
   end Each_Element;

   ---------------------------------------------------------------------------
   --  Uniqueness (§40) — one issue per duplicate after the first
   ---------------------------------------------------------------------------

   generic
      type Key_Type is private;
      with function Key_Of (Element : Element_Type) return Key_Type;
      with function Key_Equal (Left, Right : Key_Type) return Boolean;
   package Unique is
      function Rule
        (Field    : Identifiers.Field_Id;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Duplicate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Duplicate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
   end Unique;

   ---------------------------------------------------------------------------
   --  Quantifiers (§40) over an element predicate
   ---------------------------------------------------------------------------

   generic
      with function Check (Element : Element_Type) return Boolean;
   package Quantifier is
      function At_Least
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
      function At_Most
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
      function Exactly
        (Field    : Identifiers.Field_Id;
         N        : Natural;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Quantifier;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
   end Quantifier;

   ---------------------------------------------------------------------------
   --  Aggregate (§40) — caller-provided integer projection
   ---------------------------------------------------------------------------

   generic
      with function Project (Element : Element_Type) return Long_Long_Integer;
   package Aggregate is
      function Sum_At_Most
        (Field    : Identifiers.Field_Id;
         Max      : Long_Long_Integer;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Aggregate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
      function Sum_Equals
        (Field    : Identifiers.Field_Id;
         Expected : Long_Long_Integer;
         Rule_Id  : Identifiers.Rule_Id;
         Message  : Identifiers.Message_Id := Messages.Collection_Aggregate;
         Level    : Issues.Severity := Issues.Error;
         Category : Identifiers.Issue_Category_Id := Issues.Category_Aggregate;
         Phase    : Phases.Phase := Phases.Phase_Collection) return Val.Rule;
   end Aggregate;

end Validation.Collections;
