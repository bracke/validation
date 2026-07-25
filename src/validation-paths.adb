with Ada.Strings.Hash;
with Ada.Strings.Unbounded;

package body Validation.Paths is

   package Field_Ids renames Identifiers.Field_Ids;
   use type Text_Store.Bounded_String;
   use type Ada.Containers.Count_Type;

   ---------------------------------------------------------------------------
   --  Roots and construction
   ---------------------------------------------------------------------------

   function Root return Path is
     (Absolute => True, Segments => Segment_Vectors.Empty_Vector);

   function Empty_Relative return Path is
     (Absolute => False, Segments => Segment_Vectors.Empty_Vector);

   function With_Segment (Parent : Path; Seg : Segment) return Path is
      Result : Path := Parent;
   begin
      Result.Segments.Append (Seg);
      return Result;
   end With_Segment;

   function Append_Field
     (Parent : Path; Field : Identifiers.Field_Id) return Path is
     (With_Segment (Parent, (Kind => Paths.Field, Field_Ref => Field)));

   function Append_Index
     (Parent     : Path;
      Value      : Index_Value;
      Convention : Index_Convention := Zero_Based_Ordinal) return Path is
     (With_Segment
        (Parent,
         (Kind => Index, Index_Ref => Value, Convention => Convention)));

   function Append_Key
     (Parent     : Path;
      Kind       : Key_Kind;
      Text       : String;
      Disclosure : Disclosure_Policy := Include) return Path is
     (With_Segment
        (Parent,
         (Kind           => Paths.Key,
          Key_Category   => Kind,
          Key_Text       => Text_Store.To_Bounded_String (Text),
          Key_Disclosure => Disclosure)));

   function Append_Object_Identity
     (Parent     : Path;
      Namespace  : String;
      Token      : String;
      Disclosure : Disclosure_Policy := Include) return Path is
     (With_Segment
        (Parent,
         (Kind             => Object_Identity,
          Namespace        => Text_Store.To_Bounded_String (Namespace),
          Token            => Text_Store.To_Bounded_String (Token),
          Ident_Disclosure => Disclosure)));

   function Append_Synthetic
     (Parent : Path; Location : Synthetic_Location) return Path is
     (With_Segment (Parent, (Kind => Synthetic, Location => Location)));

   ---------------------------------------------------------------------------
   --  Queries
   ---------------------------------------------------------------------------

   function Is_Absolute (Item : Path) return Boolean is (Item.Absolute);
   function Is_Relative (Item : Path) return Boolean is (not Item.Absolute);

   function Segment_Count (Item : Path) return Natural is
     (Natural (Item.Segments.Length));

   function Is_Root (Item : Path) return Boolean is
     (Item.Absolute and then Item.Segments.Is_Empty);

   function Parent (Item : Path) return Path is
      Result : Path := Item;
   begin
      Result.Segments.Delete_Last;
      return Result;
   end Parent;

   function Kind_At (Item : Path; Position : Positive) return Segment_Kind is
     (Item.Segments (Position).Kind);

   function Field_At
     (Item : Path; Position : Positive) return Identifiers.Field_Id is
     (Item.Segments (Position).Field_Ref);

   function Index_At (Item : Path; Position : Positive) return Index_Value is
     (Item.Segments (Position).Index_Ref);

   function Key_Text_At (Item : Path; Position : Positive) return String is
     (Text_Store.To_String (Item.Segments (Position).Key_Text));

   function Last_Name (Item : Path) return String is
   begin
      if Item.Segments.Is_Empty then
         return "";
      end if;
      declare
         Last : constant Segment := Item.Segments.Last_Element;
      begin
         case Last.Kind is
            when Field =>
               return Field_Ids.Image (Last.Field_Ref);
            when Key =>
               return Text_Store.To_String (Last.Key_Text);
            when others =>
               return "";
         end case;
      end;
   end Last_Name;

   ---------------------------------------------------------------------------
   --  Segment comparison
   ---------------------------------------------------------------------------

   function Seg_Equal (Left, Right : Segment) return Boolean is
   begin
      if Left.Kind /= Right.Kind then
         return False;
      end if;
      case Left.Kind is
         when Field =>
            return Field_Ids."=" (Left.Field_Ref, Right.Field_Ref);
         when Index =>
            return Left.Index_Ref = Right.Index_Ref
              and then Left.Convention = Right.Convention;
         when Key =>
            return Left.Key_Category = Right.Key_Category
              and then Left.Key_Text = Right.Key_Text
              and then Left.Key_Disclosure = Right.Key_Disclosure;
         when Object_Identity =>
            return Left.Namespace = Right.Namespace
              and then Left.Token = Right.Token
              and then Left.Ident_Disclosure = Right.Ident_Disclosure;
         when Synthetic =>
            return Left.Location = Right.Location;
      end case;
   end Seg_Equal;

   function Seg_Less (Left, Right : Segment) return Boolean is
   begin
      if Left.Kind /= Right.Kind then
         return Segment_Kind'Pos (Left.Kind) < Segment_Kind'Pos (Right.Kind);
      end if;
      case Left.Kind is
         when Field =>
            return Field_Ids."<" (Left.Field_Ref, Right.Field_Ref);
         when Index =>
            if Left.Convention /= Right.Convention then
               return Index_Convention'Pos (Left.Convention)
                 < Index_Convention'Pos (Right.Convention);
            end if;
            return Left.Index_Ref < Right.Index_Ref;
         when Key =>
            if Left.Key_Category /= Right.Key_Category then
               return Key_Kind'Pos (Left.Key_Category)
                 < Key_Kind'Pos (Right.Key_Category);
            end if;
            return Text_Store."<" (Left.Key_Text, Right.Key_Text);
         when Object_Identity =>
            if Left.Namespace /= Right.Namespace then
               return Text_Store."<" (Left.Namespace, Right.Namespace);
            end if;
            return Text_Store."<" (Left.Token, Right.Token);
         when Synthetic =>
            return Synthetic_Location'Pos (Left.Location)
              < Synthetic_Location'Pos (Right.Location);
      end case;
   end Seg_Less;

   ---------------------------------------------------------------------------
   --  Relations and combination
   ---------------------------------------------------------------------------

   function Is_Prefix_Of (Prefix, Item : Path) return Boolean is
   begin
      if Prefix.Absolute /= Item.Absolute
        or else Prefix.Segments.Length > Item.Segments.Length
      then
         return False;
      end if;
      for I in 1 .. Natural (Prefix.Segments.Length) loop
         if not Seg_Equal (Prefix.Segments (I), Item.Segments (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Prefix_Of;

   function Is_In_Subtree_Of (Item, Ancestor : Path) return Boolean is
     (Is_Prefix_Of (Ancestor, Item));

   function Concatenate (Base, Suffix : Path) return Path is
      Result : Path := Base;
   begin
      for Seg of Suffix.Segments loop
         Result.Segments.Append (Seg);
      end loop;
      return Result;
   end Concatenate;

   function Rebase (Item, Old_Base, New_Base : Path) return Path is
      Result : Path := New_Base;
   begin
      for I in Natural (Old_Base.Segments.Length) + 1
                 .. Natural (Item.Segments.Length)
      loop
         Result.Segments.Append (Item.Segments (I));
      end loop;
      return Result;
   end Rebase;

   ---------------------------------------------------------------------------
   --  Order, equality, hashing
   ---------------------------------------------------------------------------

   function "=" (Left, Right : Path) return Boolean is
   begin
      if Left.Absolute /= Right.Absolute
        or else Left.Segments.Length /= Right.Segments.Length
      then
         return False;
      end if;
      for I in 1 .. Natural (Left.Segments.Length) loop
         if not Seg_Equal (Left.Segments (I), Right.Segments (I)) then
            return False;
         end if;
      end loop;
      return True;
   end "=";

   function "<" (Left, Right : Path) return Boolean is
      Common : constant Natural :=
        Natural'Min (Natural (Left.Segments.Length),
                     Natural (Right.Segments.Length));
   begin
      if Left.Absolute /= Right.Absolute then
         --  Absolute paths sort before relative ones.
         return Left.Absolute;
      end if;
      for I in 1 .. Common loop
         if not Seg_Equal (Left.Segments (I), Right.Segments (I)) then
            return Seg_Less (Left.Segments (I), Right.Segments (I));
         end if;
      end loop;
      return Left.Segments.Length < Right.Segments.Length;
   end "<";

   function Seg_Hash (Seg : Segment) return Ada.Containers.Hash_Type is
      use type Ada.Containers.Hash_Type;
      H : Ada.Containers.Hash_Type :=
        Ada.Containers.Hash_Type (Segment_Kind'Pos (Seg.Kind));
   begin
      case Seg.Kind is
         when Field =>
            H := H * 31 + Field_Ids.Hash (Seg.Field_Ref);
         when Index =>
            H := H * 31
              + Ada.Containers.Hash_Type
                  (Index_Convention'Pos (Seg.Convention))
              + Ada.Strings.Hash (Index_Value'Image (Seg.Index_Ref));
         when Key =>
            H := H * 31
              + Ada.Strings.Hash (Text_Store.To_String (Seg.Key_Text));
         when Object_Identity =>
            H := H * 31
              + Ada.Strings.Hash (Text_Store.To_String (Seg.Namespace))
              + Ada.Strings.Hash (Text_Store.To_String (Seg.Token));
         when Synthetic =>
            H := H * 31
              + Ada.Containers.Hash_Type (Synthetic_Location'Pos (Seg.Location));
      end case;
      return H;
   end Seg_Hash;

   function Hash (Item : Path) return Ada.Containers.Hash_Type is
      use type Ada.Containers.Hash_Type;
      H : Ada.Containers.Hash_Type := (if Item.Absolute then 1 else 0);
   begin
      for Seg of Item.Segments loop
         H := H * 33 + Seg_Hash (Seg);
      end loop;
      return H;
   end Hash;

   ---------------------------------------------------------------------------
   --  Rendering
   ---------------------------------------------------------------------------

   function Trim_Number (S : String) return String is
     (if S'Length > 0 and then S (S'First) = ' '
      then S (S'First + 1 .. S'Last) else S);

   function Hex8 (H : Ada.Containers.Hash_Type) return String is
      use type Ada.Containers.Hash_Type;
      Digits_Set : constant String := "0123456789abcdef";
      Value      : Ada.Containers.Hash_Type := H;
      Result     : String (1 .. 8) := [others => '0'];
   begin
      for I in reverse Result'Range loop
         Result (I) := Digits_Set (Natural (Value mod 16) + 1);
         Value := Value / 16;
      end loop;
      return Result;
   end Hex8;

   function Render_Sensitive
     (Text : String; Policy : Disclosure_Policy) return String is
   begin
      case Policy is
         when Include =>
            return Text;
         when Redact =>
            return "REDACTED";
         when Opaque_Hash =>
            return "#" & Hex8 (Ada.Strings.Hash (Text));
         when Omit_Value =>
            return "?";
      end case;
   end Render_Sensitive;

   function Synthetic_Name (Location : Synthetic_Location) return String is
     (case Location is
         when Key_Location        => "key",
         when Value_Location      => "value",
         when Summary_Location    => "summary",
         when Transition_Location => "transition",
         when Source_Location     => "source");

   function Render (Item : Path) return String is
      use Ada.Strings.Unbounded;
      Buffer : Unbounded_String :=
        (if Item.Absolute then To_Unbounded_String ("$")
         else Null_Unbounded_String);
   begin
      for Seg of Item.Segments loop
         case Seg.Kind is
            when Field =>
               if Length (Buffer) > 0 then
                  Append (Buffer, ".");
               end if;
               Append (Buffer, Field_Ids.Image (Seg.Field_Ref));
            when Index =>
               Append (Buffer,
                       "[" & Trim_Number (Index_Value'Image (Seg.Index_Ref))
                       & "]");
            when Key =>
               declare
                  Rendered : constant String :=
                    Render_Sensitive
                      (Text_Store.To_String (Seg.Key_Text),
                       Seg.Key_Disclosure);
               begin
                  if Seg.Key_Disclosure = Include then
                     Append (Buffer, "[""" & Rendered & """]");
                  else
                     Append (Buffer, "[" & Rendered & "]");
                  end if;
               end;
            when Object_Identity =>
               declare
                  NS   : constant String := Text_Store.To_String (Seg.Namespace);
                  Tok  : constant String := Text_Store.To_String (Seg.Token);
                  Body_Text : constant String :=
                    (if NS'Length = 0 then Tok else NS & ":" & Tok);
               begin
                  Append (Buffer,
                          "<"
                          & Render_Sensitive (Body_Text, Seg.Ident_Disclosure)
                          & ">");
               end;
            when Synthetic =>
               Append (Buffer, "{" & Synthetic_Name (Seg.Location) & "}");
         end case;
      end loop;
      return To_String (Buffer);
   end Render;

end Validation.Paths;
