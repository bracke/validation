package body Validation.Outcomes is

   use type Error_Vectors.Vector;

   function Success (Value : Value_Type) return Outcome is
     (Succeeded => True, Value => Value);

   function Failure (Errors : Error_Array) return Outcome is
      Result : Outcome := (Succeeded => False, Errors => Error_Vectors.Empty_Vector);
   begin
      for E of Errors loop
         Result.Errors.Append (E);
      end loop;
      return Result;
   end Failure;

   function Failure (Error : Error_Type) return Outcome is
      Result : Outcome := (Succeeded => False, Errors => Error_Vectors.Empty_Vector);
   begin
      Result.Errors.Append (Error);
      return Result;
   end Failure;

   function Is_Success (Item : Outcome) return Boolean is (Item.Succeeded);

   function Is_Failure (Item : Outcome) return Boolean is (not Item.Succeeded);

   function Value_Of (Item : Outcome) return Value_Type is (Item.Value);

   function Error_Count (Item : Outcome) return Natural is
     (if Item.Succeeded then 0 else Natural (Item.Errors.Length));

   function Element (Item : Outcome; Index : Positive) return Error_Type is
     (Item.Errors (Index));

   function "=" (Left, Right : Outcome) return Boolean is
   begin
      if Left.Succeeded /= Right.Succeeded then
         return False;
      elsif Left.Succeeded then
         return Left.Value = Right.Value;
      else
         return Left.Errors = Right.Errors;
      end if;
   end "=";

end Validation.Outcomes;
