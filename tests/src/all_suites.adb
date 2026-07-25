with Proto_Tests;
with Foundation_Tests;

package body All_Suites is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      Proto_Tests.Add_Tests (Result);
      Foundation_Tests.Add_Tests (Result);
      return Result;
   end Suite;

end All_Suites;
