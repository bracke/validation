with Validation.Identifiers;
with Validation.Paths;
with Validation.Metadata;

------------------------------------------------------------------------------
--  Validation.Errors
--
--  Definition and invocation errors (§17, §25). These are kept STRICTLY
--  distinct from ordinary validation issues:
--
--    Definition error  — a validator/profile/context/adapter/schema definition
--                        or composition is malformed (a programming error).
--    Invocation error  — execution inputs or runtime contracts are incompatible
--                        (missing capability, stale continuation, callback
--                        fault, malformed/unknown/duplicate deferred result, ...).
--
--  Definition errors are carried by Validation.Outcomes at finalization;
--  invocation errors are carried in Validation.Results (they are part of the
--  execution outcome). Neither is ever placed in the ordinary issue collection.
--  Each error has a stable dotted key derived mechanically from its code.
------------------------------------------------------------------------------

package Validation.Errors is

   type Error_Domain is (Definition, Invocation);

   type Error_Code is
     (Empty_Validator_Id,   --  Definition domain
      Duplicate_Rule_Id,
      Duplicate_Field_Id,
      Duplicate_Deferred_Check_Id,
      Duplicate_Edge_Id,
      Duplicate_Ordinal,
      Unknown_Prerequisite,
      Prerequisite_Cycle,
      Profile_Inheritance_Cycle,
      Unknown_Group,
      Conflicting_Override,
      Invalid_Profile_Mapping,
      Invalid_Relative_Path,
      Invalid_Path_Scope,
      Incompatible_Collection_Capability,
      Invalid_Deferred_Schema,
      Invalid_Replacement,
      Invalid_Any_Of_No_Branches,
      Recursive_Edge_Without_Identity,
      Missing_Capability,   --  Invocation domain
      Unsupported_Capability_Version,
      Stale_Continuation,
      Callback_Fault,
      Malformed_Deferred_Result,
      Unknown_Deferred_Result,
      Duplicate_Deferred_Result,
      Invalid_Execution_Options,
      Mismatched_Profile_Set,
      Payload_Type_Mismatch,
      Context_Projection_Fault);

   function Domain_Of (Code : Error_Code) return Error_Domain;

   type Error is private;

   function Make (Code : Error_Code) return Error;

   function With_Path (Item : Error; Path : Paths.Path) return Error;
   function With_Validator
     (Item : Error; Validator : Identifiers.Validator_Id) return Error;
   function With_Rule (Item : Error; Rule : Identifiers.Rule_Id) return Error;
   function With_Detail (Item : Error; Detail : Metadata.Metadata) return Error;

   function Code_Of (Item : Error) return Error_Code;
   function Domain_Of (Item : Error) return Error_Domain;

   --  Stable dotted key, e.g. "definition.duplicate_rule_id" or
   --  "invocation.missing_capability".
   function Key (Item : Error) return String;
   function Key (Code : Error_Code) return String;

   function Has_Path (Item : Error) return Boolean;
   function Path (Item : Error) return Paths.Path with Pre => Has_Path (Item);
   function Has_Validator (Item : Error) return Boolean;
   function Validator (Item : Error) return Identifiers.Validator_Id
     with Pre => Has_Validator (Item);
   function Has_Rule (Item : Error) return Boolean;
   function Rule (Item : Error) return Identifiers.Rule_Id
     with Pre => Has_Rule (Item);
   function Detail (Item : Error) return Metadata.Metadata;

   overriding function "=" (Left, Right : Error) return Boolean;

private

   type Error is record
      Code          : Error_Code := Callback_Fault;
      Path_Set      : Boolean := False;
      Path_Ref      : Paths.Path;
      Validator_Set : Boolean := False;
      Validator_Ref : Identifiers.Validator_Id;
      Rule_Set      : Boolean := False;
      Rule_Ref      : Identifiers.Rule_Id;
      Detail_Data   : Metadata.Metadata := Metadata.Empty;
   end record;

end Validation.Errors;
