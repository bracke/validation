with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Validation.Issues;
with Validation.Messages;
with Validation.Errors;
with Validation.Provenance;

package body Validation.Deferred is

   package Rule_Ids renames Identifiers.Rule_Ids;
   use type Fingerprints.Fingerprint;

   Deferred_Rule : constant Identifiers.Rule_Id := Rule_Ids.Make (Check_Id);

   function Build_Requests
     (Subject : Subject_Type) return Request_Vectors.Vector
   is
      Result : Request_Vectors.Vector;
   begin
      for Index in 1 .. Item_Count (Subject) loop
         Result.Append
           (Request'(Occurrence => Index,
                     Payload    => Request_Of (Subject, Index),
                     Target     => Path_Of (Subject, Index)));
      end loop;
      return Result;
   end Build_Requests;

   function Fail_Issue
     (Validator : Val.Validator; Ordinal : Positive; Target : Paths.Path)
      return Issues.Issue
   is
      Prov : constant Provenance.Provenance :=
        Provenance.Make_Minimal (Val.Id (Validator), Deferred_Rule, Ordinal);
      B : constant Issues.Issue_Builder :=
        Issues.Begin_Issue
          (Ordinal, Val.Id (Validator), Deferred_Rule, Issues.Error,
           Issues.Category_External_Ref, Target,
           Messages.Make (Fail_Message), Prov);
   begin
      return Issues.Build (B);
   end Fail_Issue;

   function Failure (Code : Errors.Error_Code) return Results.Result is
      RB : Results.Result_Builder :=
        Results.Begin_Result (Results.Invocation_Failed);
   begin
      Results.Add_Invocation_Error (RB, Errors.Make (Code));
      return Results.Build (RB);
   end Failure;

   ---------------------------------------------------------------------------

   function Request_Count (Cont : Continuation) return Natural is
     (Natural (Cont.Requests.Length));

   function Request_At (Cont : Continuation; Index : Positive) return Request is
     (Cont.Requests (Index));

   ---------------------------------------------------------------------------

   procedure Start
     (Subject       : Subject_Type;
      Validator     : Val.Validator;
      Context       : Contexts.Context;
      Subject_Token : String;
      Options       : Val.Execution_Options := Val.Default_Options;
      Outcome       : out Results.Result;
      Cont          : out Continuation)
   is
      Immediate : constant Results.Result :=
        Val.Validate (Subject, Validator, Context, Options);
      Requests  : constant Request_Vectors.Vector := Build_Requests (Subject);
      Status    : constant Results.Execution_Status :=
        (if Requests.Is_Empty then Results.Completed else Results.Pending);
      RB : Results.Result_Builder := Results.Begin_Result (Status);
   begin
      for Index in 1 .. Results.Issue_Count (Immediate) loop
         Results.Add_Issue (RB, Results.Issue_At (Immediate, Index));
      end loop;
      Results.Set_Validator_Fingerprint (RB, Val.Fingerprint (Validator));
      Outcome := Results.Build (RB);

      Cont :=
        (Validator_FP => Val.Fingerprint (Validator),
         Context_FP   => Contexts.Fingerprint (Context),
         Token        => To_Unbounded_String (Subject_Token),
         Round        => 1,
         Requests     => Requests);
   end Start;

   ---------------------------------------------------------------------------

   function Resume
     (Cont          : Continuation;
      Subject       : Subject_Type;
      Validator     : Val.Validator;
      Context       : Contexts.Context;
      Subject_Token : String;
      Provided      : Result_Array;
      Options       : Val.Execution_Options := Val.Default_Options)
      return Results.Result
   is
      Count : constant Natural := Request_Count (Cont);
   begin
      --  Stale / incompatible continuation (VAL-INV-030).
      if Val.Fingerprint (Validator) /= Cont.Validator_FP
        or else Contexts.Fingerprint (Context) /= Cont.Context_FP
        or else Subject_Token /= To_String (Cont.Token)
      then
         return Failure (Errors.Stale_Continuation);
      end if;

      --  Reject unknown / duplicate results (VAL-INV-012).
      declare
         Seen : array (1 .. Count) of Boolean := [others => False];
      begin
         for Entry_Item of Provided loop
            if Entry_Item.Occurrence not in 1 .. Count then
               return Failure (Errors.Unknown_Deferred_Result);
            elsif Seen (Entry_Item.Occurrence) then
               return Failure (Errors.Duplicate_Deferred_Result);
            else
               Seen (Entry_Item.Occurrence) := True;
            end if;
         end loop;
      end;

      --  Deterministic replay of the immediate validator, then interpret.
      declare
         Immediate : constant Results.Result :=
           Val.Validate (Subject, Validator, Context, Options);
         Ordinal     : Natural := Results.Issue_Count (Immediate);
         Unresolved  : Boolean := False;
         Fail_Issues : Issues.Issue_Collection := Issues.Empty_Collection;
      begin
         for Index in 1 .. Count loop
            declare
               Req   : constant Request := Request_At (Cont, Index);
               Found : Boolean := False;
               Ok    : Boolean := True;
            begin
               for Entry_Item of Provided loop
                  if Entry_Item.Occurrence = Req.Occurrence then
                     Found := True;
                     Ok := Is_Valid_Result (Entry_Item.Payload);
                     exit;
                  end if;
               end loop;
               if not Found then
                  Unresolved := True;
               elsif not Ok then
                  Ordinal := Ordinal + 1;
                  Issues.Append
                    (Fail_Issues, Fail_Issue (Validator, Ordinal, Req.Target));
               end if;
            end;
         end loop;

         declare
            Status : constant Results.Execution_Status :=
              (if Unresolved then Results.Pending else Results.Completed);
            FB : Results.Result_Builder := Results.Begin_Result (Status);
         begin
            for Index in 1 .. Results.Issue_Count (Immediate) loop
               Results.Add_Issue (FB, Results.Issue_At (Immediate, Index));
            end loop;
            for Index in 1 .. Issues.Count (Fail_Issues) loop
               Results.Add_Issue (FB, Issues.Element (Fail_Issues, Index));
            end loop;
            Results.Set_Validator_Fingerprint (FB, Val.Fingerprint (Validator));
            return Results.Build (FB);
         end;
      end;
   end Resume;

   ---------------------------------------------------------------------------

   package body Synchronous is

      function Run
        (Subject       : Subject_Type;
         Validator     : Val.Validator;
         Context       : Contexts.Context;
         Subject_Token : String;
         Options       : Val.Execution_Options := Val.Default_Options)
         return Results.Result
      is
         Outcome : Results.Result;
         Cont    : Continuation;
      begin
         Start (Subject, Validator, Context, Subject_Token, Options,
                Outcome, Cont);
         declare
            Count    : constant Natural := Request_Count (Cont);
            Provided : Result_Array (1 .. Count);
         begin
            for Index in 1 .. Count loop
               declare
                  Req : constant Request := Request_At (Cont, Index);
               begin
                  Provided (Index) :=
                    (Occurrence => Req.Occurrence,
                     Payload    => Handler (Req.Payload));
               end;
            end loop;
            return Resume
              (Cont, Subject, Validator, Context, Subject_Token, Provided,
               Options);
         end;
      end Run;

   end Synchronous;

end Validation.Deferred;
