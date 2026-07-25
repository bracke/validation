# Quickstart

The complete, runnable version of this is
[`examples/src/quickstart.adb`](../examples/src/quickstart.adb)
(`cd examples && alr build && ./bin/quickstart`).

## 1. Define the subject

```ada
type Customer is record
   Email : Unbounded_String;
   Age   : Integer;
end record;

function Get_Email (Subject : Customer) return String is (To_String (Subject.Email));
function Get_Age   (Subject : Customer) return Integer is (Subject.Age);
```

## 2. Instantiate the engine and standard validators

```ada
package CV is new Validation.Validators (Customer);
package Email_Text is new Validation.Standard.Text (Customer, CV, Get_Email);
package Age_Num is new Validation.Standard.Numerics (Customer, CV, Integer, Get_Age);
```

## 3. Build and finalize a validator

```ada
B : CV.Builder := CV.Start (Ids.Validator_Ids.Make ("customer"));
...
CV.Add (B, Email_Text.Non_Empty (F_Email, Ids.Rule_Ids.Make ("email/required")));
CV.Add (B, Age_Num.In_Range   (F_Age, 0, 130, Ids.Rule_Ids.Make ("age/range")));
Validator : constant CV.Validator := CV.Get_Validator (CV.Finalize (B));
```

`Finalize` returns a structured outcome; it rejects a duplicate rule id or an
empty validator id as a *definition error* (never an exception).

## 4. Validate

```ada
Result : constant Res.Result := CV.Validate (Subject, Validator, Context);
```

`Context` is a finalized `Validation.Contexts.Context` (use an empty one —
`Ctx.Freeze (Ctx.New_Builder)` — when no capabilities are needed).

## 5. Inspect and project

```ada
if Res.Has_Errors (Result) then ... end if;

for Compact of Proj.Canonical_Order
  (Res.Issues_From_Validator (Result, CV.Id (Validator)))
loop
   Put_Line (Proj.Render (Compact));
end loop;
```

Running the example prints:

```
valid customer:
  validity : VALID
  issues   : 0

invalid customer:
  validity : INVALID
  issues   : 2
    - ERROR $.age validation.range
    - ERROR $.email validation.not_empty
```

## Next steps

- **Nested objects / collections / recursion** — `Validation.Nested`,
  `Validation.Collections`, `Validation.Recursive`.
- **Profiles, conditions, prerequisites** — `In_Group`, `Requires`,
  `Conditional`, and `Execution_Options.Profiles`.
- **Deferred (externally executed) checks** — `Validation.Deferred`.
- **The rule model and everything above** — see
  [`ARCHITECTURE.md`](ARCHITECTURE.md) and the standard-validator
  [`VALIDATOR_CATALOG.md`](VALIDATOR_CATALOG.md).
