with Ada.Containers;

------------------------------------------------------------------------------
--  Validation.Fingerprints
--
--  Deterministic semantic-compatibility fingerprints (§45). A fingerprint
--  summarises the SEMANTIC content of a definition (validator, context,
--  profile, ...) so compatibility can be compared cheaply. It is NOT a
--  cryptographic signature and carries no security guarantee.
--
--  Algorithm: FNV-1a over a 64-bit accumulator. Each contribution is
--  length-prefixed so that (a, bc) and (ab, c) do not collide. Contributions
--  must be SEMANTIC only — never memory addresses, callback pointers,
--  elaboration/allocation order, or non-semantic text (§45).
--
--  Format: 16 lowercase hex digits.
------------------------------------------------------------------------------

package Validation.Fingerprints is

   type Fingerprint is private;

   type Builder is private;

   function Start return Builder;

   procedure Add_String (Item : in out Builder; Text : String);
   procedure Add_Natural (Item : in out Builder; Value : Natural);
   procedure Add_Boolean (Item : in out Builder; Value : Boolean);
   procedure Add_Fingerprint (Item : in out Builder; Value : Fingerprint);

   --  Mix in a discriminator so two structurally similar sequences with
   --  different meaning cannot collide (e.g. tag each field with its role).
   procedure Add_Tag (Item : in out Builder; Tag : String);

   function Finish (Item : Builder) return Fingerprint;

   function Of_String (Text : String) return Fingerprint;

   function Image (Item : Fingerprint) return String;

   function "=" (Left, Right : Fingerprint) return Boolean;
   function "<" (Left, Right : Fingerprint) return Boolean;
   function Hash (Item : Fingerprint) return Ada.Containers.Hash_Type;

private

   type Word is mod 2 ** 64;

   type Fingerprint is record
      Value : Word := 16#cbf29ce484222325#;  --  FNV offset basis
   end record;

   type Builder is record
      State : Word := 16#cbf29ce484222325#;
   end record;

end Validation.Fingerprints;
