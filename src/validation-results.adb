package body Validation.Results is

   package Issue_Ops renames Validation.Issues;
   use type Paths.Path;
   use type Issue_Ops.Severity;

   ---------------------------------------------------------------------------
   --  Validity derivation
   ---------------------------------------------------------------------------

   function Derive_Validity
     (Status : Execution_Status;
      Issues : Issue_Ops.Issue_Collection) return Semantic_Validity is
   begin
      if Issue_Ops.Has_Errors (Issues) then
         return Invalid;
      end if;
      case Status is
         when Completed =>
            if Issue_Ops.Count (Issues) = 0 then
               return Valid;
            else
               return Valid_With_Nonerrors;
            end if;
         when others =>
            --  No errors, but work was not fully completed.
            return Undetermined;
      end case;
   end Derive_Validity;

   ---------------------------------------------------------------------------
   --  Builder
   ---------------------------------------------------------------------------

   function Begin_Result
     (Status   : Execution_Status;
      Coverage : Results.Coverage := Complete_Definition) return Result_Builder
   is
   begin
      return B : Result_Builder do
         B.Data.Status := Status;
         B.Data.Coverage := Coverage;
         B.Data.Issues := Issue_Ops.Empty_Collection;
      end return;
   end Begin_Result;

   procedure Add_Issue
     (Builder : in out Result_Builder; Item : Issues.Issue) is
   begin
      Issue_Ops.Append (Builder.Data.Issues, Item);
   end Add_Issue;

   procedure Add_Invocation_Error
     (Builder : in out Result_Builder; Item : Errors.Error) is
   begin
      Builder.Data.Invocation_Errors.Append (Item);
   end Add_Invocation_Error;

   procedure Add_Incompleteness
     (Builder : in out Result_Builder; Note : Incompleteness_Note) is
   begin
      Builder.Data.Incompleteness.Append (Note);
   end Add_Incompleteness;

   procedure Set_Stop
     (Builder : in out Result_Builder; Descriptor : Stop_Descriptor) is
   begin
      Builder.Data.Stop := Descriptor;
   end Set_Stop;

   procedure Set_Counters
     (Builder : in out Result_Builder; Counters : Statistics.Counters) is
   begin
      Builder.Data.Counters := Counters;
   end Set_Counters;

   procedure Set_Validator_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint) is
   begin
      Builder.Data.Validator_FP := Fingerprint;
   end Set_Validator_Fingerprint;

   procedure Set_Context_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint) is
   begin
      Builder.Data.Context_FP := Fingerprint;
   end Set_Context_Fingerprint;

   procedure Set_Options_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint) is
   begin
      Builder.Data.Options_FP := Fingerprint;
   end Set_Options_Fingerprint;

   function Build (Builder : Result_Builder) return Result is
      Result_Value : Result := Builder.Data;
   begin
      Result_Value.Validity :=
        Derive_Validity (Result_Value.Status, Result_Value.Issues);
      return Result_Value;
   end Build;

   ---------------------------------------------------------------------------
   --  Top-level
   ---------------------------------------------------------------------------

   function Status (Item : Result) return Execution_Status is (Item.Status);
   function Validity (Item : Result) return Semantic_Validity is (Item.Validity);
   function Coverage_Of (Item : Result) return Coverage is (Item.Coverage);
   function Counters (Item : Result) return Statistics.Counters is
     (Item.Counters);
   function Stop (Item : Result) return Stop_Descriptor is (Item.Stop);
   function Validator_Fingerprint
     (Item : Result) return Fingerprints.Fingerprint is (Item.Validator_FP);

   ---------------------------------------------------------------------------
   --  Issue queries
   ---------------------------------------------------------------------------

   function Issue_Count (Item : Result) return Natural is
     (Issue_Ops.Count (Item.Issues));
   function Error_Count (Item : Result) return Natural is
     (Issue_Ops.Error_Count (Item.Issues));
   function Warning_Count (Item : Result) return Natural is
     (Issue_Ops.Warning_Count (Item.Issues));
   function Information_Count (Item : Result) return Natural is
     (Issue_Ops.Information_Count (Item.Issues));
   function Has_Errors (Item : Result) return Boolean is
     (Error_Count (Item) > 0);
   function Has_Warnings (Item : Result) return Boolean is
     (Warning_Count (Item) > 0);
   function Has_Information (Item : Result) return Boolean is
     (Information_Count (Item) > 0);
   function Highest_Severity (Item : Result) return Issues.Severity is
     (Issue_Ops.Highest_Severity (Item.Issues));

   function Has_Severity_At_Least
     (Item : Result; Level : Issues.Severity) return Boolean is
     (Issue_Count (Item) >= 1 and then Highest_Severity (Item) >= Level);

   function Issue_At (Item : Result; Position : Positive) return Issues.Issue is
     (Issue_Ops.Element (Item.Issues, Position));

   function Is_Complete (Item : Result) return Boolean is
     (Item.Status = Completed);
   function Is_Pending (Item : Result) return Boolean is (Item.Status = Pending);
   function Has_Invocation_Failure (Item : Result) return Boolean is
     (Item.Status = Invocation_Failed
      or else not Item.Invocation_Errors.Is_Empty);
   function Invocation_Error_Count (Item : Result) return Natural is
     (Natural (Item.Invocation_Errors.Length));
   function Invocation_Error_At
     (Item : Result; Position : Positive) return Errors.Error is
     (Item.Invocation_Errors (Position));

   function Incompleteness_Count (Item : Result) return Natural is
     (Natural (Item.Incompleteness.Length));
   function Incompleteness_At
     (Item : Result; Position : Positive) return Incompleteness_Note is
     (Item.Incompleteness (Position));

   ---------------------------------------------------------------------------
   --  Filters
   ---------------------------------------------------------------------------

   generic
      with function Matches (Item : Issues.Issue) return Boolean;
   function Filter (Item : Result) return Issues.Issue_Collection;

   function Filter (Item : Result) return Issues.Issue_Collection is
      Result_Coll : Issue_Ops.Issue_Collection := Issue_Ops.Empty_Collection;
   begin
      for Position in 1 .. Issue_Ops.Count (Item.Issues) loop
         declare
            One : constant Issues.Issue := Issue_Ops.Element (Item.Issues, Position);
         begin
            if Matches (One) then
               Issue_Ops.Append (Result_Coll, One);
            end if;
         end;
      end loop;
      return Result_Coll;
   end Filter;

   function Issues_At_Exact_Path
     (Item : Result; Path : Paths.Path) return Issues.Issue_Collection is
      function Matches (One : Issues.Issue) return Boolean is
        (Issue_Ops.Primary_Path (One) = Path);
      function Do_Filter is new Filter (Matches);
   begin
      return Do_Filter (Item);
   end Issues_At_Exact_Path;

   function Issues_Under_Path
     (Item : Result; Path : Paths.Path) return Issues.Issue_Collection is
      function Matches (One : Issues.Issue) return Boolean is
        (Paths.Is_In_Subtree_Of (Issue_Ops.Primary_Path (One), Path));
      function Do_Filter is new Filter (Matches);
   begin
      return Do_Filter (Item);
   end Issues_Under_Path;

   function Issues_From_Rule
     (Item : Result; Rule : Identifiers.Rule_Id) return Issues.Issue_Collection
   is
      function Matches (One : Issues.Issue) return Boolean is
        (Identifiers.Rule_Ids."=" (Issue_Ops.Rule (One), Rule));
      function Do_Filter is new Filter (Matches);
   begin
      return Do_Filter (Item);
   end Issues_From_Rule;

   function Issues_From_Validator
     (Item : Result; Validator : Identifiers.Validator_Id)
      return Issues.Issue_Collection is
      function Matches (One : Issues.Issue) return Boolean is
        (Identifiers.Validator_Ids."=" (Issue_Ops.Validator (One), Validator));
      function Do_Filter is new Filter (Matches);
   begin
      return Do_Filter (Item);
   end Issues_From_Validator;

   function Issues_By_Category
     (Item : Result; Category : Identifiers.Issue_Category_Id)
      return Issues.Issue_Collection is
      function Matches (One : Issues.Issue) return Boolean is
        (Identifiers.Issue_Category_Ids."="
           (Issue_Ops.Category (One), Category));
      function Do_Filter is new Filter (Matches);
   begin
      return Do_Filter (Item);
   end Issues_By_Category;

   ---------------------------------------------------------------------------
   --  Semantic fingerprint
   ---------------------------------------------------------------------------

   function Semantic_Fingerprint
     (Item : Result) return Fingerprints.Fingerprint is
      B : Fingerprints.Builder := Fingerprints.Start;
   begin
      Fingerprints.Add_Tag (B, "status");
      Fingerprints.Add_Natural (B, Execution_Status'Pos (Item.Status));
      Fingerprints.Add_Tag (B, "validity");
      Fingerprints.Add_Natural (B, Semantic_Validity'Pos (Item.Validity));
      Fingerprints.Add_Tag (B, "coverage");
      Fingerprints.Add_Natural (B, Coverage'Pos (Item.Coverage));
      Fingerprints.Add_Tag (B, "issues");
      for Position in 1 .. Issue_Ops.Count (Item.Issues) loop
         Fingerprints.Add_String
           (B, Issue_Ops.Image
                 (Issue_Ops.Identity (Issue_Ops.Element (Item.Issues, Position))));
      end loop;
      Fingerprints.Add_Tag (B, "invocation");
      for Err of Item.Invocation_Errors loop
         Fingerprints.Add_String (B, Errors.Key (Err));
      end loop;
      return Fingerprints.Finish (B);
   end Semantic_Fingerprint;

   function Issue_Set_Fingerprint
     (Item : Result) return Fingerprints.Fingerprint
   is
      Count  : constant Natural := Issue_Count (Item);
      subtype Id_Image is String (1 .. 16);
      Images : array (1 .. Count) of Id_Image;
      B      : Fingerprints.Builder := Fingerprints.Start;
   begin
      for I in 1 .. Count loop
         Images (I) :=
           Issue_Ops.Image (Issue_Ops.Identity (Issue_At (Item, I)));
      end loop;
      --  Sort the identities so arrival/execution order does not matter.
      for I in 2 .. Count loop
         declare
            Key : constant Id_Image := Images (I);
            J   : Integer := I - 1;
         begin
            while J >= 1 and then Key < Images (J) loop
               Images (J + 1) := Images (J);
               J := J - 1;
            end loop;
            Images (J + 1) := Key;
         end;
      end loop;
      Fingerprints.Add_Tag (B, "validity");
      Fingerprints.Add_Natural (B, Semantic_Validity'Pos (Item.Validity));
      Fingerprints.Add_Tag (B, "issue-set");
      for I in 1 .. Count loop
         Fingerprints.Add_String (B, Images (I));
      end loop;
      return Fingerprints.Finish (B);
   end Issue_Set_Fingerprint;

   function Same_Issue_Set (Left, Right : Result) return Boolean is
      use type Fingerprints.Fingerprint;
   begin
      return Issue_Set_Fingerprint (Left) = Issue_Set_Fingerprint (Right);
   end Same_Issue_Set;

end Validation.Results;
