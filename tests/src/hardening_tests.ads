with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 11 tests: determinism, property tests, fuzz targets (deterministic
--  LCG), fault injection, and ownership.
package Hardening_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Determinism (T : in out Fixture);
   procedure Test_Path_Properties (T : in out Fixture);
   procedure Test_Result_Properties (T : in out Fixture);
   procedure Test_Identifier_Fuzz (T : in out Fixture);
   procedure Test_UTF8_Fuzz (T : in out Fixture);
   procedure Test_Condition_Fault (T : in out Fixture);
   procedure Test_Ownership (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Hardening_Tests;
