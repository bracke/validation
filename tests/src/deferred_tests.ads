with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 9 tests: deferred validation lifecycle, replay, stale rejection.
package Deferred_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Synchronous (T : in out Fixture);
   procedure Test_Replay_And_Order (T : in out Fixture);
   procedure Test_Partial (T : in out Fixture);
   procedure Test_Stale (T : in out Fixture);
   procedure Test_Unknown_And_Duplicate (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Deferred_Tests;
