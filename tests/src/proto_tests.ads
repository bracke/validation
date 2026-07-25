with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

--  Phase 0 feasibility tests: exercise the capability-storage and callback
--  (rule-node) prototypes that de-risk the Contexts and Rules designs.
package Proto_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Capability_Roundtrip (T : in out Fixture);
   procedure Test_Capability_Rejections (T : in out Fixture);
   procedure Test_Rule_Nodes (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Proto_Tests;
