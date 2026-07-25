with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 8 tests: nested objects, optional presence, recursive trees.
package Nested_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Nested (T : in out Fixture);
   procedure Test_Optional (T : in out Fixture);
   procedure Test_Recursive_Cycle (T : in out Fixture);
   procedure Test_Recursive_Depth (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Nested_Tests;
