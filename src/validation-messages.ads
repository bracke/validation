private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Values;

------------------------------------------------------------------------------
--  Validation.Messages
--
--  Stable message identifiers plus ordered typed arguments (§10). Rules NEVER
--  render text; they return a Message_Id and an ordered set of named typed
--  Values. Localization is an external concern (VAL-INV-023/024). Duplicate
--  argument names are rejected by default. Argument order is deterministic
--  (insertion order) and is part of the message's meaning.
--
--  Standard message ids and argument names are provided as constants;
--  applications may override any message id when configuring a rule.
------------------------------------------------------------------------------

package Validation.Messages is

   type Message is private;

   type Message_Builder is private;

   function Begin_Message
     (Id : Identifiers.Message_Id) return Message_Builder;

   --  Appends (Name => Value). Added is False (and nothing is appended) when an
   --  argument with the same name already exists.
   procedure Add_Argument
     (Builder : in out Message_Builder;
      Name    : Identifiers.Argument_Name;
      Value   : Values.Value;
      Added   : out Boolean);

   function To_Message (Builder : Message_Builder) return Message;

   --  Convenience: a message with no arguments.
   function Make (Id : Identifiers.Message_Id) return Message;

   function Id_Of (Item : Message) return Identifiers.Message_Id;
   function Argument_Count (Item : Message) return Natural;

   function Name_At
     (Item : Message; Position : Positive) return Identifiers.Argument_Name
     with Pre => Position <= Argument_Count (Item);
   function Value_At (Item : Message; Position : Positive) return Values.Value
     with Pre => Position <= Argument_Count (Item);

   function Has_Argument
     (Item : Message; Name : Identifiers.Argument_Name) return Boolean;

   function "=" (Left, Right : Message) return Boolean;

   ---------------------------------------------------------------------------
   --  Standard message ids (§10). Applications may override any of these.
   ---------------------------------------------------------------------------

   package MID renames Identifiers.Message_Ids;

   Required           : constant Identifiers.Message_Id := MID.Make ("validation.required");
   Not_Blank          : constant Identifiers.Message_Id := MID.Make ("validation.not_blank");
   Equal              : constant Identifiers.Message_Id := MID.Make ("validation.equal");
   Not_Equal          : constant Identifiers.Message_Id := MID.Make ("validation.not_equal");
   Minimum            : constant Identifiers.Message_Id := MID.Make ("validation.minimum");
   Maximum            : constant Identifiers.Message_Id := MID.Make ("validation.maximum");
   Out_Of_Range       : constant Identifiers.Message_Id := MID.Make ("validation.range");
   Length_Minimum     : constant Identifiers.Message_Id := MID.Make ("validation.length.minimum");
   Length_Maximum     : constant Identifiers.Message_Id := MID.Make ("validation.length.maximum");
   Length_Exact       : constant Identifiers.Message_Id := MID.Make ("validation.length.exact");
   Invalid_UTF8       : constant Identifiers.Message_Id := MID.Make ("validation.text.invalid_utf8");
   Value_Allowed      : constant Identifiers.Message_Id := MID.Make ("validation.value.allowed");
   Value_Forbidden    : constant Identifiers.Message_Id := MID.Make ("validation.value.forbidden");
   Fields_Match       : constant Identifiers.Message_Id := MID.Make ("validation.fields.match");
   Fields_Conflict    : constant Identifiers.Message_Id := MID.Make ("validation.fields.conflict");
   Collection_Minimum : constant Identifiers.Message_Id := MID.Make ("validation.collection.minimum_count");
   Collection_Maximum : constant Identifiers.Message_Id := MID.Make ("validation.collection.maximum_count");
   Collection_Duplicate : constant Identifiers.Message_Id := MID.Make ("validation.collection.duplicate");
   Graph_Cycle        : constant Identifiers.Message_Id := MID.Make ("validation.graph.cycle");

   ---------------------------------------------------------------------------
   --  Standard argument names (§10).
   ---------------------------------------------------------------------------

   package ANM renames Identifiers.Argument_Names;

   Arg_Minimum        : constant Identifiers.Argument_Name := ANM.Make ("minimum");
   Arg_Maximum        : constant Identifiers.Argument_Name := ANM.Make ("maximum");
   Arg_Expected       : constant Identifiers.Argument_Name := ANM.Make ("expected");
   Arg_Actual         : constant Identifiers.Argument_Name := ANM.Make ("actual");
   Arg_Count          : constant Identifiers.Argument_Name := ANM.Make ("count");
   Arg_Path           : constant Identifiers.Argument_Name := ANM.Make ("path");
   Arg_Previous_Path  : constant Identifiers.Argument_Name := ANM.Make ("previous_path");
   Arg_Duplicate_Count : constant Identifiers.Argument_Name := ANM.Make ("duplicate_count");
   Arg_Allowed_Values : constant Identifiers.Argument_Name := ANM.Make ("allowed_values");

private

   type Argument is record
      Name  : Identifiers.Argument_Name;
      Value : Values.Value;
   end record;

   package Argument_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Argument);

   type Message is record
      Id        : Identifiers.Message_Id;
      Arguments : Argument_Vectors.Vector;
   end record;

   type Message_Builder is record
      Id        : Identifiers.Message_Id;
      Arguments : Argument_Vectors.Vector;
   end record;

end Validation.Messages;
