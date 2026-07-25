------------------------------------------------------------------------------
--  Validation.Statistics
--
--  Semantic execution counters (§58). These are DETERMINISTIC for identical
--  semantic inputs and may be compared. They are distinct from diagnostic
--  performance metrics (elapsed time, allocations) which are non-semantic and
--  excluded from result equality, fingerprints, and snapshots.
------------------------------------------------------------------------------

package Validation.Statistics
  with Pure
is

   type Counters is record
      Rules_Visited          : Natural := 0;
      Rules_Executed         : Natural := 0;
      Rules_Skipped          : Natural := 0;
      Rules_Faulted          : Natural := 0;
      Objects_Visited        : Natural := 0;
      Collections_Visited    : Natural := 0;
      Elements_Visited       : Natural := 0;
      Elements_Skipped       : Natural := 0;
      Deferred_Rules_Visited : Natural := 0;
      Requests_Produced      : Natural := 0;
      Requests_Deduplicated  : Natural := 0;
      Batches_Produced       : Natural := 0;
      Batch_Entries          : Natural := 0;
      Results_Consumed       : Natural := 0;
      Continuation_Rounds    : Natural := 0;
      Maximum_Depth_Reached  : Natural := 0;
   end record;

   Zero : constant Counters := (others => 0);

end Validation.Statistics;
