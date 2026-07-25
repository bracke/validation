private with Ada.Containers.Indefinite_Vectors;
private with Ada.Strings.Bounded;
with Ada.Containers;
with Validation.Identifiers;

------------------------------------------------------------------------------
--  Validation.Paths
--
--  Structured immutable validation paths (§9). A path is a sequence of typed
--  segments plus an absolute/relative flag — never merely a rendered string.
--  Paths are the semantic location of a value in a typed subject; rendering is
--  a separate, deterministic, redaction-aware projection.
--
--  Segment kinds: Field, Index, Key, Object_Identity, Synthetic. Index
--  segments carry an explicit index convention; Key and Object_Identity
--  segments carry a per-segment disclosure policy so sensitive keys can be
--  redacted at render time without losing the structured path. No segment ever
--  derives identity from a memory address (VAL-INV-015).
------------------------------------------------------------------------------

package Validation.Paths is

   type Segment_Kind is
     (Field, Index, Key, Object_Identity, Synthetic);

   --  How an Index segment's value is to be understood (§9).
   type Index_Convention is
     (Zero_Based_Ordinal,
      One_Based_Ordinal,
      Native_Discrete_Index,
      Semantic_Index);

   type Key_Kind is (Text_Key, Integer_Key, Enumeration_Key, Composite_Key);

   --  Stable typed locations for Synthetic segments (§9): key/value/summary/
   --  transition/source. No magic strings.
   type Synthetic_Location is
     (Key_Location,
      Value_Location,
      Summary_Location,
      Transition_Location,
      Source_Location);

   --  Per-segment disclosure policy for sensitive keys / identities (§9).
   type Disclosure_Policy is (Include, Redact, Opaque_Hash, Omit_Value);

   type Index_Value is new Long_Long_Integer;

   type Path is private;

   --  The absolute empty path (the root of a typed subject).
   function Root return Path;

   --  The empty relative path (rebased later onto some base).
   function Empty_Relative return Path;

   ---------------------------------------------------------------------------
   --  Construction (each returns a new immutable path)
   ---------------------------------------------------------------------------

   function Append_Field
     (Parent : Path; Field : Identifiers.Field_Id) return Path;

   function Append_Index
     (Parent     : Path;
      Value      : Index_Value;
      Convention : Index_Convention := Zero_Based_Ordinal) return Path;

   function Append_Key
     (Parent     : Path;
      Kind       : Key_Kind;
      Text       : String;
      Disclosure : Disclosure_Policy := Include) return Path;

   function Append_Object_Identity
     (Parent     : Path;
      Namespace  : String;
      Token      : String;
      Disclosure : Disclosure_Policy := Include) return Path;

   function Append_Synthetic
     (Parent : Path; Location : Synthetic_Location) return Path;

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Is_Absolute (Item : Path) return Boolean;
   function Is_Relative (Item : Path) return Boolean;
   function Is_Root (Item : Path) return Boolean;
   function Segment_Count (Item : Path) return Natural;

   function Parent (Item : Path) return Path
     with Pre => Segment_Count (Item) >= 1;

   function Kind_At (Item : Path; Position : Positive) return Segment_Kind
     with Pre => Position <= Segment_Count (Item);

   function Field_At (Item : Path; Position : Positive) return Identifiers.Field_Id
     with Pre => Position <= Segment_Count (Item)
                 and then Kind_At (Item, Position) = Field;

   function Index_At (Item : Path; Position : Positive) return Index_Value
     with Pre => Position <= Segment_Count (Item)
                 and then Kind_At (Item, Position) = Index;

   function Key_Text_At (Item : Path; Position : Positive) return String
     with Pre => Position <= Segment_Count (Item)
                 and then Kind_At (Item, Position) = Key;

   --  Leaf field or key name (empty when the last segment is neither).
   function Last_Name (Item : Path) return String;

   ---------------------------------------------------------------------------
   --  Relations and combination
   ---------------------------------------------------------------------------

   --  True when Prefix is an initial subsequence of Item (same absoluteness).
   function Is_Prefix_Of (Prefix, Item : Path) return Boolean;

   --  True when Item is Ancestor or lies in its subtree.
   function Is_In_Subtree_Of (Item, Ancestor : Path) return Boolean;

   --  Append every segment of Suffix (which must be relative) onto Base.
   function Concatenate (Base, Suffix : Path) return Path
     with Pre => Is_Relative (Suffix);

   --  Replace an Old_Base prefix of Item with New_Base.
   function Rebase (Item, Old_Base, New_Base : Path) return Path
     with Pre => Is_Prefix_Of (Old_Base, Item);

   ---------------------------------------------------------------------------
   --  Total order, equality, hashing
   ---------------------------------------------------------------------------

   function "=" (Left, Right : Path) return Boolean;
   function "<" (Left, Right : Path) return Boolean;
   function Hash (Item : Path) return Ada.Containers.Hash_Type;

   ---------------------------------------------------------------------------
   --  Rendering (deterministic, redaction-aware, locale-neutral)
   ---------------------------------------------------------------------------

   --  Dot/bracket notation, e.g.  $.items[3].payment<card:visa>.expiry .
   --  Absolute paths start with "$"; relative paths start at the first
   --  segment. Sensitive Key/Object_Identity segments honour their disclosure
   --  policy.
   function Render (Item : Path) return String;

private

   package Text_Store is new Ada.Strings.Bounded.Generic_Bounded_Length (128);

   type Segment (Kind : Segment_Kind := Field) is record
      case Kind is
         when Field =>
            Field_Ref : Identifiers.Field_Id;
         when Index =>
            Index_Ref  : Index_Value;
            Convention : Index_Convention;
         when Key =>
            Key_Category   : Key_Kind;
            Key_Text       : Text_Store.Bounded_String;
            Key_Disclosure : Disclosure_Policy;
         when Object_Identity =>
            Namespace       : Text_Store.Bounded_String;
            Token           : Text_Store.Bounded_String;
            Ident_Disclosure : Disclosure_Policy;
         when Synthetic =>
            Location : Synthetic_Location;
      end case;
   end record;

   package Segment_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive, Element_Type => Segment);

   type Path is record
      Absolute : Boolean := True;
      Segments : Segment_Vectors.Vector;
   end record;

end Validation.Paths;
