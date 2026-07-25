private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Issues;
with Validation.Errors;
with Validation.Fingerprints;

------------------------------------------------------------------------------
--  Validation.Profiles
--
--  Profiles select and configure rule subsets (§34). A profile activates rule
--  GROUPS and may override the SEVERITY of specific rules. Profiles never
--  reorder surviving rules (VAL-INV-010).
--
--  Inheritance is by COMPOSITION: Extend starts a builder from a finalized
--  parent profile. This makes inheritance cycles impossible by construction —
--  a deliberate simplification of the id-based-inheritance-with-cycle-detection
--  model in §34, documented in docs/ai/package_map.md. The remaining
--  definition error is a Conflicting_Override (the same rule overridden to two
--  different severities), detected at Finalize.
--
--  Precedence for a Profile_Set (§34): later active profile wins. Group
--  activation is the union across the active profiles.
------------------------------------------------------------------------------

package Validation.Profiles is

   type Profile is private;
   type Profile_Builder is private;

   function Begin_Profile
     (Id : Identifiers.Profile_Id) return Profile_Builder;
   function Extend
     (Parent : Profile; Id : Identifiers.Profile_Id) return Profile_Builder;

   procedure Include_Group
     (Builder : in out Profile_Builder; Group : Identifiers.Rule_Group_Id);
   procedure Exclude_Group
     (Builder : in out Profile_Builder; Group : Identifiers.Rule_Group_Id);
   procedure Override_Severity
     (Builder : in out Profile_Builder;
      Rule    : Identifiers.Rule_Id;
      Level   : Issues.Severity);

   --  Finalize outcome: a finalized Profile, or the definition errors that
   --  prevented it (currently only Conflicting_Override).
   type Finalize_Outcome is private;

   function Finalize (Builder : Profile_Builder) return Finalize_Outcome;
   function Is_Success (Item : Finalize_Outcome) return Boolean;
   function Get_Profile (Item : Finalize_Outcome) return Profile
     with Pre => Is_Success (Item);
   function Error_Count (Item : Finalize_Outcome) return Natural;
   function Error_At
     (Item : Finalize_Outcome; Position : Positive) return Errors.Error
     with Pre => Position <= Error_Count (Item);

   function Id (Item : Profile) return Identifiers.Profile_Id;
   function Is_Group_Active
     (Item : Profile; Group : Identifiers.Rule_Group_Id) return Boolean;
   function Active_Group_Count (Item : Profile) return Natural;
   function Has_Override
     (Item : Profile; Rule : Identifiers.Rule_Id) return Boolean;
   function Effective_Severity
     (Item     : Profile;
      Rule     : Identifiers.Rule_Id;
      Declared : Issues.Severity) return Issues.Severity;
   function Fingerprint (Item : Profile) return Fingerprints.Fingerprint;

   ---------------------------------------------------------------------------
   --  Ordered active-profile set (later profile has higher precedence)
   ---------------------------------------------------------------------------

   type Profile_Set is private;

   function Empty_Set return Profile_Set;
   function Add (Item : Profile_Set; Profile : Profiles.Profile) return Profile_Set;
   function Count (Item : Profile_Set) return Natural;
   function Is_Group_Active
     (Item : Profile_Set; Group : Identifiers.Rule_Group_Id) return Boolean;
   function Effective_Severity
     (Item     : Profile_Set;
      Rule     : Identifiers.Rule_Id;
      Declared : Issues.Severity) return Issues.Severity;

private

   type Override_Entry is record
      Rule  : Identifiers.Rule_Id;
      Level : Issues.Severity;
   end record;

   package Group_Vectors is new Ada.Containers.Vectors
     (Positive, Identifiers.Rule_Group_Id, Identifiers.Rule_Group_Ids."=");
   package Override_Vectors is new Ada.Containers.Vectors
     (Positive, Override_Entry);

   type Profile is record
      Id        : Identifiers.Profile_Id;
      Groups    : Group_Vectors.Vector;
      Overrides : Override_Vectors.Vector;
   end record;

   type Profile_Builder is record
      Data : Profile;
   end record;

   package Error_Vectors is new Ada.Containers.Vectors
     (Positive, Errors.Error, Errors."=");

   type Finalize_Outcome is record
      Succeeded : Boolean := True;
      Value     : Profile;
      Errors    : Error_Vectors.Vector;
   end record;

   package Profile_Vectors is new Ada.Containers.Vectors (Positive, Profile);

   type Profile_Set is record
      Items : Profile_Vectors.Vector;
   end record;

end Validation.Profiles;
