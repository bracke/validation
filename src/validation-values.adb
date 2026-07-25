package body Validation.Values is

   use type Text_Store.Bounded_String;
   use type Digit_Store.Bounded_String;
   use type Blob_Store.Bounded_String;
   use type Identifiers.Schema_Id;
   use type Versions.Schema_Version;

   function Trim (S : String) return String is
     (if S'Length > 0 and then S (S'First) = ' '
      then S (S'First + 1 .. S'Last) else S);

   function Pad (Value, Width : Natural) return String is
      Raw    : constant String := Trim (Natural'Image (Value));
      Result : String (1 .. Width) := [others => '0'];
   begin
      if Raw'Length >= Width then
         return Raw;
      end if;
      Result (Width - Raw'Length + 1 .. Width) := Raw;
      return Result;
   end Pad;

   ---------------------------------------------------------------------------
   --  Constructors
   ---------------------------------------------------------------------------

   function Of_Text
     (Text : String; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Text_Value, Disclosure => Disclosure,
      Text => Text_Store.To_Bounded_String (Text));

   function Of_Signed
     (Item : Long_Long_Integer; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Signed_Value, Disclosure => Disclosure, Signed => Item);

   function Of_Unsigned
     (Item : Unsigned_Word; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Unsigned_Value, Disclosure => Disclosure, Unsigned => Item);

   function Of_Boolean
     (Item : Boolean; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Boolean_Value, Disclosure => Disclosure, Bool => Item);

   function Of_Real
     (Item : Long_Float; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Real_Value, Disclosure => Disclosure,
      Real_Kind => Finite, Magnitude => Item);

   function Of_Real_Special
     (Class : Real_Class; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Real_Value, Disclosure => Disclosure,
      Real_Kind => Class, Magnitude => 0.0);

   function Of_Decimal
     (Negative    : Boolean;
      Coefficient : String;
      Scale       : Integer;
      Disclosure  : Disclosure_Class := Public) return Value is
     (Kind => Decimal_Value, Disclosure => Disclosure,
      Dec_Negative => Negative,
      Dec_Coefficient => Digit_Store.To_Bounded_String (Coefficient),
      Dec_Scale => Scale);

   function Of_Count
     (Item : Count_Number; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Count_Value, Disclosure => Disclosure, Count => Item);

   function Of_Identifier
     (Image : String; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Identifier_Value, Disclosure => Disclosure,
      Ident => Text_Store.To_Bounded_String (Image));

   function Of_Enumeration
     (Symbol : String; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Enumeration_Value, Disclosure => Disclosure,
      Symbol => Text_Store.To_Bounded_String (Symbol));

   function Of_Duration
     (Item : Standard.Duration; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Duration_Value, Disclosure => Disclosure, Dur => Item);

   function Of_Instant
     (Item : Instant_Point; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Instant_Value, Disclosure => Disclosure, Instant => Item);

   function Of_Civil_Date
     (Item : Civil_Date_Point; Disclosure : Disclosure_Class := Public)
      return Value is
     (Kind => Civil_Date_Value, Disclosure => Disclosure, Date => Item);

   function Of_Path
     (Item : Paths.Path; Disclosure : Disclosure_Class := Public) return Value is
     (Kind => Path_Value, Disclosure => Disclosure, Path_Ref => Item);

   function Of_Opaque
     (Semantic_Type : Identifiers.Schema_Id;
      Schema        : Versions.Schema_Version;
      Payload       : String;
      Disclosure    : Disclosure_Class := Public) return Value is
     (Kind => Opaque_Value, Disclosure => Disclosure,
      Opaque_Type => Semantic_Type, Opaque_Version => Schema,
      Opaque_Blob => Blob_Store.To_Bounded_String (Payload));

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Kind (Item : Value) return Value_Kind is (Item.Kind);
   function Disclosure (Item : Value) return Disclosure_Class is
     (Item.Disclosure);
   function Is_Secret (Item : Value) return Boolean is
     (Item.Disclosure = Secret);

   function As_Text (Item : Value) return String is
     (Text_Store.To_String (Item.Text));
   function As_Signed (Item : Value) return Long_Long_Integer is (Item.Signed);
   function As_Unsigned (Item : Value) return Unsigned_Word is (Item.Unsigned);
   function As_Boolean (Item : Value) return Boolean is (Item.Bool);
   function Real_Category (Item : Value) return Real_Class is (Item.Real_Kind);
   function As_Real (Item : Value) return Long_Float is (Item.Magnitude);
   function As_Count (Item : Value) return Count_Number is (Item.Count);
   function As_Path (Item : Value) return Paths.Path is (Item.Path_Ref);

   ---------------------------------------------------------------------------
   --  Rendering
   ---------------------------------------------------------------------------

   function Image (Item : Value) return String is
   begin
      if Is_Secret (Item) then
         return "<secret>";
      end if;
      case Item.Kind is
         when Text_Value =>
            return Text_Store.To_String (Item.Text);
         when Signed_Value =>
            return Trim (Long_Long_Integer'Image (Item.Signed));
         when Unsigned_Value =>
            return Trim (Unsigned_Word'Image (Item.Unsigned));
         when Boolean_Value =>
            return (if Item.Bool then "true" else "false");
         when Real_Value =>
            case Item.Real_Kind is
               when Finite =>
                  return Trim (Long_Float'Image (Item.Magnitude));
               when Not_A_Number =>
                  return "NaN";
               when Positive_Infinity =>
                  return "+Inf";
               when Negative_Infinity =>
                  return "-Inf";
            end case;
         when Decimal_Value =>
            return (if Item.Dec_Negative then "-" else "")
              & Digit_Store.To_String (Item.Dec_Coefficient)
              & "E" & Trim (Integer'Image (-Item.Dec_Scale));
         when Count_Value =>
            return Trim (Count_Number'Image (Item.Count));
         when Identifier_Value =>
            return Text_Store.To_String (Item.Ident);
         when Enumeration_Value =>
            return Text_Store.To_String (Item.Symbol);
         when Duration_Value =>
            return Trim (Standard.Duration'Image (Item.Dur));
         when Instant_Value =>
            return Pad (Natural (Item.Instant.Year), 4) & "-"
              & Pad (Item.Instant.Month, 2) & "-"
              & Pad (Item.Instant.Day, 2) & "T"
              & Trim (Natural'Image (Item.Instant.Second_Of_Day)) & "s"
              & Trim (Natural'Image (Item.Instant.Nanosecond)) & "ns";
         when Civil_Date_Value =>
            return Pad (Natural (Item.Date.Year), 4) & "-"
              & Pad (Item.Date.Month, 2) & "-" & Pad (Item.Date.Day, 2);
         when Path_Value =>
            return Paths.Render (Item.Path_Ref);
         when Opaque_Value =>
            return "opaque:" & Identifiers.Schema_Ids.Image (Item.Opaque_Type)
              & ":" & Trim (Versions.Schema_Version'Image (Item.Opaque_Version));
      end case;
   end Image;

   ---------------------------------------------------------------------------
   --  Equality
   ---------------------------------------------------------------------------

   function "=" (Left, Right : Value) return Boolean is
   begin
      if Left.Kind /= Right.Kind
        or else Left.Disclosure /= Right.Disclosure
      then
         return False;
      end if;
      case Left.Kind is
         when Text_Value =>
            return Left.Text = Right.Text;
         when Signed_Value =>
            return Left.Signed = Right.Signed;
         when Unsigned_Value =>
            return Left.Unsigned = Right.Unsigned;
         when Boolean_Value =>
            return Left.Bool = Right.Bool;
         when Real_Value =>
            if Left.Real_Kind /= Right.Real_Kind then
               return False;
            end if;
            return Left.Real_Kind /= Finite
              or else Left.Magnitude = Right.Magnitude;
         when Decimal_Value =>
            return Left.Dec_Negative = Right.Dec_Negative
              and then Left.Dec_Coefficient = Right.Dec_Coefficient
              and then Left.Dec_Scale = Right.Dec_Scale;
         when Count_Value =>
            return Left.Count = Right.Count;
         when Identifier_Value =>
            return Left.Ident = Right.Ident;
         when Enumeration_Value =>
            return Left.Symbol = Right.Symbol;
         when Duration_Value =>
            return Left.Dur = Right.Dur;
         when Instant_Value =>
            return Left.Instant = Right.Instant;
         when Civil_Date_Value =>
            return Left.Date = Right.Date;
         when Path_Value =>
            return Paths."=" (Left.Path_Ref, Right.Path_Ref);
         when Opaque_Value =>
            return Left.Opaque_Type = Right.Opaque_Type
              and then Left.Opaque_Version = Right.Opaque_Version
              and then Left.Opaque_Blob = Right.Opaque_Blob;
      end case;
   end "=";

end Validation.Values;
