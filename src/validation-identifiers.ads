with Validation.Bounded_Identifier;
with Validation.Identifier_Syntax;

------------------------------------------------------------------------------
--  Validation.Identifiers
--
--  The library's strongly typed identifier categories (§7). Each category is a
--  distinct instantiation of Validation.Bounded_Identifier, so e.g. a
--  Validator_Id can never be assigned to a Rule_Id. Operations live in the
--  per-category ..._Ids packages; use, for example:
--
--     use type Validation.Identifiers.Validator_Ids.Id;
--
--  to bring "=", "<", etc. into view, or qualify (Validator_Ids.Make (...)).
--
--  Validation identifiers are local to the Validation domain. They are NEVER a
--  substitute for Identity.* or Authorization.* identifiers; crossing that
--  boundary requires an explicit checked adapter (VAL-INV-037). Additional
--  categories are minted the same way, on demand, as later phases need them.
------------------------------------------------------------------------------

package Validation.Identifiers is

   Max_Length : constant := Validation.Identifier_Syntax.Max_Length;

   function Is_Valid (Text : String) return Boolean
     renames Validation.Identifier_Syntax.Is_Valid;

   package Validator_Ids      is new Validation.Bounded_Identifier ("validator");
   package Rule_Ids           is new Validation.Bounded_Identifier ("rule");
   package Rule_Kind_Ids      is new Validation.Bounded_Identifier ("rule-kind");
   package Field_Ids          is new Validation.Bounded_Identifier ("field");
   package Message_Ids        is new Validation.Bounded_Identifier ("message");
   package Profile_Ids        is new Validation.Bounded_Identifier ("profile");
   package Rule_Group_Ids     is new Validation.Bounded_Identifier ("rule-group");
   package Capability_Ids     is new Validation.Bounded_Identifier ("capability");
   package Issue_Category_Ids is new Validation.Bounded_Identifier ("issue-category");
   package Machine_Codes      is new Validation.Bounded_Identifier ("machine-code");
   package Schema_Ids         is new Validation.Bounded_Identifier ("schema");
   package Argument_Names     is new Validation.Bounded_Identifier ("argument-name");
   package Metadata_Keys      is new Validation.Bounded_Identifier ("metadata-key");
   package Documentation_Ids  is new Validation.Bounded_Identifier ("documentation");
   package Implementation_Version_Ids is
     new Validation.Bounded_Identifier ("implementation-version");
   package Deferred_Check_Ids is new Validation.Bounded_Identifier ("deferred-check");
   package Source_Kind_Ids    is new Validation.Bounded_Identifier ("source-kind");
   package Source_Instance_Ids is new Validation.Bounded_Identifier ("source-instance");

   subtype Validator_Id      is Validator_Ids.Id;
   subtype Rule_Id           is Rule_Ids.Id;
   subtype Rule_Kind_Id      is Rule_Kind_Ids.Id;
   subtype Field_Id          is Field_Ids.Id;
   subtype Message_Id        is Message_Ids.Id;
   subtype Profile_Id        is Profile_Ids.Id;
   subtype Rule_Group_Id     is Rule_Group_Ids.Id;
   subtype Capability_Id     is Capability_Ids.Id;
   subtype Issue_Category_Id is Issue_Category_Ids.Id;
   subtype Machine_Code      is Machine_Codes.Id;
   subtype Schema_Id         is Schema_Ids.Id;
   subtype Argument_Name     is Argument_Names.Id;
   subtype Metadata_Key      is Metadata_Keys.Id;
   subtype Documentation_Id  is Documentation_Ids.Id;
   subtype Implementation_Version_Id is Implementation_Version_Ids.Id;
   subtype Deferred_Check_Id is Deferred_Check_Ids.Id;
   subtype Source_Kind_Id    is Source_Kind_Ids.Id;
   subtype Source_Instance_Id is Source_Instance_Ids.Id;

end Validation.Identifiers;
