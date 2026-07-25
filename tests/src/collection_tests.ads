with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 7 tests: collection validators over a Vector adapter.
package Collection_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Cardinality (T : in out Fixture);
   procedure Test_Each_Element (T : in out Fixture);
   procedure Test_Uniqueness (T : in out Fixture);
   procedure Test_Quantifier (T : in out Fixture);
   procedure Test_Aggregate (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Collection_Tests;
