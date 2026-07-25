with Ada.Command_Line;

with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit;

with All_Suites;

--  AUnit entry point for the validation test suite. Exit status reflects
--  overall pass/fail so CI and project_tools gates can key off it.
procedure Tests is
   use type AUnit.Status;

   function Runner is new AUnit.Run.Test_Runner_With_Status (All_Suites.Suite);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : AUnit.Status;
begin
   Status := Runner (Reporter);
   Ada.Command_Line.Set_Exit_Status
     (if Status = AUnit.Success
      then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end Tests;
