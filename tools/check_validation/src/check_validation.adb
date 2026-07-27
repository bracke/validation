with Ada.Command_Line; use Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;      use Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;

--  Ada replacement for the former shell tools/check_dependencies.sh and
--  tools/prove.sh, so validation's repository tooling is Ada-only like the rest
--  of the stack.
--
--  Default: the dependency-boundary audit (VAL-INV-019/020, ADR-001) -- the
--  Validation core (src/) must never `with` I/O, the system clock, randomness,
--  sockets, GNAT.OS_Lib, or any ecosystem project.
--    --release : + build and run the test suite (`alr test`).
--    --prove   : + GNATprove on the SPARK_Mode Identifier_Syntax unit.
procedure Check_Validation is

   package Files renames Project_Tools.Files;
   package Proc  renames Project_Tools.Processes;

   Errors : Natural := 0;

   procedure Fail (Message : String) is
   begin
      Errors := Errors + 1;
      Put_Line (Standard_Error, "error: " & Message);
   end Fail;

   function Root return String is
      Current : constant String := Ada.Directories.Current_Directory;
      Found   : constant String := Files.Find_Root_Upward (Current, "validation.gpr");
   begin
      if Found = "" then
         Put_Line (Standard_Error, "validation root not found from " & Current);
         Set_Exit_Status (Failure);
         raise Program_Error;
      end if;
      return Found;
   end Root;

   The_Root : constant String := Root;

   --  Dependency-boundary audit: scan src/ for forbidden with-clauses.
   procedure Check_Boundary is
      Src    : constant String := The_Root & "/src";
      Search : Ada.Directories.Search_Type;
      Item   : Ada.Directories.Directory_Entry_Type;

      procedure Check_File (Full : String; Name : String) is
         procedure Forbid (Pkg : String) is
         begin
            if Files.File_Contains (Full, "with " & Pkg) then
               Fail (Name & ": forbidden dependency 'with " & Pkg & "'");
            end if;
         end Forbid;
      begin
         --  I/O, clock, randomness, sockets, process/OS.
         Forbid ("Ada.Text_IO");
         Forbid ("Ada.Wide_Text_IO");
         Forbid ("Ada.Wide_Wide_Text_IO");
         Forbid ("Ada.Direct_IO");
         Forbid ("Ada.Sequential_IO");
         Forbid ("Ada.Streams.Stream_IO");
         Forbid ("Ada.Directories");
         Forbid ("Ada.Calendar");
         Forbid ("Ada.Numerics.Float_Random");
         Forbid ("Ada.Numerics.Discrete_Random");
         Forbid ("GNAT.Sockets");
         Forbid ("GNAT.OS_Lib");
         Forbid ("AWS");
         --  Ecosystem projects the leaf core must never consume.
         Forbid ("Forms");
         Forbid ("Tables");
         Forbid ("Webframework");
         Forbid ("Database");
         Forbid ("Identity");
         Forbid ("Authorization");
         Forbid ("I18n");
         Forbid ("Humanize");
         Forbid ("Representation");
         Forbid ("Navigation");
      end Check_File;

      Count : Natural := 0;
   begin
      Ada.Directories.Start_Search
        (Search, Src, "*.ad*",
         Filter => [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         Check_File
           (Ada.Directories.Full_Name (Item), Ada.Directories.Simple_Name (Item));
         Count := Count + 1;
      end loop;
      Ada.Directories.End_Search (Search);
      if Errors = 0 then
         Put_Line ("dependency boundary: clean ("
                   & Natural'Image (Count) & " core units)");
      end if;
   end Check_Boundary;

   function Run
     (Label : String; Dir : String; Program : String;
      Args : GNAT.OS_Lib.Argument_List) return Boolean
   is
      Status : Integer;
   begin
      if Program = "" then
         Fail (Label & ": program not found");
         return False;
      end if;
      Status :=
        Proc.Run_Status (Label => Label, Dir => Dir, Program => Program, Args => Args);
      if Status /= 0 then
         Fail (Label & " failed (status" & Integer'Image (Status) & ")");
         return False;
      end if;
      return True;
   end Run;

   Ignored : Boolean;
   pragma Unreferenced (Ignored);

begin
   Check_Boundary;

   if Proc.Has_Argument ("--release") then
      Ignored := Run ("test", The_Root, Proc.Locate_Command ("alr"),
                      [new String'("--non-interactive"), new String'("test")]);
   end if;

   if Proc.Has_Argument ("--prove") then
      Ignored := Run
        ("gnatprove", The_Root, Proc.Locate_Command ("alr"),
         [new String'("exec"), new String'("--"), new String'("gnatprove"),
          new String'("-P"), new String'("validation.gpr"),
          new String'("--mode=all"), new String'("--level=1"),
          new String'("-u"), new String'("validation-identifier_syntax.adb")]);
   end if;

   if Errors = 0 then
      Put_Line ("check_validation: all checks passed");
   else
      Put_Line (Standard_Error,
                "check_validation:" & Natural'Image (Errors) & " error(s)");
      Set_Exit_Status (Failure);
   end if;
end Check_Validation;
