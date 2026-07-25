package body Validation.Profiles is

   package Group_Ids renames Identifiers.Rule_Group_Ids;
   package Rule_Ids renames Identifiers.Rule_Ids;
   use type Issues.Severity;

   ---------------------------------------------------------------------------
   --  Builder
   ---------------------------------------------------------------------------

   function Begin_Profile
     (Id : Identifiers.Profile_Id) return Profile_Builder is
   begin
      return B : Profile_Builder do
         B.Data.Id := Id;
      end return;
   end Begin_Profile;

   function Extend
     (Parent : Profile; Id : Identifiers.Profile_Id) return Profile_Builder is
   begin
      return B : Profile_Builder do
         B.Data := Parent;
         B.Data.Id := Id;
      end return;
   end Extend;

   function Group_Index
     (Groups : Group_Vectors.Vector;
      Group  : Identifiers.Rule_Group_Id) return Natural is
   begin
      for I in 1 .. Natural (Groups.Length) loop
         if Group_Ids."=" (Groups (I), Group) then
            return I;
         end if;
      end loop;
      return 0;
   end Group_Index;

   procedure Include_Group
     (Builder : in out Profile_Builder; Group : Identifiers.Rule_Group_Id) is
   begin
      if Group_Index (Builder.Data.Groups, Group) = 0 then
         Builder.Data.Groups.Append (Group);
      end if;
   end Include_Group;

   procedure Exclude_Group
     (Builder : in out Profile_Builder; Group : Identifiers.Rule_Group_Id) is
      Position : constant Natural := Group_Index (Builder.Data.Groups, Group);
   begin
      if Position > 0 then
         Builder.Data.Groups.Delete (Position);
      end if;
   end Exclude_Group;

   procedure Override_Severity
     (Builder : in out Profile_Builder;
      Rule    : Identifiers.Rule_Id;
      Level   : Issues.Severity) is
   begin
      Builder.Data.Overrides.Append (Override_Entry'(Rule => Rule, Level => Level));
   end Override_Severity;

   function Finalize (Builder : Profile_Builder) return Finalize_Outcome is
      Result : Finalize_Outcome;
   begin
      Result.Value.Id := Builder.Data.Id;
      Result.Value.Groups := Builder.Data.Groups;

      for Ovr of Builder.Data.Overrides loop
         declare
            Found_Same : Boolean := False;
            Conflict   : Boolean := False;
         begin
            for Existing of Result.Value.Overrides loop
               if Rule_Ids."=" (Existing.Rule, Ovr.Rule) then
                  Found_Same := True;
                  Conflict := Existing.Level /= Ovr.Level;
               end if;
            end loop;
            if Conflict then
               Result.Succeeded := False;
               Result.Errors.Append
                 (Errors.With_Rule
                    (Errors.Make (Errors.Conflicting_Override), Ovr.Rule));
               return Result;
            end if;
            if not Found_Same then
               Result.Value.Overrides.Append (Ovr);
            end if;
         end;
      end loop;

      return Result;
   end Finalize;

   function Is_Success (Item : Finalize_Outcome) return Boolean is
     (Item.Succeeded);

   function Get_Profile (Item : Finalize_Outcome) return Profile is
     (Item.Value);

   function Error_Count (Item : Finalize_Outcome) return Natural is
     (Natural (Item.Errors.Length));

   function Error_At
     (Item : Finalize_Outcome; Position : Positive) return Errors.Error is
     (Item.Errors (Position));

   ---------------------------------------------------------------------------
   --  Profile queries
   ---------------------------------------------------------------------------

   function Id (Item : Profile) return Identifiers.Profile_Id is (Item.Id);

   function Is_Group_Active
     (Item : Profile; Group : Identifiers.Rule_Group_Id) return Boolean is
     (Group_Index (Item.Groups, Group) > 0);

   function Active_Group_Count (Item : Profile) return Natural is
     (Natural (Item.Groups.Length));

   function Has_Override
     (Item : Profile; Rule : Identifiers.Rule_Id) return Boolean is
   begin
      for Ovr of Item.Overrides loop
         if Rule_Ids."=" (Ovr.Rule, Rule) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Override;

   function Effective_Severity
     (Item     : Profile;
      Rule     : Identifiers.Rule_Id;
      Declared : Issues.Severity) return Issues.Severity is
   begin
      for Ovr of Item.Overrides loop
         if Rule_Ids."=" (Ovr.Rule, Rule) then
            return Ovr.Level;
         end if;
      end loop;
      return Declared;
   end Effective_Severity;

   function Fingerprint (Item : Profile) return Fingerprints.Fingerprint is
      B      : Fingerprints.Builder := Fingerprints.Start;
      Groups : Group_Vectors.Vector := Item.Groups;

      procedure Sort_Groups is
      begin
         for I in 2 .. Natural (Groups.Length) loop
            declare
               Key : constant Identifiers.Rule_Group_Id := Groups (I);
               J   : Integer := I - 1;
            begin
               while J >= 1 and then Group_Ids."<" (Key, Groups (J)) loop
                  Groups.Replace_Element (J + 1, Groups (J));
                  J := J - 1;
               end loop;
               Groups.Replace_Element (J + 1, Key);
            end;
         end loop;
      end Sort_Groups;
   begin
      Fingerprints.Add_Tag (B, "profile");
      Fingerprints.Add_String (B, Identifiers.Profile_Ids.Image (Item.Id));
      Sort_Groups;
      Fingerprints.Add_Tag (B, "groups");
      for G of Groups loop
         Fingerprints.Add_String (B, Group_Ids.Image (G));
      end loop;
      --  Overrides are deduplicated at Finalize; contribute them in rule order.
      Fingerprints.Add_Tag (B, "overrides");
      for Ovr of Item.Overrides loop
         Fingerprints.Add_String (B, Rule_Ids.Image (Ovr.Rule));
         Fingerprints.Add_Natural (B, Issues.Severity'Pos (Ovr.Level));
      end loop;
      return Fingerprints.Finish (B);
   end Fingerprint;

   ---------------------------------------------------------------------------
   --  Profile set
   ---------------------------------------------------------------------------

   function Empty_Set return Profile_Set is
     (Items => Profile_Vectors.Empty_Vector);

   function Add
     (Item : Profile_Set; Profile : Profiles.Profile) return Profile_Set is
      Result : Profile_Set := Item;
   begin
      Result.Items.Append (Profile);
      return Result;
   end Add;

   function Count (Item : Profile_Set) return Natural is
     (Natural (Item.Items.Length));

   function Is_Group_Active
     (Item : Profile_Set; Group : Identifiers.Rule_Group_Id) return Boolean is
   begin
      for P of Item.Items loop
         if Is_Group_Active (P, Group) then
            return True;
         end if;
      end loop;
      return False;
   end Is_Group_Active;

   function Effective_Severity
     (Item     : Profile_Set;
      Rule     : Identifiers.Rule_Id;
      Declared : Issues.Severity) return Issues.Severity is
      Level : Issues.Severity := Declared;
   begin
      --  Later profile wins: overwrite as we go in precedence order.
      for P of Item.Items loop
         if Has_Override (P, Rule) then
            Level := Effective_Severity (P, Rule, Declared);
         end if;
      end loop;
      return Level;
   end Effective_Severity;

end Validation.Profiles;
