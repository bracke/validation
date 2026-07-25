with AUnit.Test_Suites;

--  Aggregate suite for the whole validation test tree. Each test package
--  contributes through Add_Tests; new packages are wired in the body.
package All_Suites is

   function Suite return AUnit.Test_Suites.Access_Test_Suite;

end All_Suites;
