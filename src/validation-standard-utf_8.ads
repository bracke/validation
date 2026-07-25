------------------------------------------------------------------------------
--  Validation.Standard.UTF_8
--
--  The one audited UTF-8 decoder (§41). A String is treated as a byte sequence.
--  Is_Valid rejects overlong encodings, surrogate code points, out-of-range
--  code points, truncated sequences, and stray continuation bytes. Scalar_Count
--  (code-point count) is meaningful only for valid input, so length validation
--  must validate UTF-8 first (an encoding issue, not a misleading length one).
------------------------------------------------------------------------------

package Validation.Standard.UTF_8 is

   function Is_Valid (Item : String) return Boolean;

   function Scalar_Count (Item : String) return Natural
     with Pre => Is_Valid (Item);

end Validation.Standard.UTF_8;
