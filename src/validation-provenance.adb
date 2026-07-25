package body Validation.Provenance is

   function Make_Minimal
     (Validator     : Identifiers.Validator_Id;
      Rule          : Identifiers.Rule_Id;
      Issue_Ordinal : Positive) return Provenance is
   begin
      return P : Provenance do
         P.Mode := Minimal;
         P.Validator := Validator;
         P.Rule := Rule;
         P.Ordinal := Issue_Ordinal;
      end return;
   end Make_Minimal;

   function Begin_Standard
     (Validator           : Identifiers.Validator_Id;
      Rule                : Identifiers.Rule_Id;
      Issue_Ordinal       : Positive;
      Phase               : Phases.Phase;
      Declaration_Ordinal : Positive) return Provenance_Builder is
   begin
      return B : Provenance_Builder do
         B.Data.Mode := Standard;
         B.Data.Validator := Validator;
         B.Data.Rule := Rule;
         B.Data.Ordinal := Issue_Ordinal;
         B.Data.Phase := Phase;
         B.Data.Declaration_Ordinal := Declaration_Ordinal;
      end return;
   end Begin_Standard;

   procedure Set_Root
     (Builder : in out Provenance_Builder; Root : Identifiers.Validator_Id) is
   begin
      Builder.Data.Has_Root_Flag := True;
      Builder.Data.Root := Root;
   end Set_Root;

   procedure Add_Nested
     (Builder : in out Provenance_Builder; Validator : Identifiers.Validator_Id) is
   begin
      Builder.Data.Nested.Append (Validator);
   end Add_Nested;

   procedure Add_Profile
     (Builder : in out Provenance_Builder; Profile : Identifiers.Profile_Id) is
   begin
      Builder.Data.Profiles.Append (Profile);
   end Add_Profile;

   function Build (Builder : Provenance_Builder) return Provenance is
     (Builder.Data);

   function Mode (Item : Provenance) return Provenance_Mode is (Item.Mode);
   function Validator (Item : Provenance) return Identifiers.Validator_Id is
     (Item.Validator);
   function Rule (Item : Provenance) return Identifiers.Rule_Id is (Item.Rule);
   function Issue_Ordinal (Item : Provenance) return Positive is (Item.Ordinal);

   function Phase (Item : Provenance) return Phases.Phase is (Item.Phase);
   function Declaration_Ordinal (Item : Provenance) return Positive is
     (Item.Declaration_Ordinal);
   function Has_Root (Item : Provenance) return Boolean is (Item.Has_Root_Flag);
   function Root (Item : Provenance) return Identifiers.Validator_Id is
     (Item.Root);
   function Nested_Count (Item : Provenance) return Natural is
     (Natural (Item.Nested.Length));
   function Nested_At
     (Item : Provenance; Position : Positive) return Identifiers.Validator_Id is
     (Item.Nested (Position));
   function Profile_Count (Item : Provenance) return Natural is
     (Natural (Item.Profiles.Length));
   function Profile_At
     (Item : Provenance; Position : Positive) return Identifiers.Profile_Id is
     (Item.Profiles (Position));

end Validation.Provenance;
