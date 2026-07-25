with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 5 tests: standard scalar validators (text, numerics, UTF-8).
package Standard_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_UTF8 (T : in out Fixture);
   procedure Test_Text_Rules (T : in out Fixture);
   procedure Test_Numeric_Rules (T : in out Fixture);
   procedure Test_Message_Arguments (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Standard_Tests;
