# immut API

`Luna-Flow/luna-poly/immut` is the facade of the immutable polynomial layer. It defines nothing of its own: it re-exports the shared [`core`](core.md) vocabulary, the common algebra traits of `Luna-Flow/luna-generic`, and the four immutable representations, so one import gives access to the whole value-oriented API.

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

Every name below is a `pub using` alias: `@immut.DensePolynomial` *is* `@immut/dense.DensePolynomial`, and `@immut.ExponentVector` *is* `@core.ExponentVector`. Methods are documented on the page of the package that defines the type.

## Polynomial types

### `DensePolynomial`

Immutable dense univariate polynomial. See the [immut/dense API](immut/dense.md).

```mbti
pub using @dense {type DensePolynomial}
```

### `TermPolynomial`

Immutable multivariate polynomial as a sorted term array. See the [immut/term API](immut/term.md).

```mbti
pub using @term {type TermPolynomial}
```

### `SparsePolynomial`

Immutable multivariate polynomial as an ordered map. See the [immut/sparse API](immut/sparse.md).

```mbti
pub using @sparse {type SparsePolynomial}
```

### `ContextPolynomial`, `ContextSubstitutionValue`

Immutable polynomial over a named-variable context, and the payload of its substitutions. See the [immut/context API](immut/context.md).

```mbti
pub using @context {type ContextPolynomial}
pub using @context {type ContextSubstitutionValue}
```

The alias re-exports the type, not its constructors as standalone values: write `Scalar(v)` and `Polynomial(p)` where the expected type is known, or `@immut.ContextSubstitutionValue::Polynomial(p)` in full.

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

`Clearable`, `Copyable` and `MutablePolynomial` are re-exported here as well so that both facades export the same trait set, although no immutable type implements them.

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
fn[A : @immut.Ring + Eq] cube_at(p : @immut.DensePolynomial[A], a : A) -> A {
  p.pow(3).eval(a)
}

test "one import" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  inspect(cube_at(p, 1), content="8")
  let v : @immut.ExponentVector = @immut.ExponentVector::from_array([1U])
  let s = @immut.SparsePolynomial::from_terms([(v, 2)])
  inspect(@immut.HasTermCount::term_count(s), content="1")
}
```
