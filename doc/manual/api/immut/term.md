# immut/term API

## Purpose

`Luna-Flow/luna-poly/immut/term` provides `TermPolynomial[A]`, an immutable multivariate polynomial stored as an array of `(ExponentVector, A)` terms. The array is canonical: sorted in *descending* [monomial order](../../design/core.md#the-monomial-order), with no two terms sharing an exponent vector and no zero coefficients.

Variables are addressed by index: variable $i$ is position $i$ of the exponent vectors. For named variables use [`ContextPolynomial`](context.md). The design is explained in the [immut/term design](../../design/immut/term.md).

## Importing

The type is re-exported by the [`immut`](../immut.md) facade, which the examples use:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/immut",
}
```

To depend on this package alone, import `"Luna-Flow/luna-poly/immut/term"` instead; its names are the same.

## The type

### `TermPolynomial`

`TermPolynomial[A]` represents $\sum_k c_k x^{\alpha_k}$ by the terms $(\alpha_k, c_k)$ with $\alpha_1 \succ \alpha_2 \succ \cdots$ and every $c_k \neq 0$.

```mbti
type TermPolynomial[A] derive(Eq, @debug.Debug)
pub impl[A] @luna-generic.Zero for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + @luna-generic.One] @luna-generic.One for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] Add for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Neg] Sub for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul] Mul for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + Neg] Neg for TermPolynomial[A]
pub impl[A : Show + @luna-generic.Zero] Show for TermPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] @arithmetic.PowNatChecked for TermPolynomial[A]
pub impl[A] @core.HasArity for TermPolynomial[A]
pub impl[A] @core.HasShape for TermPolynomial[A]
pub impl[A] @core.HasTermCount for TermPolynomial[A]
pub impl[A] @core.HasTotalDegree for TermPolynomial[A]
pub impl[A] @core.IsZero for TermPolynomial[A]
pub impl[A] @core.MultivariatePolynomial for TermPolynomial[A]
```

## Construction

### `TermPolynomial::from_terms`

Builds the canonical polynomial of a list of terms: sorts them, adds the coefficients of equal exponent vectors, and drops zero sums. The input is copied. Cost $O(m \log m)$ comparisons for $m$ input terms.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::from_terms(Array[(@core.ExponentVector, A)]) -> Self[A]
```

### `TermPolynomial::from_array`

Like `from_terms`, with each exponent vector given as an `Array[UInt]` (converted with `ExponentVector::from_array`).

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::from_array(Array[(Array[UInt], A)]) -> Self[A]
```

### `TermPolynomial::zero`, `TermPolynomial::one`

The empty polynomial and the constant $1$ (the zero polynomial if $1 = 0$ in `A`), also `Zero::zero()` and `One::one()`.

```mbti
pub fn[A] TermPolynomial::zero() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] TermPolynomial::one() -> Self[A]
```

```moonbit
test "construction" {
  let p = @immut.TermPolynomial::from_array([
    ([0U, 1], 3),
    ([2U], 1),
    ([1U, 0], 2),
    ([1U], -2),
    ([], 4),
  ])
  inspect(p, content="1 * x^2 + 3 * x_1 + 4")
  inspect(p.size(), content="3")
}
```

`[1, 0]` and `[1]` are the same monomial, so $2x_0 - 2x_0$ cancels.

## Queries

### `TermPolynomial::to_terms`

Returns a fresh array of the canonical terms, leading term first.

```mbti
pub fn[A] TermPolynomial::to_terms(Self[A]) -> Array[(@core.ExponentVector, A)]
```

### `TermPolynomial::coefficients`

Returns the coefficients in the order of `to_terms`.

```mbti
pub fn[A] TermPolynomial::coefficients(Self[A]) -> Array[A]
```

### `TermPolynomial::size`, `TermPolynomial::term_count`

Both return the number of non-zero terms.

```mbti
pub fn[A] TermPolynomial::size(Self[A]) -> Int
pub fn[A] TermPolynomial::term_count(Self[A]) -> Int
```

### `TermPolynomial::is_zero`

Returns `true` when there are no terms.

```mbti
pub fn[A] TermPolynomial::is_zero(Self[A]) -> Bool
```

### `TermPolynomial::arity`

Returns the number of variables in use: the longest canonical exponent vector, `0` for constants and zero.

```mbti
pub fn[A] TermPolynomial::arity(Self[A]) -> Int
```

### `TermPolynomial::total_degree`

Returns the largest total degree of a term, or `None` for zero.

```mbti
pub fn[A] TermPolynomial::total_degree(Self[A]) -> UInt?
```

### `TermPolynomial::shape`

Returns `PolynomialShape::Multivariate(arity~, term_count~)`.

```mbti
pub fn[A] TermPolynomial::shape(Self[A]) -> @core.PolynomialShape
```

```moonbit
test "queries" {
  let p = @immut.TermPolynomial::from_array([([1U, 2], 5), ([0U, 0, 1], 1), ([], 7)])
  inspect(p.arity(), content="3")
  debug_inspect(p.total_degree(), content="Some(3)")
  debug_inspect(p.coefficients(), content="[5, 1, 7]")
  inspect(p.to_terms()[0].0, content="xx_1^2")
}
```

## Arithmetic

### `TermPolynomial::add`, `TermPolynomial::sub`, `TermPolynomial::neg`

Addition, subtraction and negation, the operators `+`, `-` and unary `-`. Addition concatenates the terms and renormalizes, $O((m + n) \log(m + n))$; negation keeps the order, $O(m)$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] TermPolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] TermPolynomial::neg(Self[A]) -> Self[A]
```

### `TermPolynomial::mul`

Multiplies every term of one operand by every term of the other and renormalizes, the operator `*`. Cost $O(mn \log(mn))$ for $m$ and $n$ terms.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] TermPolynomial::mul(Self[A], Self[A]) -> Self[A]
```

### `TermPolynomial::scale`

Returns $c\,x^\gamma \cdot p$ for an exponent vector $\gamma$ and a coefficient $c$. Products that vanish are dropped. The result stays sorted without re-sorting, so the cost is $O(m)$ term operations.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] TermPolynomial::scale(Self[A], @core.ExponentVector, A) -> Self[A]
```

### `TermPolynomial::pow`

Returns $p^e$ by binary exponentiation; `pow(0)` is `one()`. Also available through `@arithmetic.PowNatChecked`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::pow(Self[A], UInt) -> Self[A]
```

```moonbit
test "arithmetic" {
  let x = @immut.TermPolynomial::from_array([([1U], 1)])
  let y = @immut.TermPolynomial::from_array([([0U, 1], 1)])
  inspect((x + y).pow(2), content="1 * x_1^2 + 2 * xx_1 + 1 * x^2")
  inspect((x + y) * (x - y), content="-1 * x_1^2 + 1 * x^2")
  let xy = @immut.ExponentVector::from_array([1U, 1])
  inspect((x + y).scale(xy, 3), content="3 * xx_1^2 + 3 * x^2x_1")
}
```

## Evaluation

### `TermPolynomial::eval`

Evaluates at the point `values`, where `values[i]` is the value of variable $i$. Each term is evaluated as $c \prod_i a_i^{\alpha_i}$ with binary exponentiation. It aborts when `values` is shorter than `arity()`; extra values are ignored.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::eval(Self[A], Array[A]) -> A
```

### `TermPolynomial::eval_checked`

Like `eval`, but returns `None` when `values.length() < arity()`.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::eval_checked(Self[A], Array[A]) -> A?
```

```moonbit
test "evaluation" {
  let p = @immut.TermPolynomial::from_array([([2U], 1), ([1U, 1], 3), ([], 4)])
  inspect(p.eval([2, 5]), content="38")
  assert_true(p.eval_checked([2]) is None)
  inspect(p.eval([2, 5, 100]), content="38")
}
```

## Comparison and printing

### `TermPolynomial::equal`

Structural equality of the canonical term arrays, which is equality of polynomials. It is `==`. There is no `Compare` instance.

```mbti
pub fn[A : Eq] TermPolynomial::equal(Self[A], Self[A]) -> Bool
```

### `TermPolynomial::to_string`

Renders the terms in stored order as `c * monomial` (just `c` for the constant term), joined by ` + `; zero prints as the coefficient zero. Monomials use the `ExponentVector` notation.

```mbti
pub fn[A : Show + @luna-generic.Zero] TermPolynomial::to_string(Self[A]) -> String
```

## Generic access

### `TermPolynomial::ops`

Returns the [`MultivariateOps`](../core.md#multivariateops) record of this type; `eval_indexed` is `eval`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::ops() -> @core.MultivariateOps[Self[A], A]
```

```moonbit
test "ops" {
  let ops = @immut.TermPolynomial::ops()
  let p = ops.from_terms([(@immut.ExponentVector::from_array([1U]), 2)])
  inspect(ops.eval_indexed(ops.pow(p, 3), [1]), content="8")
}
```

## Converting to sparse storage

There is no direct conversion method; go through the term list, which re-applies canonicalization:

```moonbit
test "conversion" {
  let t = @immut.TermPolynomial::from_array([([1U], 2), ([], 1)])
  let s = @immut.SparsePolynomial::from_terms(t.to_terms())
  let back = @immut.TermPolynomial::from_terms(s.to_terms())
  assert_true(back == t)
}
```

## Deprecated

Hidden method forms kept for source compatibility:

| Deprecated | Replacement |
| --- | --- |
| `p.not_equal(q)` | `p != q` |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
| `p.pow_nat_checked(e, ctx)` | `@arithmetic.PowNatChecked::pow_nat_checked(p, e, ctx)` or `p.pow(e)` |
