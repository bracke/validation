private with Ada.Strings.Bounded;
with Validation.Identifiers;
with Validation.Versions;
with Validation.Paths;

------------------------------------------------------------------------------
--  Validation.Values
--
--  One shared immutable neutral value model (§8), used for message-argument
--  values, metadata values, and neutral diagnostic projections. Numeric
--  semantics are preserved — values are NOT collapsed to String. Real values
--  distinguish finite / NaN / +Inf / -Inf (and signed zero via the stored
--  float); Decimal is a sign/coefficient/scale triple suitable for later
--  localization; temporal values distinguish instant / civil date / duration.
--
--  Every value carries a disclosure classification. Secret values are redacted
--  by default in Image and in any projection (VAL-INV-035). Validation.Values
--  is NOT a secret container: passwords, tokens, and verifier material must
--  never be stored here — they are inspected only through bounded secret-view
--  contracts elsewhere.
------------------------------------------------------------------------------

package Validation.Values is

   type Value_Kind is
     (Text_Value,
      Signed_Value,
      Unsigned_Value,
      Boolean_Value,
      Real_Value,
      Decimal_Value,
      Count_Value,
      Identifier_Value,
      Enumeration_Value,
      Duration_Value,
      Instant_Value,
      Civil_Date_Value,
      Path_Value,
      Opaque_Value);

   type Disclosure_Class is (Public, Internal, Confidential, Secret);

   type Real_Class is
     (Finite, Not_A_Number, Positive_Infinity, Negative_Infinity);

   type Unsigned_Word is mod 2 ** 64;
   type Count_Number is range 0 .. 2 ** 62;

   type Instant_Point is record
      Year          : Integer  := 1970;
      Month         : Positive range 1 .. 12 := 1;
      Day           : Positive range 1 .. 31 := 1;
      Second_Of_Day : Natural range 0 .. 86_400 := 0;
      Nanosecond    : Natural  := 0;
   end record;

   type Civil_Date_Point is record
      Year  : Integer := 1970;
      Month : Positive range 1 .. 12 := 1;
      Day   : Positive range 1 .. 31 := 1;
   end record;

   type Value is private;

   ---------------------------------------------------------------------------
   --  Constructors
   ---------------------------------------------------------------------------

   function Of_Text
     (Text : String; Disclosure : Disclosure_Class := Public) return Value;

   function Of_Signed
     (Item : Long_Long_Integer; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Unsigned
     (Item : Unsigned_Word; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Boolean
     (Item : Boolean; Disclosure : Disclosure_Class := Public) return Value;

   --  Finite real (accepts signed zero). Use Of_Real_Special for NaN/Inf.
   function Of_Real
     (Item : Long_Float; Disclosure : Disclosure_Class := Public) return Value;

   function Of_Real_Special
     (Class : Real_Class; Disclosure : Disclosure_Class := Public) return Value
     with Pre => Class /= Finite;

   --  Decimal as sign + coefficient digits + scale, e.g. -12.34 is
   --  (Negative => True, Coefficient => "1234", Scale => 2).
   function Of_Decimal
     (Negative    : Boolean;
      Coefficient : String;
      Scale       : Integer;
      Disclosure  : Disclosure_Class := Public) return Value;

   function Of_Count
     (Item : Count_Number; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Identifier
     (Image : String; Disclosure : Disclosure_Class := Public) return Value;

   function Of_Enumeration
     (Symbol : String; Disclosure : Disclosure_Class := Public) return Value;

   function Of_Duration
     (Item : Standard.Duration; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Instant
     (Item : Instant_Point; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Civil_Date
     (Item : Civil_Date_Point; Disclosure : Disclosure_Class := Public)
      return Value;

   function Of_Path
     (Item : Paths.Path; Disclosure : Disclosure_Class := Public) return Value;

   function Of_Opaque
     (Semantic_Type : Identifiers.Schema_Id;
      Schema        : Versions.Schema_Version;
      Payload       : String;
      Disclosure    : Disclosure_Class := Public) return Value;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Kind (Item : Value) return Value_Kind;
   function Disclosure (Item : Value) return Disclosure_Class;
   function Is_Secret (Item : Value) return Boolean;

   function As_Text (Item : Value) return String
     with Pre => Kind (Item) = Text_Value;
   function As_Signed (Item : Value) return Long_Long_Integer
     with Pre => Kind (Item) = Signed_Value;
   function As_Unsigned (Item : Value) return Unsigned_Word
     with Pre => Kind (Item) = Unsigned_Value;
   function As_Boolean (Item : Value) return Boolean
     with Pre => Kind (Item) = Boolean_Value;
   function Real_Category (Item : Value) return Real_Class
     with Pre => Kind (Item) = Real_Value;
   function As_Real (Item : Value) return Long_Float
     with Pre => Kind (Item) = Real_Value
                 and then Real_Category (Item) = Finite;
   function As_Count (Item : Value) return Count_Number
     with Pre => Kind (Item) = Count_Value;
   function As_Path (Item : Value) return Paths.Path
     with Pre => Kind (Item) = Path_Value;

   --  Neutral, locale-independent rendering for diagnostics and fingerprints.
   --  Secret values render as "<secret>"; the actual content never appears.
   function Image (Item : Value) return String;

   function "=" (Left, Right : Value) return Boolean;

private

   package Text_Store is new Ada.Strings.Bounded.Generic_Bounded_Length (512);
   package Digit_Store is new Ada.Strings.Bounded.Generic_Bounded_Length (64);
   package Blob_Store is new Ada.Strings.Bounded.Generic_Bounded_Length (512);

   type Value (Kind : Value_Kind := Text_Value) is record
      Disclosure : Disclosure_Class := Public;
      case Kind is
         when Text_Value =>
            Text : Text_Store.Bounded_String;
         when Signed_Value =>
            Signed : Long_Long_Integer;
         when Unsigned_Value =>
            Unsigned : Unsigned_Word;
         when Boolean_Value =>
            Bool : Boolean;
         when Real_Value =>
            Real_Kind : Real_Class;
            Magnitude : Long_Float;
         when Decimal_Value =>
            Dec_Negative    : Boolean;
            Dec_Coefficient : Digit_Store.Bounded_String;
            Dec_Scale       : Integer;
         when Count_Value =>
            Count : Count_Number;
         when Identifier_Value =>
            Ident : Text_Store.Bounded_String;
         when Enumeration_Value =>
            Symbol : Text_Store.Bounded_String;
         when Duration_Value =>
            Dur : Standard.Duration;
         when Instant_Value =>
            Instant : Instant_Point;
         when Civil_Date_Value =>
            Date : Civil_Date_Point;
         when Path_Value =>
            Path_Ref : Paths.Path;
         when Opaque_Value =>
            Opaque_Type    : Identifiers.Schema_Id;
            Opaque_Version : Versions.Schema_Version;
            Opaque_Blob    : Blob_Store.Bounded_String;
      end case;
   end record;

end Validation.Values;
