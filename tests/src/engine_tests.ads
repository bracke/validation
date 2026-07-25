with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 4 tests: the minimal typed validator engine, exercised end to end
--  through the public API with an application-defined record.
package Engine_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Valid_Subject (T : in out Fixture);
   procedure Test_Invalid_Subject (T : in out Fixture);
   procedure Test_Phase_Order (T : in out Fixture);
   procedure Test_Stop_On_First_Error (T : in out Fixture);
   procedure Test_Finalize_Errors (T : in out Fixture);
   procedure Test_Callback_Fault (T : in out Fixture);
   procedure Test_Fingerprint (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Engine_Tests;
