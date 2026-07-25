with Ada.Characters.Handling;

package body Validation.Errors is

   use type Paths.Path;
   use type Metadata.Metadata;

   function Domain_Of (Code : Error_Code) return Error_Domain is
     (if Code <= Recursive_Edge_Without_Identity then Definition else Invocation);

   function Make (Code : Error_Code) return Error is
   begin
      return E : Error do
         E.Code := Code;
      end return;
   end Make;

   function With_Path (Item : Error; Path : Paths.Path) return Error is
      Result : Error := Item;
   begin
      Result.Path_Set := True;
      Result.Path_Ref := Path;
      return Result;
   end With_Path;

   function With_Validator
     (Item : Error; Validator : Identifiers.Validator_Id) return Error is
      Result : Error := Item;
   begin
      Result.Validator_Set := True;
      Result.Validator_Ref := Validator;
      return Result;
   end With_Validator;

   function With_Rule (Item : Error; Rule : Identifiers.Rule_Id) return Error is
      Result : Error := Item;
   begin
      Result.Rule_Set := True;
      Result.Rule_Ref := Rule;
      return Result;
   end With_Rule;

   function With_Detail
     (Item : Error; Detail : Metadata.Metadata) return Error is
      Result : Error := Item;
   begin
      Result.Detail_Data := Detail;
      return Result;
   end With_Detail;

   function Code_Of (Item : Error) return Error_Code is (Item.Code);
   function Domain_Of (Item : Error) return Error_Domain is
     (Domain_Of (Item.Code));

   function Key (Code : Error_Code) return String is
      Prefix : constant String :=
        (if Domain_Of (Code) = Definition then "definition" else "invocation");
   begin
      return Prefix & "."
        & Ada.Characters.Handling.To_Lower (Error_Code'Image (Code));
   end Key;

   function Key (Item : Error) return String is (Key (Item.Code));

   function Has_Path (Item : Error) return Boolean is (Item.Path_Set);
   function Path (Item : Error) return Paths.Path is (Item.Path_Ref);
   function Has_Validator (Item : Error) return Boolean is (Item.Validator_Set);
   function Validator (Item : Error) return Identifiers.Validator_Id is
     (Item.Validator_Ref);
   function Has_Rule (Item : Error) return Boolean is (Item.Rule_Set);
   function Rule (Item : Error) return Identifiers.Rule_Id is (Item.Rule_Ref);
   function Detail (Item : Error) return Metadata.Metadata is (Item.Detail_Data);

   overriding function "=" (Left, Right : Error) return Boolean is
      use type Identifiers.Validator_Id;
      use type Identifiers.Rule_Id;
   begin
      if Left.Code /= Right.Code
        or else Left.Path_Set /= Right.Path_Set
        or else Left.Validator_Set /= Right.Validator_Set
        or else Left.Rule_Set /= Right.Rule_Set
      then
         return False;
      end if;
      if Left.Path_Set and then Left.Path_Ref /= Right.Path_Ref then
         return False;
      end if;
      if Left.Validator_Set
        and then Left.Validator_Ref /= Right.Validator_Ref
      then
         return False;
      end if;
      if Left.Rule_Set and then Left.Rule_Ref /= Right.Rule_Ref then
         return False;
      end if;
      return Left.Detail_Data = Right.Detail_Data;
   end "=";

end Validation.Errors;
