with Validation.Identifiers;
with Validation.Paths;
with Validation.Messages;
with Validation.Fingerprints;

package body Validation.Projections is

   package Message_Ids renames Identifiers.Message_Ids;
   package Machine_Codes renames Identifiers.Machine_Codes;

   function Compact (Item : Issues.Issue) return Compact_Issue is
      Result : Compact_Issue;
   begin
      Result.Identity_Image :=
        To_Unbounded_String (Issues.Image (Issues.Identity (Item)));
      Result.Severity := Issues.Level (Item);
      Result.Primary_Path :=
        To_Unbounded_String (Paths.Render (Issues.Primary_Path (Item)));
      Result.Message_Id :=
        To_Unbounded_String
          (Message_Ids.Image (Messages.Id_Of (Issues.Message (Item))));
      Result.Argument_Count := Messages.Argument_Count (Issues.Message (Item));
      Result.Has_Machine_Code := Issues.Has_Machine_Code (Item);
      if Result.Has_Machine_Code then
         Result.Machine_Code :=
           To_Unbounded_String (Machine_Codes.Image (Issues.Machine_Code (Item)));
      else
         Result.Machine_Code := Null_Unbounded_String;
      end if;
      return Result;
   end Compact;

   function Compact_All
     (Collection : Issues.Issue_Collection) return Compact_Issue_Array is
      Count  : constant Natural := Issues.Count (Collection);
      Result : Compact_Issue_Array (1 .. Count);
   begin
      for Position in 1 .. Count loop
         Result (Position) := Compact (Issues.Element (Collection, Position));
      end loop;
      return Result;
   end Compact_All;

   function Render (Item : Compact_Issue) return String is
     (Issues.Severity'Image (Item.Severity) & " "
      & To_String (Item.Primary_Path) & " " & To_String (Item.Message_Id));

   function Summarize (Item : Results.Result) return Result_Summary is
      Result : Result_Summary;
   begin
      Result.Status := Results.Status (Item);
      Result.Validity := Results.Validity (Item);
      Result.Coverage := Results.Coverage_Of (Item);
      Result.Issue_Count := Results.Issue_Count (Item);
      Result.Error_Count := Results.Error_Count (Item);
      Result.Warning_Count := Results.Warning_Count (Item);
      Result.Information_Count := Results.Information_Count (Item);
      Result.Has_Highest_Severity := Result.Issue_Count >= 1;
      if Result.Has_Highest_Severity then
         Result.Highest_Severity := Results.Highest_Severity (Item);
      else
         Result.Highest_Severity := Issues.Information;
      end if;
      Result.Incompleteness_Count := Results.Incompleteness_Count (Item);
      Result.Invocation_Error_Count := Results.Invocation_Error_Count (Item);
      Result.Semantic_Fingerprint :=
        To_Unbounded_String
          (Fingerprints.Image (Results.Semantic_Fingerprint (Item)));
      return Result;
   end Summarize;

end Validation.Projections;
