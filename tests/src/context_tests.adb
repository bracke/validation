with AUnit.Assertions;
with AUnit.Test_Caller;

with Validation.Identifiers;
with Validation.Issues;
with Validation.Errors;
with Validation.Contexts;
with Validation.Profiles;
with Validation.Fingerprints;

package body Context_Tests is

   use AUnit.Assertions;

   package Ids renames Validation.Identifiers;
   package Ctx renames Validation.Contexts;
   package Prof renames Validation.Profiles;
   package Errs renames Validation.Errors;
   package Iss renames Validation.Issues;
   package FP renames Validation.Fingerprints;

   package Caller is new AUnit.Test_Caller (Fixture);

   use type Ctx.Add_Result;
   use type Errs.Error_Code;
   use type Iss.Severity;
   use type FP.Fingerprint;

   type Tenant is record
      Code : Integer;
   end record;

   package Cap_Tenant is new Ctx.Capability (Tenant, "tenant", "tenant.v", 1);
   package Cap_Tenant_V2 is new Ctx.Capability (Tenant, "tenant", "tenant.v", 2);
   package Cap_Age is new Ctx.Capability (Integer, "proposed.age", "age.v", 1);

   --------------------------------------------------------------------------

   procedure Test_Capability_Trust (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Ctx.Builder := Ctx.New_Builder;
      R : Ctx.Add_Result;
   begin
      Cap_Tenant.Put (B, (Code => 7), Ctx.Trusted_Application_Fact, Result => R);
      Assert (R = Ctx.Added, "tenant added");
      Cap_Age.Put (B, 40, Ctx.Proposed_Untrusted_Value, Result => R);
      Assert (R = Ctx.Added, "proposed age added");
      Cap_Tenant.Put (B, (Code => 9), Ctx.Trusted_Application_Fact, Result => R);
      Assert (R = Ctx.Duplicate_Capability, "duplicate capability rejected");

      declare
         C     : constant Ctx.Context := Ctx.Freeze (B);
         Ten   : Tenant;
         Age   : Integer;
         Found : Boolean;
      begin
         Cap_Tenant.Get (C, Ctx.Trusted_Facts, Ten, Found);
         Assert (Found and then Ten.Code = 7, "trusted capability retrieved");

         --  VAL-INV-036: an untrusted proposed value cannot satisfy a request
         --  that accepts only trusted provenance.
         Cap_Age.Get (C, Ctx.Trusted_Facts, Age, Found);
         Assert (not Found, "untrusted value rejected for trusted request");
         Cap_Age.Get (C, Ctx.Any_Trust, Age, Found);
         Assert (Found and then Age = 40, "untrusted value readable with Any_Trust");

         --  Schema-version mismatch: same id, version 2 -> not present.
         Cap_Tenant_V2.Get (C, Ctx.Any_Trust, Ten, Found);
         Assert (not Found, "schema-version mismatch not found");
      end;
   end Test_Capability_Trust;

   --------------------------------------------------------------------------

   procedure Test_Context_Fingerprint (T : in out Fixture) is
      pragma Unreferenced (T);
      A, B : Ctx.Builder := Ctx.New_Builder;
      R    : Ctx.Add_Result;
   begin
      --  Same capabilities, DIFFERENT insertion order -> same fingerprint.
      Cap_Tenant.Put (A, (Code => 1), Ctx.Trusted_Application_Fact, Result => R);
      Cap_Age.Put (A, 5, Ctx.Proposed_Untrusted_Value, Result => R);

      Cap_Age.Put (B, 5, Ctx.Proposed_Untrusted_Value, Result => R);
      Cap_Tenant.Put (B, (Code => 1), Ctx.Trusted_Application_Fact, Result => R);

      Assert (Ctx.Fingerprint (Ctx.Freeze (A)) = Ctx.Fingerprint (Ctx.Freeze (B)),
              "context fingerprint is insertion-order independent");
   end Test_Context_Fingerprint;

   --------------------------------------------------------------------------

   procedure Test_Contract (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Ctx.Builder := Ctx.New_Builder;
      R : Ctx.Add_Result;
   begin
      Cap_Tenant.Put (B, (Code => 1), Ctx.Trusted_Application_Fact, Result => R);
      Cap_Age.Put (B, 5, Ctx.Proposed_Untrusted_Value, Result => R);
      declare
         C : constant Ctx.Context := Ctx.Freeze (B);

         Ok : constant Ctx.Requirement_Array :=
           [(Cap_Id => Ids.Capability_Ids.Make ("tenant"),
             Required => True, Version => 1, Accepted => Ctx.Trusted_Facts)];
         Missing : constant Ctx.Requirement_Array :=
           [(Cap_Id => Ids.Capability_Ids.Make ("locale"),
             Required => True, Version => 1, Accepted => Ctx.Trusted_Facts)];
         Bad_Version : constant Ctx.Requirement_Array :=
           [(Cap_Id => Ids.Capability_Ids.Make ("tenant"),
             Required => True, Version => 2, Accepted => Ctx.Trusted_Facts)];
         Untrusted : constant Ctx.Requirement_Array :=
           [(Cap_Id => Ids.Capability_Ids.Make ("proposed.age"),
             Required => True, Version => 1, Accepted => Ctx.Trusted_Facts)];
      begin
         Assert (Ctx.Check_Contract (C, Ok)'Length = 0, "satisfied contract");
         declare
            E : constant Ctx.Error_Array := Ctx.Check_Contract (C, Missing);
         begin
            Assert (E'Length = 1
                      and then Errs.Code_Of (E (1)) = Errs.Missing_Capability,
                    "missing capability reported");
         end;
         declare
            E : constant Ctx.Error_Array := Ctx.Check_Contract (C, Bad_Version);
         begin
            Assert (E'Length = 1
                      and then Errs.Code_Of (E (1))
                               = Errs.Unsupported_Capability_Version,
                    "version mismatch reported");
         end;
         Assert (Ctx.Check_Contract (C, Untrusted)'Length = 1,
                 "untrusted capability fails a trusted requirement");
      end;
   end Test_Contract;

   --------------------------------------------------------------------------

   G_Basic : constant Ids.Rule_Group_Id := Ids.Rule_Group_Ids.Make ("basic");
   G_Strict : constant Ids.Rule_Group_Id := Ids.Rule_Group_Ids.Make ("strict");
   R_A : constant Ids.Rule_Id := Ids.Rule_Ids.Make ("field.a/rule");

   function Draft return Prof.Profile is
      B : Prof.Profile_Builder :=
        Prof.Begin_Profile (Ids.Profile_Ids.Make ("draft"));
   begin
      Prof.Include_Group (B, G_Basic);
      Prof.Override_Severity (B, R_A, Iss.Warning);
      return Prof.Get_Profile (Prof.Finalize (B));
   end Draft;

   procedure Test_Profiles (T : in out Fixture) is
      pragma Unreferenced (T);
      D : constant Prof.Profile := Draft;

      --  Strict inherits from Draft (composition) and adds a group.
      SB : Prof.Profile_Builder :=
        Prof.Extend (D, Ids.Profile_Ids.Make ("strict"));

      --  Conflicting override on the same rule -> definition error.
      CB : Prof.Profile_Builder :=
        Prof.Begin_Profile (Ids.Profile_Ids.Make ("bad"));
   begin
      Assert (Prof.Is_Group_Active (D, G_Basic), "draft activates basic");
      Assert (not Prof.Is_Group_Active (D, G_Strict), "draft does not activate strict");
      Assert (Prof.Effective_Severity (D, R_A, Iss.Error) = Iss.Warning,
              "severity overridden");
      Assert (Prof.Effective_Severity
                (D, Ids.Rule_Ids.Make ("other/rule"), Iss.Error) = Iss.Error,
              "non-overridden rule keeps declared severity");

      Prof.Include_Group (SB, G_Strict);
      declare
         S : constant Prof.Profile := Prof.Get_Profile (Prof.Finalize (SB));
      begin
         Assert (Prof.Is_Group_Active (S, G_Basic)
                   and then Prof.Is_Group_Active (S, G_Strict),
                 "extend inherits basic and adds strict");
         Assert (Prof.Effective_Severity (S, R_A, Iss.Error) = Iss.Warning,
                 "inherited override preserved");
      end;

      Prof.Override_Severity (CB, R_A, Iss.Warning);
      Prof.Override_Severity (CB, R_A, Iss.Error);
      declare
         O : constant Prof.Finalize_Outcome := Prof.Finalize (CB);
      begin
         Assert (not Prof.Is_Success (O), "conflicting override fails finalize");
         Assert (Prof.Error_Count (O) = 1
                   and then Errs.Code_Of (Prof.Error_At (O, 1))
                            = Errs.Conflicting_Override,
                 "conflicting override reported");
      end;
   end Test_Profiles;

   procedure Test_Profile_Set (T : in out Fixture) is
      pragma Unreferenced (T);
      D : constant Prof.Profile := Draft;

      SB : Prof.Profile_Builder :=
        Prof.Begin_Profile (Ids.Profile_Ids.Make ("override"));
      Set : Prof.Profile_Set := Prof.Empty_Set;
   begin
      Prof.Override_Severity (SB, R_A, Iss.Information);
      declare
         S : constant Prof.Profile := Prof.Get_Profile (Prof.Finalize (SB));
      begin
         Set := Prof.Add (Set, D);   --  lower precedence
         Set := Prof.Add (Set, S);   --  higher precedence (later)
         Assert (Prof.Count (Set) = 2, "two active profiles");
         Assert (Prof.Is_Group_Active (Set, G_Basic), "union group activation");
         --  Later profile wins: Information overrides Draft's Warning.
         Assert (Prof.Effective_Severity (Set, R_A, Iss.Error) = Iss.Information,
                 "later profile wins on severity");
      end;
   end Test_Profile_Set;

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Context: capability trust", Test_Capability_Trust'Access));
      Suite.Add_Test
        (Caller.Create ("Context: fingerprint", Test_Context_Fingerprint'Access));
      Suite.Add_Test (Caller.Create ("Context: contract", Test_Contract'Access));
      Suite.Add_Test (Caller.Create ("Profiles: profile", Test_Profiles'Access));
      Suite.Add_Test (Caller.Create ("Profiles: profile set", Test_Profile_Set'Access));
   end Add_Tests;

end Context_Tests;
