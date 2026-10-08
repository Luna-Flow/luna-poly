# mutable API

## Purpose

`Luna-Flow/luna-poly/mutable` is the facade of the mutable polynomial layer. It defines nothing of its own: it re-exports the shared [`core`](core.md) vocabulary, the common algebra traits of `Luna-Flow/luna-generic`, and the four mutable representations, so one import gives access to the whole execution-oriented API. It exports the same names as the [`immut`](immut.md) facade.

Every name below is a `pub using` alias: `@mutable.DensePolynomial` *is* `@mutable/dense.DensePolynomial`, and `@mutable.ExponentVector` *is* `@core.ExponentVector`, the same type as `@immut.ExponentVector`. Methods are documented on the page of the package that defines the type.

## Importing

Add the facade to your `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/mutable",
}
```

It is the import every other `mutable` page assumes.

## Polynomial types

### `DensePolynomial`

Mutable dense univariate polynomial. See the [mutable/dense API](mutable/dense.md).

```mbti
pub using @dense {type DensePolynomial}
```

### `TermPolynomial`

Mutable multivariate polynomial as a sorted term array. See the [mutable/term API](mutable/term.md).

```mbti
pub using @term {type TermPolynomial}
```

### `SparsePolynomial`

Mutable multivariate polynomial as an ordered map. See the [mutable/sparse API](mutable/sparse.md).

```mbti
pub using @sparse {type SparsePolynomial}
```

### `ContextPolynomial`, `ContextSubstitutionValue`

Mutable polynomial over a named-variable context, and the payload of its substitutions. See the [mutable/context API](mutable/context.md).

```mbti
pub using @context {type ContextPolynomial}
pub using @context {type ContextSubstitutionValue}
```

The alias re-exports the type, not its constructors as standalone values: write `Scalar(v)` and `Polynomial(p)` where the expected type is known, or `@mutable.ContextSubstitutionValue::Polynomial(p)` in full.

## Shared vocabulary from `core`

### `ExponentVector`, `Variable`, `VariableContext`, `PolynomialShape`

Monomials, named variables, variable contexts and shape metadata. See the [core API](core.md).

```mbti
pub using @core {type ExponentVector}
pub using @core {type Variable}
pub using @core {type VariableContext}
pub using @core {type PolynomialShape}
```

### `UnivariateOps`, `MultivariateOps`, `ContextOps`

Operation records for dictionary-passing generic code. See the [core API](core.md#operation-records).

```mbti
pub using @core {type UnivariateOps}
pub using @core {type MultivariateOps}
pub using @core {type ContextOps}
```

### Capability traits

The observation traits and their bundles. See the [core API](core.md#capability-traits).

```mbti
pub using @core {trait HasLength}
pub using @core {trait HasDegree}
pub using @core {trait IsZero}
pub using @core {trait HasTermCount}
pub using @core {trait HasArity}
pub using @core {trait HasTotalDegree}
pub using @core {trait HasContext}
pub using @core {trait HasShape}
pub using @core {trait Clearable}
pub using @core {trait Copyable}
pub using @core {trait UnivariatePolynomial}
pub using @core {trait MultivariatePolynomial}
pub using @core {trait ContextualPolynomial}
pub using @core {trait MutablePolynomial}
```

Every mutable container implements `Clearable`, `Copyable` and `MutablePolynomial`, in addition to the observation bundle of its family.

## Algebra traits from `luna-generic`

### `Zero`, `One`, `AddMonoid`, `MulMonoid`, `AddGroup`, `MulGroup`, `Semiring`, `Ring`, `Field`, `Num`

The algebraic capability traits of [`Luna-Flow/luna-generic`](https://lunaflow.cn/en/luna-generic/), re-exported so that coefficient bounds can be written without a second import.

```mbti
pub using @luna-generic {trait Zero}
pub using @luna-generic {trait One}
pub using @luna-generic {trait AddMonoid}
pub using @luna-generic {trait MulMonoid}
pub using @luna-generic {trait AddGroup}
pub using @luna-generic {trait MulGroup}
pub using @luna-generic {trait Semiring}
pub using @luna-generic {trait Ring}
pub using @luna-generic {trait Field}
pub using @luna-generic {trait Num}
```

```moonbit
fn[P : @mutable.MutablePolynomial + @mutable.IsZero] reset(p : P) -> Bool {
  @mutable.Clearable::clear(p)
  @mutable.IsZero::is_zero(p)
}

test "one import" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 1])
  inspect(reset(p), content="true")
  let s = @mutable.SparsePolynomial::from_array([([1U], 2)])
  inspect(reset(s), content="true")
}
```
