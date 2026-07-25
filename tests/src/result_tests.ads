with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 2 tests: issues, results, projections, provenance, errors.
package Result_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Issue_Identity (T : in out Fixture);
   procedure Test_Related_Paths (T : in out Fixture);
   procedure Test_Validity_Derivation (T : in out Fixture);
   procedure Test_Result_Queries (T : in out Fixture);
   procedure Test_Invocation_Errors (T : in out Fixture);
   procedure Test_Projections (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Result_Tests;
