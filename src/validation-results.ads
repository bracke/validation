private with Ada.Containers.Vectors;
with Validation.Identifiers;
with Validation.Paths;
with Validation.Issues;
with Validation.Errors;
with Validation.Statistics;
with Validation.Fingerprints;

------------------------------------------------------------------------------
--  Validation.Results
--
--  The immutable execution result (§15, §16, §57). Exactly two top-level
--  dimensions:
--
--    Execution_Status  — Completed / Pending / Stopped / Incomplete /
--                        Invocation_Failed / Cancelled.
--    Semantic_Validity — Valid / Valid_With_Nonerrors / Invalid / Undetermined,
--                        DERIVED from the status and the issues (never set
--                        independently, so the two dimensions can't disagree).
--
--  Invocation errors are carried separately from the ordinary issue collection
--  (VAL-INV-025). Limit exhaustion is explicit controlled incompleteness
--  (VAL-INV-016). Coverage records whether the result is a subset (a subset
--  result never claims complete global validity).
------------------------------------------------------------------------------

package Validation.Results is

   type Execution_Status is
     (Completed, Pending, Stopped, Incomplete, Invocation_Failed, Cancelled);

   type Semantic_Validity is
     (Valid, Valid_With_Nonerrors, Invalid, Undetermined);

   type Coverage is
     (Complete_Definition, Selected_Subset, Profile_Subset, Conditional_Subset);

   ---------------------------------------------------------------------------
   --  Stop descriptor (§27)
   ---------------------------------------------------------------------------

   type Stop_Scope is
     (No_Stop, First_Error, First_Issue, Exact_Path, Subtree, Per_Object);

   type Stop_Descriptor is record
      Stopped  : Boolean := False;
      Scope    : Stop_Scope := No_Stop;
      Has_Path : Boolean := False;
      Path     : Paths.Path;
   end record;

   ---------------------------------------------------------------------------
   --  Incompleteness (§28)
   ---------------------------------------------------------------------------

   type Incompleteness_Reason is
     (Issue_Limit_Reached,
      Error_Limit_Reached,
      Warning_Limit_Reached,
      Depth_Limit_Reached,
      Object_Limit_Reached,
      Element_Limit_Reached,
      Deferred_Requests_Limit,
      Continuation_Round_Limit,
      Deferred_Infrastructure_Unavailable,
      Batch_Limit_Reached);

   type Incompleteness_Note is record
      Reason     : Incompleteness_Reason := Issue_Limit_Reached;
      Has_Path   : Boolean := False;
      Path       : Paths.Path;
      --  True when additional issues are KNOWN (not merely possible).
      More_Known : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   --  Result
   ---------------------------------------------------------------------------

   type Result is private;

   type Result_Builder is private;

   function Begin_Result
     (Status   : Execution_Status;
      Coverage : Results.Coverage := Complete_Definition) return Result_Builder;

   procedure Add_Issue
     (Builder : in out Result_Builder; Item : Issues.Issue);
   procedure Add_Invocation_Error
     (Builder : in out Result_Builder; Item : Errors.Error);
   procedure Add_Incompleteness
     (Builder : in out Result_Builder; Note : Incompleteness_Note);
   procedure Set_Stop
     (Builder : in out Result_Builder; Descriptor : Stop_Descriptor);
   procedure Set_Counters
     (Builder : in out Result_Builder; Counters : Statistics.Counters);
   procedure Set_Validator_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint);
   procedure Set_Context_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint);
   procedure Set_Options_Fingerprint
     (Builder : in out Result_Builder; Fingerprint : Fingerprints.Fingerprint);

   function Build (Builder : Result_Builder) return Result;

   ---------------------------------------------------------------------------
   --  Top-level dimensions and coverage
   ---------------------------------------------------------------------------

   function Status (Item : Result) return Execution_Status;
   function Validity (Item : Result) return Semantic_Validity;
   function Coverage_Of (Item : Result) return Coverage;
   function Counters (Item : Result) return Statistics.Counters;
   function Stop (Item : Result) return Stop_Descriptor;
   function Validator_Fingerprint (Item : Result) return Fingerprints.Fingerprint;

   ---------------------------------------------------------------------------
   --  Issue queries (§57)
   ---------------------------------------------------------------------------

   function Issue_Count (Item : Result) return Natural;
   function Error_Count (Item : Result) return Natural;
   function Warning_Count (Item : Result) return Natural;
   function Information_Count (Item : Result) return Natural;
   function Has_Errors (Item : Result) return Boolean;
   function Has_Warnings (Item : Result) return Boolean;
   function Has_Information (Item : Result) return Boolean;
   function Highest_Severity (Item : Result) return Issues.Severity
     with Pre => Issue_Count (Item) >= 1;
   function Has_Severity_At_Least
     (Item : Result; Level : Issues.Severity) return Boolean;

   function Issue_At (Item : Result; Position : Positive) return Issues.Issue
     with Pre => Position <= Issue_Count (Item);

   function Is_Complete (Item : Result) return Boolean;
   function Is_Pending (Item : Result) return Boolean;
   function Has_Invocation_Failure (Item : Result) return Boolean;
   function Invocation_Error_Count (Item : Result) return Natural;
   function Invocation_Error_At
     (Item : Result; Position : Positive) return Errors.Error
     with Pre => Position <= Invocation_Error_Count (Item);

   function Incompleteness_Count (Item : Result) return Natural;
   function Incompleteness_At
     (Item : Result; Position : Positive) return Incompleteness_Note
     with Pre => Position <= Incompleteness_Count (Item);

   --  Filtered collections (deterministic, execution order preserved).
   function Issues_At_Exact_Path
     (Item : Result; Path : Paths.Path) return Issues.Issue_Collection;
   function Issues_Under_Path
     (Item : Result; Path : Paths.Path) return Issues.Issue_Collection;
   function Issues_From_Rule
     (Item : Result; Rule : Identifiers.Rule_Id) return Issues.Issue_Collection;
   function Issues_From_Validator
     (Item : Result; Validator : Identifiers.Validator_Id)
      return Issues.Issue_Collection;
   function Issues_By_Category
     (Item : Result; Category : Identifiers.Issue_Category_Id)
      return Issues.Issue_Collection;

   ---------------------------------------------------------------------------
   --  Semantic fingerprint (§57) — excludes non-semantic metrics/trace.
   ---------------------------------------------------------------------------

   function Semantic_Fingerprint (Item : Result) return Fingerprints.Fingerprint;

   --  Order-INDEPENDENT canonical fingerprint of the issue set + validity: two
   --  results with the same issues in any order fingerprint equally (§57).
   function Issue_Set_Fingerprint (Item : Result) return Fingerprints.Fingerprint;

   function Same_Issue_Set (Left, Right : Result) return Boolean;

private

   package Error_Vectors is new Ada.Containers.Vectors
     (Positive, Errors.Error, Errors."=");
   package Note_Vectors is new Ada.Containers.Vectors
     (Positive, Incompleteness_Note);

   type Result is record
      Status            : Execution_Status := Completed;
      Validity          : Semantic_Validity := Valid;
      Coverage          : Results.Coverage := Complete_Definition;
      Issues            : Validation.Issues.Issue_Collection;
      Invocation_Errors : Error_Vectors.Vector;
      Incompleteness    : Note_Vectors.Vector;
      Stop              : Stop_Descriptor;
      Counters          : Statistics.Counters := Statistics.Zero;
      Validator_FP      : Fingerprints.Fingerprint;
      Context_FP        : Fingerprints.Fingerprint;
      Options_FP        : Fingerprints.Fingerprint;
   end record;

   type Result_Builder is record
      Data : Result;
   end record;

end Validation.Results;
