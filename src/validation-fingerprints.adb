package body Validation.Fingerprints is

   FNV_Prime : constant Word := 16#100000001b3#;

   procedure Mix_Byte (State : in out Word; B : Word) is
   begin
      State := State xor (B and 16#FF#);
      State := State * FNV_Prime;
   end Mix_Byte;

   procedure Mix_Word (State : in out Word; Value : Word) is
      Remaining : Word := Value;
   begin
      for Ignore in 1 .. 8 loop
         Mix_Byte (State, Remaining and 16#FF#);
         Remaining := Remaining / 256;
      end loop;
   end Mix_Word;

   procedure Mix_Length (State : in out Word; Length : Natural) is
   begin
      Mix_Word (State, Word (Length));
   end Mix_Length;

   function Start return Builder is (State => 16#cbf29ce484222325#);

   procedure Add_String (Item : in out Builder; Text : String) is
   begin
      Mix_Length (Item.State, Text'Length);
      for C of Text loop
         Mix_Byte (Item.State, Word (Character'Pos (C)));
      end loop;
   end Add_String;

   procedure Add_Natural (Item : in out Builder; Value : Natural) is
   begin
      Mix_Byte (Item.State, 16#01#);  --  type tag for a number
      Mix_Word (Item.State, Word (Value));
   end Add_Natural;

   procedure Add_Boolean (Item : in out Builder; Value : Boolean) is
   begin
      Mix_Byte (Item.State, 16#02#);
      Mix_Byte (Item.State, (if Value then 1 else 0));
   end Add_Boolean;

   procedure Add_Fingerprint (Item : in out Builder; Value : Fingerprint) is
   begin
      Mix_Byte (Item.State, 16#03#);
      Mix_Word (Item.State, Value.Value);
   end Add_Fingerprint;

   procedure Add_Tag (Item : in out Builder; Tag : String) is
   begin
      Mix_Byte (Item.State, 16#04#);
      Add_String (Item, Tag);
   end Add_Tag;

   function Finish (Item : Builder) return Fingerprint is
     (Value => Item.State);

   function Of_String (Text : String) return Fingerprint is
      B : Builder := Start;
   begin
      Add_String (B, Text);
      return Finish (B);
   end Of_String;

   function Image (Item : Fingerprint) return String is
      Digits_Set : constant String := "0123456789abcdef";
      Value      : Word := Item.Value;
      Result     : String (1 .. 16) := [others => '0'];
   begin
      for I in reverse Result'Range loop
         Result (I) := Digits_Set (Natural (Value mod 16) + 1);
         Value := Value / 16;
      end loop;
      return Result;
   end Image;

   function "=" (Left, Right : Fingerprint) return Boolean is
     (Left.Value = Right.Value);

   function "<" (Left, Right : Fingerprint) return Boolean is
     (Left.Value < Right.Value);

   function Hash (Item : Fingerprint) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type (Item.Value mod 2 ** 32));

end Validation.Fingerprints;
