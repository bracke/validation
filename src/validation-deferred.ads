private with Ada.Strings.Unbounded;
private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Paths;
with Validation.Contexts;
with Validation.Results;
with Validation.Fingerprints;
with Validation.Validators;

------------------------------------------------------------------------------
--  Validation.Deferred  (generic)
--
--  Deferred validation describes external work but never executes it (§46).
--  This generic models one deferred CHECK FAMILY over a subject: the subject
--  yields zero or more typed request payloads, each targeting a path; the
--  application executes them externally and supplies typed results; Resume
--  interprets the results into issues via DETERMINISTIC REPLAY of the immediate
--  validator.
--
--  A Continuation binds the validator fingerprint, a caller-supplied subject
--  token, and the context fingerprint (§50). Resume rejects a stale or
--  incompatible continuation as an invocation error (VAL-INV-030). Result
--  arrival order never affects the outcome (VAL-INV-011); unknown and duplicate
--  results are rejected, never silently accepted (VAL-INV-012).
--
--  Scope: an in-process, single-check-family, Require_All lifecycle with a
--  synchronous adapter. The heterogeneous multi-check opaque-payload model
--  (§47), batching/splitting (§53), multi-round follow-ups (§54), deduplication,
--  and externally-serializable continuations (§48) are documented
--  generalizations of this core.
------------------------------------------------------------------------------

generic
   type Subject_Type is private;
   with package Val is new Validation.Validators (Subject_Type);
   type Request_Payload is private;
   type Result_Payload is private;
   Check_Id : String;
   with function Item_Count (Subject : Subject_Type) return Natural;
   with function Request_Of
     (Subject : Subject_Type; Index : Positive) return Request_Payload;
   with function Path_Of
     (Subject : Subject_Type; Index : Positive) return Paths.Path;
   with function Is_Valid_Result (Result : Result_Payload) return Boolean;
   Fail_Message : Identifiers.Message_Id;
package Validation.Deferred is

   type Request is record
      Occurrence : Positive;
      Payload    : Request_Payload;
      Target     : Paths.Path;
   end record;

   type Result_Entry is record
      Occurrence : Positive;
      Payload    : Result_Payload;
   end record;
   type Result_Array is array (Positive range <>) of Result_Entry;

   type Continuation is private;

   function Request_Count (Cont : Continuation) return Natural;
   function Request_At (Cont : Continuation; Index : Positive) return Request
     with Pre => Index <= Request_Count (Cont);

   --  Phase 1: run immediate rules and emit deferred requests. Outcome is
   --  Pending when there is at least one request, otherwise the immediate
   --  (Completed) result.
   procedure Start
     (Subject       : Subject_Type;
      Validator     : Val.Validator;
      Context       : Contexts.Context;
      Subject_Token : String;
      Options       : Val.Execution_Options := Val.Default_Options;
      Outcome       : out Results.Result;
      Cont          : out Continuation);

   --  Phase 2: interpret externally-produced results by deterministic replay.
   --  A binding mismatch, or an unknown/duplicate result, yields Invocation_Failed.
   --  A missing result leaves the outcome Pending (Require_All).
   function Resume
     (Cont          : Continuation;
      Subject       : Subject_Type;
      Validator     : Val.Validator;
      Context       : Contexts.Context;
      Subject_Token : String;
      Provided      : Result_Array;
      Options       : Val.Execution_Options := Val.Default_Options)
      return Results.Result;

   --  In-process synchronous adapter (§55): validate, execute every request
   --  through Handler, and resume — the whole lifecycle in one call.
   generic
      with function Handler (Payload : Request_Payload) return Result_Payload;
   package Synchronous is
      function Run
        (Subject       : Subject_Type;
         Validator     : Val.Validator;
         Context       : Contexts.Context;
         Subject_Token : String;
         Options       : Val.Execution_Options := Val.Default_Options)
         return Results.Result;
   end Synchronous;

private

   package Request_Vectors is new Ada.Containers.Vectors (Positive, Request);

   type Continuation is record
      Validator_FP : Fingerprints.Fingerprint;
      Context_FP   : Fingerprints.Fingerprint;
      Token        : Ada.Strings.Unbounded.Unbounded_String;
      Round        : Positive := 1;
      Requests     : Request_Vectors.Vector;
   end record;

end Validation.Deferred;
