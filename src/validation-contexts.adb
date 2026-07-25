package body Validation.Contexts is

   package Cap_Ids renames Identifiers.Capability_Ids;
   package Schema_Ids renames Identifiers.Schema_Ids;
   use type Identifiers.Capability_Id;
   use type Versions.Schema_Version;

   ---------------------------------------------------------------------------
   --  Container basics
   ---------------------------------------------------------------------------

   function New_Builder return Builder is
     (Items => Holder_Vectors.Empty_Vector, Token_Set => False,
      Token => Id_Store.Null_Bounded_String);

   function Freeze (Item : Builder) return Context is
     (Items => Item.Items, Token_Set => Item.Token_Set, Token => Item.Token);

   procedure Set_Token (Item : in out Builder; Token : String) is
   begin
      Item.Token_Set := True;
      Item.Token := Id_Store.To_Bounded_String (Token);
   end Set_Token;

   function Cardinality (Item : Context) return Natural is
     (Natural (Item.Items.Length));

   function Has_Token (Item : Context) return Boolean is (Item.Token_Set);
   function Token (Item : Context) return String is
     (Id_Store.To_String (Item.Token));

   function Has_Capability
     (Item : Context; Cap_Id : Identifiers.Capability_Id) return Boolean is
   begin
      for H of Item.Items loop
         if H.Meta.Cap_Id = Cap_Id then
            return True;
         end if;
      end loop;
      return False;
   end Has_Capability;

   function Metadata_Of
     (Item : Context; Cap_Id : Identifiers.Capability_Id)
      return Capability_Metadata is
   begin
      for H of Item.Items loop
         if H.Meta.Cap_Id = Cap_Id then
            return H.Meta;
         end if;
      end loop;
      --  Unreachable given the precondition.
      raise Program_Error;
   end Metadata_Of;

   ---------------------------------------------------------------------------
   --  Fingerprint and continuation safety
   ---------------------------------------------------------------------------

   function Fingerprint (Item : Context) return Fingerprints.Fingerprint is
      Count : constant Natural := Natural (Item.Items.Length);
      Order : array (1 .. Count) of Positive;
      B     : Fingerprints.Builder := Fingerprints.Start;
   begin
      for I in 1 .. Count loop
         Order (I) := I;
      end loop;
      --  Insertion sort by capability id (canonical, insertion-independent).
      for I in 2 .. Count loop
         declare
            Key : constant Positive := Order (I);
            J   : Integer := I - 1;
         begin
            while J >= 1
              and then Cap_Ids."<"
                         (Item.Items (Key).Meta.Cap_Id,
                          Item.Items (Order (J)).Meta.Cap_Id)
            loop
               Order (J + 1) := Order (J);
               J := J - 1;
            end loop;
            Order (J + 1) := Key;
         end;
      end loop;

      for I in 1 .. Count loop
         declare
            H : Holder'Class renames Item.Items (Order (I));
         begin
            if H.Meta.Fingerprint_Policy /= Exclude then
               Fingerprints.Add_Tag (B, "cap");
               Fingerprints.Add_String (B, Cap_Ids.Image (H.Meta.Cap_Id));
               Fingerprints.Add_String (B, Schema_Ids.Image (H.Meta.Schema));
               Fingerprints.Add_Natural
                 (B, Natural (H.Meta.Version));
               Fingerprints.Add_Natural
                 (B, Trust_Provenance'Pos (H.Meta.Trust));
               case H.Meta.Fingerprint_Policy is
                  when Include_Canonical_Value =>
                     Fingerprints.Add_Tag (B, "val");
                     Fingerprints.Add_String
                       (B, Id_Store.To_String (H.Canonical));
                  when Include_Caller_Token =>
                     Fingerprints.Add_Tag (B, "tok");
                     Fingerprints.Add_String (B, Id_Store.To_String (H.Token));
                  when others =>
                     null;
               end case;
            end if;
         end;
      end loop;
      return Fingerprints.Finish (B);
   end Fingerprint;

   function Is_Continuation_Safe (Item : Context) return Boolean is
   begin
      for H of Item.Items loop
         if H.Meta.Fingerprint_Policy = Continuation_Forbidden
           or else H.Meta.Continuation = Invocation_Only
         then
            return False;
         end if;
      end loop;
      return True;
   end Is_Continuation_Safe;

   ---------------------------------------------------------------------------
   --  Typed capability slot
   ---------------------------------------------------------------------------

   package body Capability is

      type Value_Holder is new Holder with record
         Val : Value_Type;
      end record;

      Bounded_Cap    : constant Identifiers.Capability_Id :=
        Cap_Ids.Make (Capability_Id);
      Bounded_Schema : constant Identifiers.Schema_Id :=
        Schema_Ids.Make (Schema);

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
         Result             : out Add_Result) is
      begin
         if Capability_Id'Length = 0 then
            Result := Empty_Capability_Id;
            return;
         end if;
         for H of Item.Items loop
            if H.Meta.Cap_Id = Bounded_Cap then
               Result := Duplicate_Capability;
               return;
            end if;
         end loop;

         declare
            H : Value_Holder;
         begin
            H.Meta :=
              (Cap_Id             => Bounded_Cap,
               Schema             => Bounded_Schema,
               Version            => Schema_Version,
               Trust              => Trust,
               Sensitivity        => Sensitivity,
               Ownership          => Ownership,
               Fingerprint_Policy => Fingerprint_Policy,
               Continuation       => Continuation);
            H.Canonical := Id_Store.To_Bounded_String (Canonical);
            H.Token := Id_Store.To_Bounded_String (Caller_Token);
            H.Val := Value;
            Item.Items.Append (H);
         end;
         Result := Added;
      end Put;

      function Present (Item : Context) return Boolean is
      begin
         for H of Item.Items loop
            if H.Meta.Cap_Id = Bounded_Cap
              and then H.Meta.Version = Schema_Version
              and then H in Value_Holder'Class
            then
               return True;
            end if;
         end loop;
         return False;
      end Present;

      procedure Get
        (Item     : Context;
         Accepted : Trust_Set;
         Value    : out Value_Type;
         Found    : out Boolean) is
      begin
         Found := False;
         for H of Item.Items loop
            if H.Meta.Cap_Id = Bounded_Cap then
               if H.Meta.Version = Schema_Version
                 and then H in Value_Holder'Class
                 and then Accepted (H.Meta.Trust)
               then
                  Value := Value_Holder (H).Val;
                  Found := True;
               end if;
               return;
            end if;
         end loop;
      end Get;

   end Capability;

   ---------------------------------------------------------------------------
   --  Contracts
   ---------------------------------------------------------------------------

   function Check_Contract
     (Item : Context; Requirements : Requirement_Array) return Error_Array is
      Accumulated : Error_Array (1 .. Requirements'Length);
      Count       : Natural := 0;

      procedure Emit (E : Errors.Error) is
      begin
         Count := Count + 1;
         Accumulated (Count) := E;
      end Emit;
   begin
      for Req of Requirements loop
         if not Has_Capability (Item, Req.Cap_Id) then
            if Req.Required then
               Emit (Errors.Make (Errors.Missing_Capability));
            end if;
         else
            declare
               Meta : constant Capability_Metadata :=
                 Metadata_Of (Item, Req.Cap_Id);
            begin
               if Meta.Version /= Req.Version then
                  Emit (Errors.Make (Errors.Unsupported_Capability_Version));
               elsif not Req.Accepted (Meta.Trust) then
                  --  Present but not trusted enough: the required capability is
                  --  not satisfied (VAL-INV-036).
                  Emit (Errors.Make (Errors.Missing_Capability));
               end if;
            end;
         end if;
      end loop;
      return Accumulated (1 .. Count);
   end Check_Contract;

end Validation.Contexts;
