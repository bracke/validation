with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 10 tests: standard projection, canonical ordering, path grouping,
--  order-independent issue-set fingerprints.
package Diagnostics_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Standard_Projection (T : in out Fixture);
   procedure Test_Canonical_Order (T : in out Fixture);
   procedure Test_Distinct_Paths (T : in out Fixture);
   procedure Test_Issue_Set_Fingerprint (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Diagnostics_Tests;
