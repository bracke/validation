with Validation.Versions;

package body Validation.Issues is

   package Validator_Ids renames Identifiers.Validator_Ids;
   package Rule_Ids renames Identifiers.Rule_Ids;
   package Category_Ids renames Identifiers.Issue_Category_Ids;
   package Machine_Codes renames Identifiers.Machine_Codes;
   package Message_Ids renames Identifiers.Message_Ids;

   use type Paths.Path;
   use type Messages.Message;
   use type Metadata.Metadata;
   use type Ada.Containers.Count_Type;

   ---------------------------------------------------------------------------
   --  Issue identity
   ---------------------------------------------------------------------------

   function Image (Item : Issue_Identity) return String is
     (Fingerprints.Image (Item.Value));

   overriding function "=" (Left, Right : Issue_Identity) return Boolean is
     (Fingerprints."=" (Left.Value, Right.Value));

   function Compute_Identity (Data : Issue) return Issue_Identity is
      B : Fingerprints.Builder := Fingerprints.Start;
   begin
      Fingerprints.Add_Natural
        (B, Natural (Versions.Issue_Id_Format_Version));
      Fingerprints.Add_Tag (B, "ordinal");
      Fingerprints.Add_Natural (B, Data.Ordinal);
      Fingerprints.Add_Tag (B, "validator");
      Fingerprints.Add_String (B, Validator_Ids.Image (Data.Validator));
      Fingerprints.Add_Tag (B, "rule");
      Fingerprints.Add_String (B, Rule_Ids.Image (Data.Rule));
      Fingerprints.Add_Tag (B, "severity");
      Fingerprints.Add_Natural (B, Severity'Pos (Data.Level));
      Fingerprints.Add_Tag (B, "category");
      Fingerprints.Add_String (B, Category_Ids.Image (Data.Category));
      Fingerprints.Add_Tag (B, "primary");
      Fingerprints.Add_String (B, Paths.Render (Data.Primary));
      Fingerprints.Add_Tag (B, "message");
      Fingerprints.Add_String
        (B, Message_Ids.Image (Messages.Id_Of (Data.Message)));
      Fingerprints.Add_Natural (B, Messages.Argument_Count (Data.Message));
      for Position in 1 .. Natural (Data.Related.Length) loop
         Fingerprints.Add_Tag (B, "related");
         Fingerprints.Add_String (B, Paths.Render (Data.Related (Position)));
      end loop;
      if Data.Machine_Set then
         Fingerprints.Add_Tag (B, "machine");
         Fingerprints.Add_String (B, Machine_Codes.Image (Data.Machine));
      end if;
      return (Value => Fingerprints.Finish (B));
   end Compute_Identity;

   ---------------------------------------------------------------------------
   --  Builder
   ---------------------------------------------------------------------------

   function Begin_Issue
     (Ordinal      : Positive;
      Validator    : Identifiers.Validator_Id;
      Rule         : Identifiers.Rule_Id;
      Level        : Severity;
      Category     : Identifiers.Issue_Category_Id;
      Primary_Path : Paths.Path;
      Message      : Messages.Message;
      Provenance   : Validation.Provenance.Provenance) return Issue_Builder is
   begin
      return B : Issue_Builder do
         B.Data.Ordinal   := Ordinal;
         B.Data.Validator := Validator;
         B.Data.Rule      := Rule;
         B.Data.Level     := Level;
         B.Data.Category  := Category;
         B.Data.Primary   := Primary_Path;
         B.Data.Message   := Message;
         B.Data.Prov      := Provenance;
      end return;
   end Begin_Issue;

   procedure Add_Related_Path
     (Builder : in out Issue_Builder;
      Path    : Paths.Path;
      Added   : out Boolean) is
   begin
      if Builder.Data.Related.Length >= Max_Related_Paths
        or else Path = Builder.Data.Primary
      then
         Added := False;
         return;
      end if;
      for Existing of Builder.Data.Related loop
         if Existing = Path then
            Added := False;
            return;
         end if;
      end loop;
      Builder.Data.Related.Append (Path);
      Added := True;
   end Add_Related_Path;

   procedure Set_Machine_Code
     (Builder : in out Issue_Builder; Machine : Identifiers.Machine_Code) is
   begin
      Builder.Data.Machine_Set := True;
      Builder.Data.Machine := Machine;
   end Set_Machine_Code;

   procedure Set_Metadata
     (Builder : in out Issue_Builder; Data : Metadata.Metadata) is
   begin
      Builder.Data.Meta := Data;
   end Set_Metadata;

   procedure Set_Source
     (Builder : in out Issue_Builder;
      Source  : Source_References.Source_Reference) is
   begin
      Builder.Data.Source_Set := True;
      Builder.Data.Source_Ref := Source;
   end Set_Source;

   function Build (Builder : Issue_Builder) return Issue is
      Result : Issue := Builder.Data;
   begin
      Result.Ident := Compute_Identity (Result);
      return Result;
   end Build;

   ---------------------------------------------------------------------------
   --  Accessors
   ---------------------------------------------------------------------------

   function Identity (Item : Issue) return Issue_Identity is (Item.Ident);
   function Ordinal (Item : Issue) return Positive is (Item.Ordinal);
   function Validator (Item : Issue) return Identifiers.Validator_Id is
     (Item.Validator);
   function Rule (Item : Issue) return Identifiers.Rule_Id is (Item.Rule);
   function Level (Item : Issue) return Severity is (Item.Level);
   function Category (Item : Issue) return Identifiers.Issue_Category_Id is
     (Item.Category);
   function Primary_Path (Item : Issue) return Paths.Path is (Item.Primary);
   function Message (Item : Issue) return Messages.Message is (Item.Message);
   function Related_Path_Count (Item : Issue) return Natural is
     (Natural (Item.Related.Length));
   function Related_Path_At
     (Item : Issue; Position : Positive) return Paths.Path is
     (Item.Related (Position));
   function Has_Machine_Code (Item : Issue) return Boolean is (Item.Machine_Set);
   function Machine_Code (Item : Issue) return Identifiers.Machine_Code is
     (Item.Machine);
   function Metadata_Of (Item : Issue) return Metadata.Metadata is (Item.Meta);
   function Provenance_Of
     (Item : Issue) return Validation.Provenance.Provenance is (Item.Prov);
   function Has_Source (Item : Issue) return Boolean is (Item.Source_Set);
   function Source
     (Item : Issue) return Source_References.Source_Reference is
     (Item.Source_Ref);

   --  Exact equality over the observable diagnostic fields. Provenance and the
   --  source reference are ancillary and excluded here (they do not change the
   --  diagnostic's meaning to a consumer); semantic-equivalence variants live
   --  in Validation.Results.
   overriding function "=" (Left, Right : Issue) return Boolean is
   begin
      if Left.Ordinal /= Right.Ordinal
        or else Left.Level /= Right.Level
        or else not Validator_Ids."=" (Left.Validator, Right.Validator)
        or else not Rule_Ids."=" (Left.Rule, Right.Rule)
        or else not Category_Ids."=" (Left.Category, Right.Category)
        or else Left.Primary /= Right.Primary
        or else Left.Message /= Right.Message
        or else Left.Related.Length /= Right.Related.Length
        or else Left.Machine_Set /= Right.Machine_Set
        or else Left.Meta /= Right.Meta
      then
         return False;
      end if;
      for Position in 1 .. Natural (Left.Related.Length) loop
         if Left.Related (Position) /= Right.Related (Position) then
            return False;
         end if;
      end loop;
      if Left.Machine_Set
        and then not Machine_Codes."=" (Left.Machine, Right.Machine)
      then
         return False;
      end if;
      return True;
   end "=";

   function Rebased
     (Source : Issue; Under : Paths.Path; New_Ordinal : Positive) return Issue
   is
      B : Issue_Builder :=
        Begin_Issue
          (New_Ordinal, Source.Validator, Source.Rule, Source.Level,
           Source.Category, Paths.Rebase (Source.Primary, Paths.Root, Under),
           Source.Message, Source.Prov);
      Added : Boolean;
   begin
      for Position in 1 .. Natural (Source.Related.Length) loop
         Add_Related_Path
           (B, Paths.Rebase (Source.Related (Position), Paths.Root, Under),
            Added);
      end loop;
      if Source.Machine_Set then
         Set_Machine_Code (B, Source.Machine);
      end if;
      Set_Metadata (B, Source.Meta);
      if Source.Source_Set then
         Set_Source (B, Source.Source_Ref);
      end if;
      return Build (B);
   end Rebased;

   ---------------------------------------------------------------------------
   --  Collection
   ---------------------------------------------------------------------------

   function Empty_Collection return Issue_Collection is
     (Items => Issue_Vectors.Empty_Vector);

   procedure Append (Collection : in out Issue_Collection; Item : Issue) is
   begin
      Collection.Items.Append (Item);
   end Append;

   function Count (Collection : Issue_Collection) return Natural is
     (Natural (Collection.Items.Length));

   function Element
     (Collection : Issue_Collection; Position : Positive) return Issue is
     (Collection.Items (Position));

   function Count_At_Level
     (Collection : Issue_Collection; Level : Severity) return Natural is
      Total : Natural := 0;
   begin
      for Item of Collection.Items loop
         if Item.Level = Level then
            Total := Total + 1;
         end if;
      end loop;
      return Total;
   end Count_At_Level;

   function Error_Count (Collection : Issue_Collection) return Natural is
     (Count_At_Level (Collection, Error));
   function Warning_Count (Collection : Issue_Collection) return Natural is
     (Count_At_Level (Collection, Warning));
   function Information_Count (Collection : Issue_Collection) return Natural is
     (Count_At_Level (Collection, Information));

   function Has_Errors (Collection : Issue_Collection) return Boolean is
     (Error_Count (Collection) > 0);

   function Highest_Severity (Collection : Issue_Collection) return Severity is
      Highest : Severity := Information;
   begin
      for Item of Collection.Items loop
         if Item.Level > Highest then
            Highest := Item.Level;
         end if;
      end loop;
      return Highest;
   end Highest_Severity;

end Validation.Issues;
