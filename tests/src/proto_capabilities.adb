package body Proto_Capabilities is

   use type Id_Strings.Bounded_String;

   function New_Builder return Builder is
   begin
      return (Items => Holder_Vectors.Empty_Vector);
   end New_Builder;

   function Freeze (B : Builder) return Container is
   begin
      return (Items => B.Items);
   end Freeze;

   function Cardinality (C : Container) return Natural is
   begin
      return Natural (C.Items.Length);
   end Cardinality;

   package body Capability is

      --  Concrete holder carrying the typed value. Declared here, in a body
      --  that sees Proto_Capabilities' private part, so no type erasure leaks
      --  into the public API.
      type Value_Holder is new Holder with record
         Val : Value_Type;
      end record;

      Bounded_Id : constant Id_Strings.Bounded_String :=
        Id_Strings.To_Bounded_String (Capability_Id);

      procedure Put
        (B      : in out Builder;
         Value  : Value_Type;
         Result : out Add_Result) is
      begin
         if Capability_Id'Length = 0 then
            Result := Empty_Capability_Id;
            return;
         end if;

         for E of B.Items loop
            if E.Id = Bounded_Id then
               Result := Duplicate_Capability;
               return;
            end if;
         end loop;

         declare
            H : Value_Holder;
         begin
            H.Id      := Bounded_Id;
            H.Version := Schema_Version;
            H.Val     := Value;
            B.Items.Append (H);
         end;
         Result := Added;
      end Put;

      function Present (C : Container) return Boolean is
      begin
         for E of C.Items loop
            if E.Id = Bounded_Id
              and then E.Version = Schema_Version
              and then E in Value_Holder'Class
            then
               return True;
            end if;
         end loop;
         return False;
      end Present;

      procedure Get
        (C     : Container;
         Value : out Value_Type;
         Found : out Boolean) is
      begin
         Found := False;
         for E of C.Items loop
            if E.Id = Bounded_Id then
               --  Matching id: accept only when the schema version and the
               --  concrete value type both agree. A checked view conversion
               --  recovers the value; the guard makes it never raise.
               if E.Version = Schema_Version and then E in Value_Holder'Class
               then
                  Value := Value_Holder (E).Val;
                  Found := True;
               end if;
               return;
            end if;
         end loop;
      end Get;

   end Capability;

end Proto_Capabilities;
