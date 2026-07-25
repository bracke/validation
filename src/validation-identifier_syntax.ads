------------------------------------------------------------------------------
--  Validation.Identifier_Syntax
--
--  Shared syntactic rule for every Validation identifier (§7). ASCII only,
--  1 .. Max_Length bytes, first character an ASCII letter or digit, remaining
--  characters letters, digits, or one of  .  _  -  :  /  . Empty, whitespace,
--  control characters, and any other byte are rejected deterministically.
--
--  Specific identifier categories may impose stricter rules on top of this.
------------------------------------------------------------------------------

package Validation.Identifier_Syntax
  with Pure, SPARK_Mode => On
is

   Max_Length : constant := 128;

   function Is_Valid (Text : String) return Boolean;

end Validation.Identifier_Syntax;
