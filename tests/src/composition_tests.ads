with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 6 tests: prerequisites, conditions, profile selection + severity
--  override, and composition (extend/disable).
package Composition_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Prerequisite (T : in out Fixture);
   procedure Test_Group_Filtering (T : in out Fixture);
   procedure Test_Severity_Override (T : in out Fixture);
   procedure Test_Condition (T : in out Fixture);
   procedure Test_Composition (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Composition_Tests;
