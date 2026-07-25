------------------------------------------------------------------------------
--  Validation.Phases
--
--  The canonical execution phases (§24), shared by provenance, rules, and the
--  engine. Execution order is: phase ordinal, then declaration ordinal within a
--  validator, then traversal order, then issue occurrence ordinal. Literals are
--  prefixed to avoid clashing with same-named entities elsewhere (Value,
--  Object, ...).
------------------------------------------------------------------------------

package Validation.Phases
  with Pure
is

   type Phase is
     (Phase_Presence,
      Phase_Shape,
      Phase_Value,
      Phase_Nested,
      Phase_Collection,
      Phase_Cross_Field,
      Phase_Object,
      Phase_Deferred,
      Phase_Final);

end Validation.Phases;
