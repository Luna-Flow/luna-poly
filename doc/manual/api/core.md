# core API

`Luna-Flow/luna-poly/core` is the shared vocabulary of the library. It owns the exponent-vector monomial type, the named-variable layer, the shape metadata, the capability traits that every concrete polynomial implements, and the operation records used for dictionary-passing generic code. It contains no polynomial storage of its own.

Both facades, [`immut`](immut.md) and [`mutable`](mutable.md), re-export every type and trait of this page, so most programs never import `core` directly. When you do, give it an alias that does not collide with `Luna-Flow/type_theory/core`:

```text
import {
  "Luna-Flow/luna-poly/core" @poly_core,
}
```

The examples on this page use that alias. The mathematics behind the items is explained in the [core design](../design/core.md).

## Monomials

### `ExponentVector`

`ExponentVector` is the exponent vector $\alpha = (\alpha_0, \alpha_1, \dots)$ of a monomial $x^\alpha = x_0^{\alpha_0} x_1^{\alpha_1} \cdots$. Trailing zero exponents are never stored, so `[1, 0]` and `[1]` are the same value, and the total degree $|\alpha| = \sum_i \alpha_i$ is cached.

```mbti
type ExponentVector derive(@debug.Debug)
pub impl @luna-generic.One for ExponentVector
pub impl Compare for ExponentVector
pub impl Eq for ExponentVector
pub impl Hash for ExponentVector
pub impl Mul for ExponentVector
pub impl Show for ExponentVector
```

The value is immutable. Every "update" returns a new vector.

### `ExponentVector::from_array`

Builds the canonical exponent vector of an array, removing trailing zeros. The array is copied.

```mbti
pub fn ExponentVector::from_array(Array[UInt]) -> Self
```

### `ExponentVector::one`

Returns the empty exponent vector, the monomial $1 = x^{0}$. It is also `One::one()` for `ExponentVector`.

```mbti
pub fn ExponentVector::one() -> Self
```

### `ExponentVector::length`

Returns the stored length: one more than the index of the last non-zero exponent, and `0` for the unit.

```mbti
pub fn ExponentVector::length(Self) -> Int
```

### `ExponentVector::degree`

Returns the total degree $|\alpha| = \sum_i \alpha_i$ in $O(1)$.

```mbti
pub fn ExponentVector::degree(Self) -> UInt
```

The degree is a `UInt` sum and wraps modulo $2^{32}$ if the exponents are that large.

### `ExponentVector::is_one`

Returns `true` exactly for the unit vector (every exponent zero).

```mbti
pub fn ExponentVector::is_one(Self) -> Bool
```

### `ExponentVector::get`

Returns the exponent of variable `index`; it also serves `v[index]`. An index at or beyond `length()` reads as `0`. A negative index aborts.

```mbti
#alias("_[_]")
pub fn ExponentVector::get(Self, Int) -> UInt
```

### `ExponentVector::get_checked`

Returns `Some(exponent)` like `get`, and `None` for a negative index.

```mbti
pub fn ExponentVector::get_checked(Self, Int) -> UInt?
```

### `ExponentVector::with_exponent`

Returns a new vector with the exponent of `index` replaced by `value`, canonicalized again (setting the last non-zero exponent to `0` shortens the vector). A negative index aborts.

```mbti
pub fn ExponentVector::with_exponent(Self, Int, UInt) -> Self
```

### `ExponentVector::with_exponent_checked`

Returns `None` for a negative index and `Some` of the `with_exponent` result otherwise.

```mbti
pub fn ExponentVector::with_exponent_checked(Self, Int, UInt) -> Self?
```

### `ExponentVector::to_array`

Returns a fresh copy of the canonical exponents, without trailing zeros.

```mbti
pub fn ExponentVector::to_array(Self) -> Array[UInt]
```

### `ExponentVector::mul`

Multiplies two monomials by adding exponents pointwise: $x^\alpha x^\beta = x^{\alpha+\beta}$. It is also the `*` operator.

```mbti
pub fn ExponentVector::mul(Self, Self) -> Self
```

Exponent addition is `UInt` addition and wraps modulo $2^{32}$.

### `ExponentVector::compare`

Compares two monomials in the library's monomial order: first by total degree, then by the exponent of the highest-indexed variable where they differ, the larger exponent being the larger monomial. This is the graded lexicographic order with $x_0 < x_1 < x_2 < \cdots$. It also drives `<`, `<=`, `>` and `>=`.

```mbti
pub fn ExponentVector::compare(Self, Self) -> Int
```

The order is total, has $1$ as its least element, and is compatible with multiplication: $\alpha < \beta$ implies $\alpha + \gamma < \beta + \gamma$. The [core design](../design/core.md#the-monomial-order) derives these properties.

### `ExponentVector::equal`, `ExponentVector::hash`

`equal` is structural equality of canonical vectors (it is `==`); `hash` is consistent with it.

```mbti
pub fn ExponentVector::equal(Self, Self) -> Bool
pub fn ExponentVector::hash(Self) -> Int
```

### `ExponentVector::to_string`

Renders the monomial with `x` for variable `0` and `x_i` for variable `i`, and `1` for the unit. Factors are written next to each other without a separator.

```mbti
pub fn ExponentVector::to_string(Self) -> String
```

```moonbit
test "exponent vectors" {
  let a = @poly_core.ExponentVector::from_array([2U, 0, 1, 0])
  debug_inspect(a.to_array(), content="[2, 0, 1]")
  inspect(a.degree(), content="3")
  inspect(a[1], content="0")
  inspect(a[7], content="0")
  inspect(a, content="x^2x_2")
  let b = @poly_core.ExponentVector::from_array([0U, 1])
  inspect(a * b, content="x^2x_1x_2")
  assert_true(a.get_checked(-1) is None)
  assert_true(a.with_exponent(2, 0) == @poly_core.ExponentVector::from_array([2U]))
  // Same degree: the higher variable decides, so x_1 > x_0.
  let x0 = @poly_core.ExponentVector::from_array([1U])
  let x1 = @poly_core.ExponentVector::from_array([0U, 1])
  assert_true(x0 < x1)
  assert_true(x1 < x0 * x0)
}
```

## Named variables

### `Variable`

`Variable` is a named variable together with its position in the [`VariableContext`](#variablecontext) that created it. Two variables are equal when both the name and the index agree.

```mbti
type Variable derive(Compare, Eq, @debug.Debug)
pub impl Show for Variable
```

You obtain variables from a context; there is no public constructor.

### `Variable::name`, `Variable::index`

`name` returns the variable's name; `index` returns its context-local position, which is also the position of its exponent in an `ExponentVector`.

```mbti
pub fn Variable::name(Self) -> String
pub fn Variable::index(Self) -> Int
```

### `Variable::to_type_theory_name`

Returns the variable's name as a `Luna-Flow/type_theory` `Name`. The index is not part of the result; it is recovered by looking the name up in a context with [`VariableContext::variable_by_type_theory_name`](#variablecontextvariable_by_type_theory_name).

```mbti
pub fn Variable::to_type_theory_name(Self) -> @Luna-Flow/type_theory/core.Name
```

### `Variable::compare`, `Variable::equal`, `Variable::to_string`

`compare` orders variables by name, then index (derived); `equal` compares name and index; `to_string` returns the name.

```mbti
pub fn Variable::compare(Self, Self) -> Int
pub fn Variable::equal(Self, Self) -> Bool
pub fn Variable::to_string(Self) -> String
```

### `VariableContext`

`VariableContext` is an ordered, persistent table of distinct variable names. The variable at position $i$ has index $i$, and the names are unique, so names and indexes determine each other inside one context.

```mbti
type VariableContext derive(Eq, @debug.Debug)
pub impl Show for VariableContext
```

Contexts are compared structurally: two contexts with the same names in the same order are equal, wherever they were built.

### `VariableContext::new`

Returns the empty context.

```mbti
pub fn VariableContext::new() -> Self
```

### `VariableContext::from_names`

Builds a context whose variables are `names` in order. It aborts on a duplicate name.

```mbti
pub fn VariableContext::from_names(Array[String]) -> Self
```

### `VariableContext::from_names_checked`

Like `from_names`, but returns `None` when a name occurs twice.

```mbti
pub fn VariableContext::from_names_checked(Array[String]) -> Self?
```

### `VariableContext::extend_checked`

Returns a new context with `name` appended, together with the new variable, or `None` when the name is already present. The receiver is unchanged.

```mbti
pub fn VariableContext::extend_checked(Self, String) -> (Self, Variable)?
```

### `VariableContext::extend_with`

Like `extend_checked`, but aborts on a duplicate name.

```mbti
#alias(extend, deprecated)
pub fn VariableContext::extend_with(Self, String) -> (Self, Variable)
```

The old name `extend` is kept as a deprecated alias; see [Deprecated](#deprecated).

### `VariableContext::size`, `VariableContext::variables`, `VariableContext::get`

`size` returns the number of variables; `variables` returns them in index order as a fresh array; `get` returns the variable at an index, or `None` outside `0 ..< size()`.

```mbti
pub fn VariableContext::size(Self) -> Int
pub fn VariableContext::variables(Self) -> Array[Variable]
pub fn VariableContext::get(Self, Int) -> Variable?
```

### `VariableContext::variable`, `VariableContext::require_variable`

`variable` looks a variable up by name and returns `None` when it is absent; `require_variable` aborts instead. Lookup is a linear scan.

```mbti
pub fn VariableContext::variable(Self, String) -> Variable?
pub fn VariableContext::require_variable(Self, String) -> Variable
```

### `VariableContext::contains`

Returns `true` when the context's variable at `variable.index()` equals `variable`. A variable from a structurally equal context is therefore contained as well.

```mbti
pub fn VariableContext::contains(Self, Variable) -> Bool
```

### `VariableContext::variable_by_type_theory_name`

Resolves a `type_theory` `Name` to the variable with the same text, or `None`.

```mbti
pub fn VariableContext::variable_by_type_theory_name(Self, @Luna-Flow/type_theory/core.Name) -> Variable?
```

For every variable `v` of a context `c`, `c.variable_by_type_theory_name(v.to_type_theory_name()) == Some(v)`.

### `VariableContext::require_type_theory_name`

Like `variable_by_type_theory_name`, but aborts when the name is unknown.

```mbti
pub fn VariableContext::require_type_theory_name(Self, @Luna-Flow/type_theory/core.Name) -> Variable
```

### `VariableContext::equal`

Structural equality, also available as `==`.

```mbti
pub fn VariableContext::equal(Self, Self) -> Bool
```

```moonbit
test "variable contexts" {
  let ctx = @poly_core.VariableContext::from_names(["x", "y"])
  inspect(ctx, content="VariableContext(x, y)")
  let (ctx2, z) = ctx.extend_with("z")
  inspect(z.index(), content="2")
  inspect(ctx.size(), content="2")
  assert_true(ctx.extend_checked("x") is None)
  assert_true(@poly_core.VariableContext::from_names_checked(["a", "a"]) is None)
  let y = ctx2.require_variable("y")
  let name = y.to_type_theory_name()
  inspect(name.text(), content="y")
  assert_true(ctx2.variable_by_type_theory_name(name) == Some(y))
  assert_true(ctx2.variable_by_type_theory_name(@tt_core.Name::new("w")) is None)
  assert_true(ctx.contains(y))
  assert_false(ctx.contains(z))
}
```

## Shapes

### `PolynomialShape`

`PolynomialShape` describes the dimensions of a polynomial without its coefficients. Construct it with the snake-case functions below or with the constructors.

```mbti
pub enum PolynomialShape {
  Univariate(length~ : Int)
  Multivariate(arity~ : Int, term_count~ : Int)
  Contextual(context~ : VariableContext, arity~ : Int, term_count~ : Int)
} derive(Eq, @debug.Debug)
pub fn PolynomialShape::equal(Self, Self) -> Bool
```

`length` is the number of stored coefficients of a dense polynomial, `arity` the number of variables in use (the longest exponent vector), and `term_count` the number of non-zero terms.

### `PolynomialShape::univariate`, `PolynomialShape::multivariate`, `PolynomialShape::contextual`

Build the three shapes.

```mbti
pub fn PolynomialShape::univariate(Int) -> Self
pub fn PolynomialShape::multivariate(Int, Int) -> Self
pub fn PolynomialShape::contextual(VariableContext, Int, Int) -> Self
```

### `PolynomialShape::arity`

Returns the arity; a univariate shape has arity `1`.

```mbti
pub fn PolynomialShape::arity(Self) -> Int
```

### `PolynomialShape::term_count`

Returns the term count, or `None` for a univariate shape, which does not record it.

```mbti
pub fn PolynomialShape::term_count(Self) -> Int?
```

### `PolynomialShape::is_compatible_with`

Returns `true` when values of the two shapes may be combined: two univariate shapes, two multivariate shapes, or two contextual shapes over equal contexts. Arity and term count are ignored.

```mbti
pub fn PolynomialShape::is_compatible_with(Self, Self) -> Bool
```

### `PolynomialShape::compatible_checked`

Returns `Some(())` when the shapes are compatible and `None` otherwise, for use in `Option` pipelines.

```mbti
pub fn PolynomialShape::compatible_checked(Self, Self) -> Unit?
```

```moonbit
test "shapes" {
  let ctx = @poly_core.VariableContext::from_names(["x"])
  let a = @poly_core.PolynomialShape::multivariate(2, 5)
  let b = @poly_core.PolynomialShape::multivariate(3, 1)
  let c = @poly_core.PolynomialShape::contextual(ctx, 1, 1)
  assert_true(a.is_compatible_with(b))
  assert_false(a.is_compatible_with(c))
  inspect(a.arity(), content="2")
  assert_true(@poly_core.PolynomialShape::univariate(4).term_count() is None)
  assert_true(c.compatible_checked(c) is Some(_))
}
```

## Capability traits

The capability traits are small, open traits (`pub(open)`) that state one observable property each. The bundle traits combine them into what generic code usually asks for. All concrete polynomial types of the library implement the bundles listed in this table:

| Trait | Required methods / supertraits | Implemented by |
| --- | --- | --- |
| `UnivariatePolynomial` | `HasShape + HasLength + HasDegree + IsZero` | `DensePolynomial` |
| `MultivariatePolynomial` | `HasShape + HasTermCount + HasArity + HasTotalDegree + IsZero` | `TermPolynomial`, `SparsePolynomial` |
| `ContextualPolynomial` | `HasShape + HasContext + HasTermCount + HasArity + IsZero` | `ContextPolynomial` |
| `MutablePolynomial` | `Clearable + Copyable` | every `mutable` container |

### `HasLength`

The number of stored coefficients of a dense polynomial; `0` for zero.

```mbti
pub(open) trait HasLength {
  fn length(Self) -> Int
}
```

### `HasDegree`

The degree of a univariate polynomial, `None` for the zero polynomial.

```mbti
pub(open) trait HasDegree {
  fn degree(Self) -> Int?
}
```

### `IsZero`

Whether the value is the zero polynomial. In canonical form this is "has no stored terms".

```mbti
pub(open) trait IsZero {
  fn is_zero(Self) -> Bool
}
```

### `HasTermCount`

The number of non-zero terms.

```mbti
pub(open) trait HasTermCount {
  fn term_count(Self) -> Int
}
```

### `HasArity`

The number of variables in use: the maximum `ExponentVector::length` over all terms, `0` for constants.

```mbti
pub(open) trait HasArity {
  fn arity(Self) -> Int
}
```

### `HasTotalDegree`

The maximum total degree over all terms, `None` for zero.

```mbti
pub(open) trait HasTotalDegree {
  fn total_degree(Self) -> UInt?
}
```

### `HasContext`

The variable context a polynomial is bound to.

```mbti
pub(open) trait HasContext {
  fn context(Self) -> VariableContext
}
```

### `HasShape`

The [`PolynomialShape`](#polynomialshape) of a value.

```mbti
pub(open) trait HasShape {
  fn shape(Self) -> PolynomialShape
}
```

### `Clearable`

Resets a mutable container to zero in place.

```mbti
pub(open) trait Clearable {
  fn clear(Self) -> Unit
}
```

### `Copyable`

Returns an independent copy of a mutable container: later mutation of either value does not affect the other.

```mbti
pub(open) trait Copyable {
  fn copy(Self) -> Self
}
```

### `UnivariatePolynomial`

Bundle for dense univariate polynomials.

```mbti
pub(open) trait UnivariatePolynomial : HasShape + HasLength + HasDegree + IsZero {
}
```

### `MultivariatePolynomial`

Bundle for index-addressed multivariate polynomials.

```mbti
pub(open) trait MultivariatePolynomial : HasShape + HasTermCount + HasArity + HasTotalDegree + IsZero {
}
```

### `ContextualPolynomial`

Bundle for polynomials bound to a `VariableContext`.

```mbti
pub(open) trait ContextualPolynomial : HasShape + HasContext + HasTermCount + HasArity + IsZero {
}
```

### `MutablePolynomial`

Bundle for mutable containers.

```mbti
pub(open) trait MutablePolynomial : Clearable + Copyable {
}
```

```moonbit
fn[P : @poly_core.MultivariatePolynomial] describe(p : P) -> String {
  let degree = match @poly_core.HasTotalDegree::total_degree(p) {
    Some(d) => d.to_string()
    None => "-"
  }
  "terms=\{@poly_core.HasTermCount::term_count(p)} arity=\{@poly_core.HasArity::arity(p)} degree=\{degree}"
}

test "capability traits" {
  let term = @immut.TermPolynomial::from_array([([2U, 1], 3), ([], 1)])
  let sparse = @immut.SparsePolynomial::from_array([([2U, 1], 3), ([], 1)])
  inspect(describe(term), content="terms=2 arity=2 degree=3")
  inspect(describe(sparse), content="terms=2 arity=2 degree=3")
}
```

Inside a function with a multi-trait bound, call trait methods in the qualified form `Trait::method(value)`, as above.

## Operation records

MoonBit traits have only the `Self` type parameter, so a trait cannot say "a polynomial type `P` with coefficient type `A`". The operation records fill that gap: each concrete type returns a record of functions from its `ops()` method, and generic code receives the record as an ordinary argument. The accessor methods call the stored functions; they add no behaviour of their own.

### `UnivariateOps`

Operations of a univariate polynomial type `P` with coefficients `A`.

```mbti
type UnivariateOps[P, A]
pub fn[P, A] UnivariateOps::new(() -> P, () -> P, (Array[A]) -> P, (P) -> Array[A], (P, Int) -> A, (P, Int) -> A?, (P, A) -> A, (P, P) -> P, (P, P) -> P, (P, Int, A) -> P, (P, Int, A) -> P?, (P, UInt) -> P) -> Self[P, A]
```

`new` takes, in order: `zero`, `one`, `from_coefficients`, `to_coefficients`, `coefficient`, `coefficient_checked`, `eval`, `add`, `mul`, `scale`, `scale_checked` and `pow`, with the meanings of the [`DensePolynomial`](immut/dense.md) methods of the same names. Use it to wrap your own univariate type.

### `UnivariateOps` accessors

Each accessor applies the corresponding stored function.

```mbti
pub fn[P, A] UnivariateOps::zero(Self[P, A]) -> P
pub fn[P, A] UnivariateOps::one(Self[P, A]) -> P
pub fn[P, A] UnivariateOps::from_coefficients(Self[P, A], Array[A]) -> P
pub fn[P, A] UnivariateOps::to_coefficients(Self[P, A], P) -> Array[A]
pub fn[P, A] UnivariateOps::coefficient(Self[P, A], P, Int) -> A
pub fn[P, A] UnivariateOps::coefficient_checked(Self[P, A], P, Int) -> A?
pub fn[P, A] UnivariateOps::eval(Self[P, A], P, A) -> A
pub fn[P, A] UnivariateOps::add(Self[P, A], P, P) -> P
pub fn[P, A] UnivariateOps::mul(Self[P, A], P, P) -> P
pub fn[P, A] UnivariateOps::scale(Self[P, A], P, Int, A) -> P
pub fn[P, A] UnivariateOps::scale_checked(Self[P, A], P, Int, A) -> P?
pub fn[P, A] UnivariateOps::pow(Self[P, A], P, UInt) -> P
```

### `MultivariateOps`

Operations of an index-addressed multivariate polynomial type `P` with coefficients `A`.

```mbti
type MultivariateOps[P, A]
pub fn[P, A] MultivariateOps::new(() -> P, () -> P, (Array[(ExponentVector, A)]) -> P, (P) -> Array[(ExponentVector, A)], (P, Array[A]) -> A, (P, Array[A]) -> A?, (P, P) -> P, (P, P) -> P, (P, ExponentVector, A) -> P, (P, UInt) -> P) -> Self[P, A]
```

`new` takes, in order: `zero`, `one`, `from_terms`, `to_terms`, `eval_indexed`, `eval_indexed_checked`, `add`, `mul`, `scale` and `pow`. `eval_indexed` is the `eval` method of [`TermPolynomial`](immut/term.md) and [`SparsePolynomial`](immut/sparse.md).

### `MultivariateOps` accessors

```mbti
pub fn[P, A] MultivariateOps::zero(Self[P, A]) -> P
pub fn[P, A] MultivariateOps::one(Self[P, A]) -> P
pub fn[P, A] MultivariateOps::from_terms(Self[P, A], Array[(ExponentVector, A)]) -> P
pub fn[P, A] MultivariateOps::to_terms(Self[P, A], P) -> Array[(ExponentVector, A)]
pub fn[P, A] MultivariateOps::eval_indexed(Self[P, A], P, Array[A]) -> A
pub fn[P, A] MultivariateOps::eval_indexed_checked(Self[P, A], P, Array[A]) -> A?
pub fn[P, A] MultivariateOps::add(Self[P, A], P, P) -> P
pub fn[P, A] MultivariateOps::mul(Self[P, A], P, P) -> P
pub fn[P, A] MultivariateOps::scale(Self[P, A], P, ExponentVector, A) -> P
pub fn[P, A] MultivariateOps::pow(Self[P, A], P, UInt) -> P
```

### `ContextOps`

Operations of a context-bound polynomial type `P` with coefficients `A`.

```mbti
type ContextOps[P, A]
pub fn[P, A] ContextOps::new((VariableContext, Array[(ExponentVector, A)]) -> P, (P) -> Array[(ExponentVector, A)], (P, Array[(Variable, A)]) -> A?, (P, P) -> P?, (P, P) -> P?) -> Self[P, A]
```

`new` takes, in order: `from_terms`, `to_terms`, `eval_named_checked`, `add_checked` and `mul_checked`, with the meanings of the [`ContextPolynomial`](immut/context.md) methods.

### `ContextOps` accessors

```mbti
pub fn[P, A] ContextOps::from_terms(Self[P, A], VariableContext, Array[(ExponentVector, A)]) -> P
pub fn[P, A] ContextOps::to_terms(Self[P, A], P) -> Array[(ExponentVector, A)]
pub fn[P, A] ContextOps::eval_named_checked(Self[P, A], P, Array[(Variable, A)]) -> A?
pub fn[P, A] ContextOps::add_checked(Self[P, A], P, P) -> P?
pub fn[P, A] ContextOps::mul_checked(Self[P, A], P, P) -> P?
```

```moonbit
fn[P, A] sum_of_squares(ops : @poly_core.MultivariateOps[P, A], polys : Array[P]) -> P {
  let mut acc = ops.zero()
  for p in polys {
    acc = ops.add(acc, ops.pow(p, 2))
  }
  acc
}

test "operation records" {
  let x = @immut.SparsePolynomial::from_array([([1U], 1)])
  let y = @immut.SparsePolynomial::from_array([([0U, 1], 1)])
  let ops = @immut.SparsePolynomial::ops()
  let s = sum_of_squares(ops, [x, y])
  inspect(s, content="1 * x^2 + 1 * x_1^2")
  inspect(ops.eval_indexed(s, [3, 4]), content="25")
}
```

## Deprecated

| Deprecated | Replacement |
| --- | --- |
| `VariableContext::extend` | `VariableContext::extend_with` (same behaviour; `extend` is now a reserved word) |
| `not_equal`, `op_lt`, `op_le`, `op_gt`, `op_ge` methods on `ExponentVector`, `Variable`, `VariableContext`, `PolynomialShape` | the operators `!=`, `<`, `<=`, `>`, `>=` |
| `output` methods (from `Show`) | `to_string` or string interpolation |
| `to_repr` methods (from `Debug`) | `Repr(x)` or `debug_inspect` |
| `ExponentVector::hash_combine` | `Hash::hash_combine` through the trait |

The method forms in the last four rows are hidden from the interface file and kept only for source compatibility.
