with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;

--  Release and documentation guard for the validation library. Uses
--  project_tools for filesystem, process, and git checks. Modes:
--
--    (default)          required-surface + text + dependency-boundary audit
--    --release          + build library, build/run tests, build/run example
--    --release-strict   + require clean git worktrees (validation, project_tools)
procedure Check_Validation is

   use Ada.Text_IO;
   package Files renames Project_Tools.Files;
   package Proc renames Project_Tools.Processes;
   package RC renames Project_Tools.Release_Checks;

   Errors : Natural := 0;

   procedure Fail (Message : String) is
   begin
      Errors := Errors + 1;
      Put_Line (Standard_Error, "error: " & Message);
   end Fail;

   function Root return String is
      Current : constant String := Ada.Directories.Current_Directory;
      Found   : constant String :=
        Files.Find_Root_Upward (Current, "validation.gpr");
   begin
      if Found = "" then
         Put_Line (Standard_Error, "validation root not found from " & Current);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
      return Found;
   end Root;

   The_Root : constant String := Root;

   procedure Need_File (Relative : String) is
   begin
      if not Files.File_Exists (The_Root & "/" & Relative) then
         Fail ("missing required file: " & Relative);
      end if;
   end Need_File;

   procedure Need_Directory (Relative : String) is
   begin
      if not Files.Directory_Exists (The_Root & "/" & Relative) then
         Fail ("missing required directory: " & Relative);
      end if;
   end Need_Directory;

   procedure Need_Text (Relative : String; Pattern : String) is
   begin
      if not Files.File_Contains (The_Root & "/" & Relative, Pattern) then
         Fail (Relative & " must contain: " & Pattern);
      end if;
   end Need_Text;

   No_Args : constant GNAT.OS_Lib.Argument_List := [];

   function Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List) return Boolean
   is
      Status : Integer;
   begin
      if Program = "" then
         Fail (Label & ": program not found");
         return False;
      end if;
      Status :=
        Proc.Run_Status
          (Label => Label, Dir => Dir, Program => Program, Args => Args);
      if Status /= 0 then
         Fail (Label & " failed (status" & Integer'Image (Status) & ")");
         return False;
      end if;
      return True;
   end Run;

   Ignored : Boolean;
   pragma Unreferenced (Ignored);

   ---------------------------------------------------------------------------
   --  Required release surface
   ---------------------------------------------------------------------------

   procedure Check_Surface is
   begin
      Need_Directory ("src");
      Need_Directory ("tests");
      Need_Directory ("examples");
      Need_Directory ("tools");
      Need_Directory ("docs");
      Need_Directory ("docs/ai");
      Need_Directory ("docs/adr");

      Need_File ("alire.toml");
      Need_File ("validation.gpr");
      Need_File ("README.md");
      Need_File ("LICENSE");
      Need_File ("CHANGELOG.md");
      Need_File ("SECURITY.md");
      Need_File ("CONTRIBUTING.md");
      Need_File ("tests/alire.toml");
      Need_File ("examples/alire.toml");
      Need_File ("examples/src/quickstart.adb");
      --  The dependency-boundary audit and the gnatprove wrapper are the Ada
      --  tools/check_validation crate now (it replaced the former
      --  tools/check_dependencies.sh and tools/prove.sh shell scripts).
      Need_File ("tools/check_validation/check_validation.gpr");

      Need_File ("docs/QUICKSTART.md");
      Need_File ("docs/ARCHITECTURE.md");
      Need_File ("docs/VALIDATOR_CATALOG.md");
      Need_File ("docs/RELEASE.md");
      Need_File ("docs/PHASE_STATUS.md");
      Need_File ("docs/ai/invariants.md");
      Need_File ("docs/ai/package_map.md");
      Need_File ("docs/ai/prohibited_patterns.md");
      Need_File ("docs/ai/allowed_dependencies.md");
      Need_File ("docs/adr/README.md");

      Need_Text ("alire.toml", "gnat_native = ""=15.2.1""");
      Need_Text ("README.md", "Validation");
      Need_Text ("docs/ai/invariants.md", "VAL-INV-040");
   end Check_Surface;

   ---------------------------------------------------------------------------
   --  Dependency-boundary audit (always)
   ---------------------------------------------------------------------------

   procedure Check_Dependency_Boundary is
      Alr  : constant String := Proc.Locate_Command ("alr");
      Tool : constant String := The_Root & "/tools/check_validation";
   begin
      --  The boundary audit is the tools/check_validation Ada crate (it replaced
      --  tools/check_dependencies.sh). Build it, then run its headless audit.
      if Run ("dependency audit build", Tool, Alr,
              [new String'("--non-interactive"), new String'("build")])
      then
         Ignored :=
           Run ("dependency audit", Tool,
                Tool & "/bin/check_validation", No_Args);
      end if;
   end Check_Dependency_Boundary;

   ---------------------------------------------------------------------------
   --  Build / test / example (release mode)
   ---------------------------------------------------------------------------

   procedure Check_Build_And_Test is
      Alr : constant String := Proc.Locate_Command ("alr");
   begin
      if not Run ("build library", The_Root, Alr,
                  [new String'("--non-interactive"), new String'("build")])
      then
         return;
      end if;
      if Run ("build tests", The_Root & "/tests", Alr,
              [new String'("--non-interactive"), new String'("build")])
      then
         Ignored :=
           Run ("run tests", The_Root & "/tests",
                The_Root & "/tests/bin/tests", No_Args);
      end if;
      if Run ("build example", The_Root & "/examples", Alr,
              [new String'("--non-interactive"), new String'("build")])
      then
         Ignored :=
           Run ("run example", The_Root & "/examples",
                The_Root & "/examples/bin/quickstart", No_Args);
      end if;
   end Check_Build_And_Test;

   ---------------------------------------------------------------------------
   --  Strict: clean worktrees
   ---------------------------------------------------------------------------

   procedure Check_Clean_Worktree (Label : String; Path : String) is
   begin
      RC.Require_Clean_Git_Worktree (Label => Label, Path => Path, Quiet => True);
   exception
      when Program_Error =>
         Fail (Label & " worktree must be clean for --release-strict");
   end Check_Clean_Worktree;

begin
   Check_Surface;
   Check_Dependency_Boundary;

   if Proc.Has_Argument ("--release")
     or else Proc.Has_Argument ("--release-strict")
   then
      Check_Build_And_Test;
   end if;

   if Proc.Has_Argument ("--release-strict") then
      Check_Clean_Worktree ("validation", The_Root);
      Check_Clean_Worktree ("project_tools", The_Root & "/../project_tools");
   end if;

   if Errors = 0 then
      Put_Line ("check_validation: all checks passed");
   else
      Put_Line
        (Standard_Error,
         "check_validation:" & Natural'Image (Errors) & " error(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Check_Validation;
