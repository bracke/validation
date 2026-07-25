------------------------------------------------------------------------------
--  Validation.Standard
--
--  Reusable standard validators (§41), implemented THROUGH the same public rule
--  abstractions in Validation.Validators that applications use (each is a
--  parameterized rule over a field accessor). This parent package holds only
--  the shared actual-value disclosure policy (§42): by default the ACTUAL field
--  value is excluded from issue arguments — only the configured bound (a public
--  value) is included. Passwords, tokens, and the like must never be disclosed.
------------------------------------------------------------------------------

package Validation.Standard
  with Pure
is

   type Actual_Disclosure is (Include_Actual, Exclude_Actual, Redact_Actual);

   Default_Disclosure : constant Actual_Disclosure := Exclude_Actual;

end Validation.Standard;
