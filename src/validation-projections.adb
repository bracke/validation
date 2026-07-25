with Validation.Identifiers;
with Validation.Paths;
with Validation.Messages;
with Validation.Metadata;
with Validation.Provenance;
with Validation.Fingerprints;

package body Validation.Projections is

   package Message_Ids renames Identifiers.Message_Ids;
   package Machine_Codes renames Identifiers.Machine_Codes;
   package Validator_Ids renames Identifiers.Validator_Ids;
   package Rule_Ids renames Identifiers.Rule_Ids;
   package Category_Ids renames Identifiers.Issue_Category_Ids;
   use type Issues.Severity;
   use type Provenance.Provenance_Mode;

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

   function Standard (Item : Issues.Issue) return Standard_Issue is
   begin
      return
        (Identity_Image => To_Unbounded_String
                             (Issues.Image (Issues.Identity (Item))),
         Severity       => Issues.Level (Item),
         Primary_Path   => To_Unbounded_String
                             (Paths.Render (Issues.Primary_Path (Item))),
         Message_Id     => To_Unbounded_String
                             (Message_Ids.Image
                                (Messages.Id_Of (Issues.Message (Item)))),
         Category       => To_Unbounded_String
                             (Category_Ids.Image (Issues.Category (Item))),
         Validator_Id   => To_Unbounded_String
                             (Validator_Ids.Image (Issues.Validator (Item))),
         Rule_Id        => To_Unbounded_String
                             (Rule_Ids.Image (Issues.Rule (Item))),
         Related_Count  => Issues.Related_Path_Count (Item),
         Argument_Count => Messages.Argument_Count (Issues.Message (Item)),
         Metadata_Count => Metadata.Count (Issues.Metadata_Of (Item)),
         Provenance_Standard =>
           Provenance.Mode (Issues.Provenance_Of (Item)) = Provenance.Standard);
   end Standard;

   function Less (Left, Right : Issues.Issue) return Boolean is
      use type Paths.Path;
   begin
      if not (Issues.Primary_Path (Left) = Issues.Primary_Path (Right)) then
         return Paths."<"
           (Issues.Primary_Path (Left), Issues.Primary_Path (Right));
      elsif Issues.Level (Left) /= Issues.Level (Right) then
         --  Higher severity first.
         return Issues.Level (Left) > Issues.Level (Right);
      elsif not Rule_Ids."=" (Issues.Rule (Left), Issues.Rule (Right)) then
         return Rule_Ids."<" (Issues.Rule (Left), Issues.Rule (Right));
      elsif not Message_Ids."="
              (Messages.Id_Of (Issues.Message (Left)),
               Messages.Id_Of (Issues.Message (Right)))
      then
         return Message_Ids."<"
           (Messages.Id_Of (Issues.Message (Left)),
            Messages.Id_Of (Issues.Message (Right)));
      else
         return Issues.Ordinal (Left) < Issues.Ordinal (Right);
      end if;
   end Less;

   function Canonical_Order
     (Collection : Issues.Issue_Collection) return Compact_Issue_Array
   is
      Count : constant Natural := Issues.Count (Collection);
      Order : array (1 .. Count) of Positive;
      Result : Compact_Issue_Array (1 .. Count);
   begin
      for I in 1 .. Count loop
         Order (I) := I;
      end loop;
      for I in 2 .. Count loop
         declare
            Key : constant Positive := Order (I);
            J   : Integer := I - 1;
         begin
            while J >= 1
              and then Less (Issues.Element (Collection, Key),
                             Issues.Element (Collection, Order (J)))
            loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;
      for I in 1 .. Count loop
         Result (I) := Compact (Issues.Element (Collection, Order (I)));
      end loop;
      return Result;
   end Canonical_Order;

   function Distinct_Paths
     (Collection : Issues.Issue_Collection) return Path_List
   is
      Count  : constant Natural := Issues.Count (Collection);
      Buffer : Path_List (1 .. Count);
      Found  : Natural := 0;

      procedure Insert (Value : Unbounded_String) is
         Position : Integer := Found;
      begin
         --  Skip duplicates.
         for K in 1 .. Found loop
            if Buffer (K) = Value then
               return;
            end if;
         end loop;
         --  Sorted insertion.
         while Position >= 1 and then Value < Buffer (Position) loop
            Buffer (Position + 1) := Buffer (Position);
            Position := Position - 1;
         end loop;
         Buffer (Position + 1) := Value;
         Found := Found + 1;
      end Insert;
   begin
      for I in 1 .. Count loop
         Insert (To_Unbounded_String
                   (Paths.Render
                      (Issues.Primary_Path (Issues.Element (Collection, I)))));
      end loop;
      return Buffer (1 .. Found);
   end Distinct_Paths;

end Validation.Projections;
