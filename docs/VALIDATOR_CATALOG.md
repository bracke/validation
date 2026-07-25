# Standard Validator Catalog

All standard validators are implemented through the public rule abstractions
(`Validators.Parameterized_Rules`) and produce a `Val.Rule` for a specific
`Validation.Validators` instance. Each constructor takes a `Field`, a `Rule_Id`,
and optional `Message` / `Level` / `Category` / `Phase`. By default the ACTUAL
field value is excluded from issue arguments — only the configured bound is
disclosed (§42).

## Text — `Validation.Standard.Text` (over a `String` accessor)

| Constructor | Fails when | Default message |
|---|---|---|
| `Min_Length (Field, Min, ...)` | element count < Min | `validation.length.minimum` |
| `Max_Length (Field, Max, ...)` | element count > Max | `validation.length.maximum` |
| `Exact_Length (Field, Length, ...)` | element count /= Length | `validation.length.exact` |
| `Non_Empty (Field, ...)` | length = 0 | `validation.not_empty` |
| `Non_Blank (Field, ...)` | empty or only whitespace | `validation.not_blank` |
| `Valid_UTF8 (Field, ...)` | not well-formed UTF-8 | `validation.text.invalid_utf8` |

Length checks use the Ada `String` element (byte) count. Validate UTF-8 first
if you need a code-point count. Message args: `minimum`/`maximum`/`expected`.

## Numerics — `Validation.Standard.Numerics` (over a signed-integer accessor)

| Constructor | Fails when | Default message |
|---|---|---|
| `Minimum (Field, Min, ...)` | value < Min | `validation.minimum` |
| `Maximum (Field, Max, ...)` | value > Max | `validation.maximum` |
| `In_Range (Field, Low, High, ...)` | value < Low or > High | `validation.range` |
| `Positive_Value (Field, ...)` | value <= 0 | `validation.number.positive` |
| `Non_Negative (Field, ...)` | value < 0 | `validation.number.non_negative` |
| `Non_Zero (Field, ...)` | value = 0 | `validation.number.non_zero` |

## UTF-8 — `Validation.Standard.UTF_8`

- `Is_Valid (String) return Boolean` — rejects overlong, surrogate,
  out-of-range, truncated, and stray-continuation sequences.
- `Scalar_Count (String) return Natural` (Pre: `Is_Valid`) — code-point count.

## Collections — `Validation.Collections` (over a `Count`/`Item` adapter)

- Cardinality: `Min_Count`, `Max_Count`, `Exact_Count`.
- `Each_Element (Check)` — one issue per failing element at `field[i]`.
- `Unique (Key_Type, Key_Of, Key_Equal)` — one issue per duplicate after the
  first, at the duplicate's path with a related path to the first occurrence.
- `Quantifier (Check)` — `At_Least`, `At_Most`, `Exactly`.
- `Aggregate (Project)` — `Sum_At_Most`, `Sum_Equals`.

## Structure

- `Validation.Nested` — `Rule` (nested record) and `Optional.Rule` (present /
  absent required / absent optional).
- `Validation.Recursive` — `Validate_Tree` with cycle detection and depth/visit
  limits.
- `Validation.Deferred` — externally executed checks with replay.

## Rule modifiers (on any `Val.Rule`)

- `In_Group (Rule, Group)` — group membership for profile selection.
- `Requires (Rule, Passed_Rule_Id)` — run only if an earlier rule passed.
- `Conditional (Condition).When_Applicable / .Unless_Applicable` — apply
  conditionally.

## Composition

- `Extend (Base, Id)` — a builder pre-loaded with a validator's rules.
- `Disable (Builder, Rule_Id)` — remove a rule by id.
