with Validation.Identifiers;
with Validation.Contexts;
with Validation.Results;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Recursive  (generic)
--
--  Validates a recursive object structure (§37): each node is validated with a
--  node validator, and issues are rebased under the node's path
--  (children[i].children[j]...). Cycles are detected on the ACTIVE PATH using a
--  caller-supplied stable Identity (never a pointer address, VAL-INV-015).
--
--  Cycle actions: Report_Issue_And_Skip (default — one graph.cycle issue with a
--  related path to the first occurrence, then skip the subtree), Skip_Silently,
--  or Invocation_Failure. Depth and visit limits produce controlled
--  incompleteness (VAL-INV-016), never an infinite loop.
------------------------------------------------------------------------------

generic
   type Node_Type is private;
   with package Node_Val is new Validation.Validators (Node_Type);
   with function Child_Count (Node : Node_Type) return Natural;
   with function Child (Node : Node_Type; Index : Positive) return Node_Type;
   with function Identity (Node : Node_Type) return String;
   Children_Field : Identifiers.Field_Id;
package Validation.Recursive is

   type Cycle_Action is
     (Report_Issue_And_Skip, Skip_Silently, Invocation_Failure);

   function Validate_Tree
     (Root       : Node_Type;
      Validator  : Node_Val.Validator;
      Context    : Validation.Contexts.Context;
      On_Cycle   : Cycle_Action := Report_Issue_And_Skip;
      Max_Depth  : Positive := 32;
      Max_Visits : Positive := 10_000) return Results.Result;

end Validation.Recursive;
