with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 1 tests: identifiers, versions, outcomes, paths, values.
package Foundation_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Identifiers (T : in out Fixture);
   procedure Test_Versions (T : in out Fixture);
   procedure Test_Outcomes (T : in out Fixture);
   procedure Test_Paths (T : in out Fixture);
   procedure Test_Path_Rendering (T : in out Fixture);
   procedure Test_Values (T : in out Fixture);
   procedure Test_Messages (T : in out Fixture);
   procedure Test_Metadata (T : in out Fixture);
   procedure Test_Source_References (T : in out Fixture);
   procedure Test_Fingerprints (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Foundation_Tests;
