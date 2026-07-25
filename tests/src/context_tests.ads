with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 3 tests: typed capability contexts and profiles.
package Context_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Capability_Trust (T : in out Fixture);
   procedure Test_Context_Fingerprint (T : in out Fixture);
   procedure Test_Contract (T : in out Fixture);
   procedure Test_Profiles (T : in out Fixture);
   procedure Test_Profile_Set (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Context_Tests;
