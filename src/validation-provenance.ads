private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Phases;

------------------------------------------------------------------------------
--  Validation.Provenance
--
--  Every issue carries provenance: at minimum its originating validator id,
--  rule id, and issue ordinal (§14, VAL-INV-007). Two modes:
--
--    Minimal  — validator id, rule id, issue ordinal.
--    Standard — additionally: root validator id, nested validator chain, phase,
--               declaration ordinal, active profile ids, and (optionally) a
--               deferred check id / continuation round / composition branch.
--
--  A detailed execution TRACE is a separate, non-semantic concern (Phase 10);
--  it is excluded from equality, fingerprints, and continuation compatibility.
------------------------------------------------------------------------------

package Validation.Provenance is

   type Provenance_Mode is (Minimal, Standard);

   type Provenance is private;

   function Make_Minimal
     (Validator     : Identifiers.Validator_Id;
      Rule          : Identifiers.Rule_Id;
      Issue_Ordinal : Positive) return Provenance;

   type Provenance_Builder is private;

   function Begin_Standard
     (Validator           : Identifiers.Validator_Id;
      Rule                : Identifiers.Rule_Id;
      Issue_Ordinal       : Positive;
      Phase               : Phases.Phase;
      Declaration_Ordinal : Positive) return Provenance_Builder;

   procedure Set_Root
     (Builder : in out Provenance_Builder; Root : Identifiers.Validator_Id);
   procedure Add_Nested
     (Builder : in out Provenance_Builder; Validator : Identifiers.Validator_Id);
   procedure Add_Profile
     (Builder : in out Provenance_Builder; Profile : Identifiers.Profile_Id);

   function Build (Builder : Provenance_Builder) return Provenance;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Mode (Item : Provenance) return Provenance_Mode;
   function Validator (Item : Provenance) return Identifiers.Validator_Id;
   function Rule (Item : Provenance) return Identifiers.Rule_Id;
   function Issue_Ordinal (Item : Provenance) return Positive;

   function Phase (Item : Provenance) return Phases.Phase
     with Pre => Mode (Item) = Standard;
   function Declaration_Ordinal (Item : Provenance) return Positive
     with Pre => Mode (Item) = Standard;
   function Has_Root (Item : Provenance) return Boolean;
   function Root (Item : Provenance) return Identifiers.Validator_Id
     with Pre => Has_Root (Item);
   function Nested_Count (Item : Provenance) return Natural;
   function Nested_At
     (Item : Provenance; Position : Positive) return Identifiers.Validator_Id
     with Pre => Position <= Nested_Count (Item);
   function Profile_Count (Item : Provenance) return Natural;
   function Profile_At
     (Item : Provenance; Position : Positive) return Identifiers.Profile_Id
     with Pre => Position <= Profile_Count (Item);

private

   package Validator_Vectors is new Ada.Containers.Vectors
     (Positive, Identifiers.Validator_Id, Identifiers.Validator_Ids."=");
   package Profile_Vectors is new Ada.Containers.Vectors
     (Positive, Identifiers.Profile_Id, Identifiers.Profile_Ids."=");

   type Provenance is record
      Mode                : Provenance_Mode := Minimal;
      Validator           : Identifiers.Validator_Id;
      Rule                : Identifiers.Rule_Id;
      Ordinal             : Positive := 1;
      Phase               : Phases.Phase := Phases.Phase_Value;
      Declaration_Ordinal : Positive := 1;
      Has_Root_Flag       : Boolean := False;
      Root                : Identifiers.Validator_Id;
      Nested              : Validator_Vectors.Vector;
      Profiles            : Profile_Vectors.Vector;
   end record;

   type Provenance_Builder is record
      Data : Provenance;
   end record;

end Validation.Provenance;
