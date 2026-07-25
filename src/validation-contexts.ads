private with Ada.Containers.Indefinite_Vectors;
private with Ada.Strings.Bounded;
with Ada.Containers;
with Validation.Identifiers;
with Validation.Versions;
with Validation.Values;
with Validation.Fingerprints;
with Validation.Errors;

------------------------------------------------------------------------------
--  Validation.Contexts
--
--  A finalized immutable heterogeneous typed-capability container (§30-33),
--  built on the Phase 0 storage model (ADR-015): unrelated capability value
--  types stored by value, inserted and retrieved only through matching typed
--  generic instances, with no public type erasure and no address identity.
--
--  Every capability carries: capability id, schema id + version, TRUST
--  PROVENANCE, sensitivity, ownership policy, fingerprint-contribution policy,
--  and continuation-safety. Retrieval is trust-aware: a Proposed_Untrusted_Value
--  can never satisfy a request that accepts only trusted provenance classes
--  (VAL-INV-036), even when the Ada value type and id text match.
--
--  Deferred to later phases: context overlays (§33) and context projections;
--  the standard capability patterns (clock/locale/tenant/...) are provided as
--  application-defined instances, not core packages (§33).
------------------------------------------------------------------------------

package Validation.Contexts is

   ---------------------------------------------------------------------------
   --  Capability metadata classifications
   ---------------------------------------------------------------------------

   type Trust_Provenance is
     (Trusted_Application_Fact,
      Identity_Attested_Fact,
      Authorization_Derived_Fact,
      Externally_Validated_Fact,
      Proposed_Untrusted_Value,
      Diagnostic_Only);

   type Ownership_Policy is
     (Copied, Shared_Immutable, Borrowed_Immutable, Stable_Handle);

   type Continuation_Safety is
     (Invocation_Only, Continuation_Safe, Externally_Serializable);

   type Fingerprint_Contribution is
     (Include_Canonical_Value,
      Include_Caller_Token,
      Include_Id_And_Version,
      Exclude,
      Continuation_Forbidden);

   type Trust_Set is array (Trust_Provenance) of Boolean;

   Any_Trust : constant Trust_Set := [others => True];

   --  Trusted classes only: excludes Proposed_Untrusted_Value and
   --  Diagnostic_Only (VAL-INV-036).
   Trusted_Facts : constant Trust_Set :=
     [Trusted_Application_Fact
      | Identity_Attested_Fact
      | Authorization_Derived_Fact
      | Externally_Validated_Fact => True,
      others => False];

   type Capability_Metadata is record
      Cap_Id             : Identifiers.Capability_Id;
      Schema             : Identifiers.Schema_Id;
      Version            : Versions.Schema_Version := 1;
      Trust              : Trust_Provenance := Trusted_Application_Fact;
      Sensitivity        : Values.Disclosure_Class := Values.Internal;
      Ownership          : Ownership_Policy := Copied;
      Fingerprint_Policy : Fingerprint_Contribution := Include_Id_And_Version;
      Continuation       : Continuation_Safety := Invocation_Only;
   end record;

   ---------------------------------------------------------------------------
   --  Container
   ---------------------------------------------------------------------------

   type Context is private;
   type Builder is private;

   function New_Builder return Builder;
   function Freeze (Item : Builder) return Context;
   procedure Set_Token (Item : in out Builder; Token : String);

   type Add_Result is (Added, Duplicate_Capability, Empty_Capability_Id);

   function Cardinality (Item : Context) return Natural;
   function Has_Token (Item : Context) return Boolean;
   function Token (Item : Context) return String with Pre => Has_Token (Item);

   --  Untyped metadata lookup (metadata only, never the value).
   function Has_Capability
     (Item : Context; Cap_Id : Identifiers.Capability_Id) return Boolean;
   function Metadata_Of
     (Item : Context; Cap_Id : Identifiers.Capability_Id)
      return Capability_Metadata
     with Pre => Has_Capability (Item, Cap_Id);

   ---------------------------------------------------------------------------
   --  Deterministic fingerprint (§30) and continuation safety
   ---------------------------------------------------------------------------

   --  Over capabilities in canonical (id-sorted) order, honouring each
   --  capability's fingerprint-contribution policy. Insertion order does not
   --  affect the result (VAL-INV-021).
   function Fingerprint (Item : Context) return Fingerprints.Fingerprint;

   --  False when any capability forbids continuation or is invocation-only.
   function Is_Continuation_Safe (Item : Context) return Boolean;

   ---------------------------------------------------------------------------
   --  Typed capability slot
   ---------------------------------------------------------------------------

   generic
      type Value_Type is private;
      Capability_Id  : String;
      Schema         : String;
      Schema_Version : Versions.Schema_Version := 1;
   package Capability is

      procedure Put
        (Item               : in out Builder;
         Value              : Value_Type;
         Trust              : Trust_Provenance;
         Sensitivity        : Values.Disclosure_Class := Values.Internal;
         Ownership          : Ownership_Policy := Copied;
         Fingerprint_Policy : Fingerprint_Contribution := Include_Id_And_Version;
         Continuation       : Continuation_Safety := Invocation_Only;
         Caller_Token       : String := "";
         Canonical          : String := "";
         Result             : out Add_Result);

      function Present (Item : Context) return Boolean;

      --  Trust-aware retrieval. Found is False when the capability is absent,
      --  its schema version differs, its concrete value type differs, OR its
      --  stored trust provenance is not in Accepted (VAL-INV-036).
      procedure Get
        (Item     : Context;
         Accepted : Trust_Set;
         Value    : out Value_Type;
         Found    : out Boolean);

   end Capability;

   ---------------------------------------------------------------------------
   --  Context contracts (§32)
   ---------------------------------------------------------------------------

   type Requirement is record
      Cap_Id   : Identifiers.Capability_Id;
      Required : Boolean := True;
      Version  : Versions.Schema_Version := 1;
      Accepted : Trust_Set := Trusted_Facts;
   end record;

   type Requirement_Array is array (Positive range <>) of Requirement;

   type Error_Array is array (Positive range <>) of Errors.Error;

   --  Checks each requirement against the context. Returns the invocation
   --  errors for missing required capabilities, version mismatches, and trust
   --  mismatches (empty array => contract satisfied).
   function Check_Contract
     (Item : Context; Requirements : Requirement_Array) return Error_Array;

private

   package Id_Store is new Ada.Strings.Bounded.Generic_Bounded_Length (256);

   type Holder is abstract tagged record
      Meta      : Capability_Metadata;
      Canonical : Id_Store.Bounded_String;
      Token     : Id_Store.Bounded_String;
   end record;

   package Holder_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Holder'Class);

   type Context is record
      Items     : Holder_Vectors.Vector;
      Token_Set : Boolean := False;
      Token     : Id_Store.Bounded_String;
   end record;

   type Builder is record
      Items     : Holder_Vectors.Vector;
      Token_Set : Boolean := False;
      Token     : Id_Store.Bounded_String;
   end record;

end Validation.Contexts;
