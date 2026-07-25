with Proto_Tests;
with Foundation_Tests;
with Result_Tests;
with Context_Tests;
with Engine_Tests;

package body All_Suites is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      Proto_Tests.Add_Tests (Result);
      Foundation_Tests.Add_Tests (Result);
      Result_Tests.Add_Tests (Result);
      Context_Tests.Add_Tests (Result);
      Engine_Tests.Add_Tests (Result);
      return Result;
   end Suite;

end All_Suites;
