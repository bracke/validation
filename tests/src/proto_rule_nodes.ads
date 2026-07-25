private with Ada.Containers.Indefinite_Holders;
private with Ada.Containers.Indefinite_Vectors;
private with Ada.Strings.Bounded;

------------------------------------------------------------------------------
--  Proto_Rule_Nodes  (Phase 0 feasibility prototype)
--
--  Proves the callback-storage strategy for Validation.Rules / Validators
--  (ADR-014 callback ownership): a finalized immutable rule stores its logic
--  as a class-wide node whose dispatching Evaluate CALLS a generic formal
--  subprogram. The predicate is therefore captured by the instantiation and
--  baked into a concrete node type — it is never stored as an
--  access-to-subprogram with local accessibility, so there is no dangling /
--  accessibility hazard and no global callback registry.
--
--  A Rule_Set stores several such nodes of different concrete types together
--  (heterogeneous immutable node storage), proving a validator can hold an
--  ordered list of class-wide rule nodes and evaluate them deterministically.
------------------------------------------------------------------------------

generic
   type Subject_Type (<>) is private;
package Proto_Rule_Nodes is

   Max_Message : constant := 128;

   type Rule is private;

   type Outcome is record
      Passed  : Boolean := True;
      Message : String (1 .. Max_Message) := [others => ' '];
      Length  : Natural := 0;
   end record;

   function Evaluate (R : Rule; Subject : Subject_Type) return Outcome;

   --  One predicate rule. The predicate and its failure message id are the
   --  generic parameters; Make returns an immutable Rule holding a node that
   --  dispatches to Predicate.
   generic
      with function Predicate (Subject : Subject_Type) return Boolean;
      Message_Id : String;
   package Predicate_Rule is
      function Make return Rule;
   end Predicate_Rule;

   --  An ordered immutable set of rules, evaluated in declaration order.
   type Rule_Set is private;

   function Empty_Set return Rule_Set;
   function Add (Set : Rule_Set; R : Rule) return Rule_Set;
   function Length (Set : Rule_Set) return Natural;

   --  Evaluate every rule; returns the first failing outcome, or a passing
   --  outcome if all pass. Deterministic: declaration order.
   function Evaluate_All
     (Set : Rule_Set; Subject : Subject_Type) return Outcome;

private

   package Msg_Strings is new Ada.Strings.Bounded.Generic_Bounded_Length
     (Max_Message);

   type Node is abstract tagged record
      Message : Msg_Strings.Bounded_String;
   end record;

   function Check (N : Node; Subject : Subject_Type) return Boolean is abstract;

   package Node_Holders is new Ada.Containers.Indefinite_Holders
     (Element_Type => Node'Class);

   type Rule is record
      Held : Node_Holders.Holder;
   end record;

   package Rule_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive, Element_Type => Rule);

   type Rule_Set is record
      Items : Rule_Vectors.Vector;
   end record;

end Proto_Rule_Nodes;
