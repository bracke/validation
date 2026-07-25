with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with Validation.Paths;
with Validation.Issues;
with Validation.Messages;
with Validation.Provenance;

package body Validation.Recursive is

   package Ids renames Validation.Identifiers;

   Cycle_Rule : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("graph/cycle");

   type Active_Entry is record
      Id   : Unbounded_String;
      Path : Paths.Path;
   end record;

   package Active_Vectors is new Ada.Containers.Vectors (Positive, Active_Entry);

   function Validate_Tree
     (Root       : Node_Type;
      Validator  : Node_Val.Validator;
      Context    : Validation.Contexts.Context;
      On_Cycle   : Cycle_Action := Report_Issue_And_Skip;
      Max_Depth  : Positive := 32;
      Max_Visits : Positive := 10_000) return Results.Result
   is
      Collected  : Issues.Issue_Collection := Issues.Empty_Collection;
      Active     : Active_Vectors.Vector;
      Ordinal    : Natural := 0;
      Visits     : Natural := 0;
      Failed     : Boolean := False;
      Incomplete : Boolean := False;
      Depth_Hit  : Boolean := False;

      procedure Emit_Cycle (Prefix, First_Path : Paths.Path) is
         Prov : constant Provenance.Provenance :=
           Provenance.Make_Minimal
             (Node_Val.Id (Validator), Cycle_Rule, Ordinal + 1);
         B : Issues.Issue_Builder :=
           Issues.Begin_Issue
             (Ordinal + 1, Node_Val.Id (Validator), Cycle_Rule, Issues.Error,
              Issues.Category_Graph, Prefix,
              Messages.Make (Messages.Graph_Cycle), Prov);
         Added : Boolean;
      begin
         Ordinal := Ordinal + 1;
         Issues.Add_Related_Path (B, First_Path, Added);
         Issues.Append (Collected, Issues.Build (B));
      end Emit_Cycle;

      procedure Walk (Node : Node_Type; Prefix : Paths.Path; Depth : Positive) is
         Id_Str : constant String := Identity (Node);
      begin
         if Failed then
            return;
         end if;
         Visits := Visits + 1;
         if Visits > Max_Visits then
            Incomplete := True;
            return;
         end if;

         for Entry_Item of Active loop
            if To_String (Entry_Item.Id) = Id_Str then
               case On_Cycle is
                  when Report_Issue_And_Skip =>
                     Emit_Cycle (Prefix, Entry_Item.Path);
                  when Skip_Silently =>
                     null;
                  when Invocation_Failure =>
                     Failed := True;
               end case;
               return;
            end if;
         end loop;

         if Depth > Max_Depth then
            Depth_Hit := True;
            Incomplete := True;
            return;
         end if;

         declare
            Sub : constant Results.Result :=
              Node_Val.Validate (Node, Validator, Context);
         begin
            for Index in 1 .. Results.Issue_Count (Sub) loop
               Ordinal := Ordinal + 1;
               Issues.Append
                 (Collected,
                  Issues.Rebased (Results.Issue_At (Sub, Index), Prefix, Ordinal));
            end loop;
         end;

         Active.Append (Active_Entry'(To_Unbounded_String (Id_Str), Prefix));
         for Position in 1 .. Child_Count (Node) loop
            exit when Failed;
            Walk
              (Child (Node, Position),
               Paths.Append_Index
                 (Paths.Append_Field (Prefix, Children_Field),
                  Paths.Index_Value (Position - 1)),
               Depth + 1);
         end loop;
         Active.Delete_Last;
      end Walk;

      Status : Results.Execution_Status;
   begin
      Walk (Root, Paths.Root, 1);

      Status :=
        (if Failed then Results.Invocation_Failed
         elsif Incomplete then Results.Incomplete
         else Results.Completed);

      return Result : Results.Result do
         declare
            RB : Results.Result_Builder := Results.Begin_Result (Status);
         begin
            for Index in 1 .. Issues.Count (Collected) loop
               Results.Add_Issue (RB, Issues.Element (Collected, Index));
            end loop;
            if Incomplete then
               Results.Add_Incompleteness
                 (RB,
                  (Reason =>
                     (if Depth_Hit then Results.Depth_Limit_Reached
                      else Results.Object_Limit_Reached),
                   others => <>));
            end if;
            Result := Results.Build (RB);
         end;
      end return;
   end Validate_Tree;

end Validation.Recursive;
