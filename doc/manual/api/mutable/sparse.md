# mutable/sparse API

## Purpose

`Luna-Flow/luna-poly/mutable/sparse` provides a mutable `SparsePolynomial[A]`: an ordered map from `ExponentVector` to non-zero coefficients, like [`immut/sparse`](../immut/sparse.md), with methods that update the map in place in logarithmic time.

"As in immut" means the semantics, bounds and costs of the [immut/sparse API](../immut/sparse.md). The mutation model is explained in the [mutable/sparse design](../../design/mutable/sparse.md).

## Importing

The type is re-exported by the [`mutable`](../mutable.md) facade, which the examples use:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/mutable",
}
```

To depend on this package alone, import `"Luna-Flow/luna-poly/mutable/sparse"` instead; its names are the same.

## The type

### `SparsePolynomial`

A mutable map from exponent vectors to non-zero coefficients, iterated in ascending monomial order.

```mbti
type SparsePolynomial[A] derive(@debug.Debug)
pub impl[A : Eq] Eq for SparsePolynomial[A]
pub impl[A] @luna-generic.Zero for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + @luna-generic.One] @luna-generic.One for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] Add for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Neg] Sub for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul] Mul for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + Neg] Neg for SparsePolynomial[A]
pub impl[A : Show + @luna-generic.Zero] Show for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] @arithmetic.PowNatChecked for SparsePolynomial[A]
pub impl[A] @core.Clearable for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] @core.Copyable for SparsePolynomial[A]
pub impl[A] @core.HasArity for SparsePolynomial[A]
pub impl[A] @core.HasShape for SparsePolynomial[A]
pub impl[A] @core.HasTermCount for SparsePolynomial[A]
pub impl[A] @core.HasTotalDegree for SparsePolynomial[A]
pub impl[A] @core.IsZero for SparsePolynomial[A]
pub impl[A] @core.MultivariatePolynomial for SparsePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] @core.MutablePolynomial for SparsePolynomial[A]
```

`Copyable` and `MutablePolynomial` need `Eq + AddMonoid` coefficients here, because `copy` rebuilds the map through `from_terms`.

## Construction and conversion

### `SparsePolynomial::new`, `SparsePolynomial::zero`, `SparsePolynomial::one`, `SparsePolynomial::from_terms`, `SparsePolynomial::from_array`

Build polynomials, as in immut.

```mbti
pub fn[A] SparsePolynomial::new() -> Self[A]
pub fn[A] SparsePolynomial::zero() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] SparsePolynomial::one() -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::from_terms(Array[(@core.ExponentVector, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::from_array(Array[(Array[UInt], A)]) -> Self[A]
```

### `SparsePolynomial::from_immut`, `SparsePolynomial::to_immut`

Convert from and to the immutable type; both build a new map.

```mbti
pub fn[A] SparsePolynomial::from_immut(@Luna-Flow/luna-poly/immut/sparse.SparsePolynomial[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::to_immut(Self[A]) -> @Luna-Flow/luna-poly/immut/sparse.SparsePolynomial[A]
```

### `SparsePolynomial::copy`

Returns an independent copy (also `Copyable::copy`), $O(m \log m)$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::copy(Self[A]) -> Self[A]
```

## Queries

### `SparsePolynomial::get`, `SparsePolynomial::get_checked`, `SparsePolynomial::to_terms`, `SparsePolynomial::size`, `SparsePolynomial::term_count`, `SparsePolynomial::is_empty`, `SparsePolynomial::is_zero`, `SparsePolynomial::arity`, `SparsePolynomial::total_degree`, `SparsePolynomial::shape`

As in immut: `get` is an $O(\log m)$ lookup returning `None` for absent (zero) terms, and `to_terms` returns a fresh array in ascending order.

```mbti
pub fn[A] SparsePolynomial::get(Self[A], @core.ExponentVector) -> A?
pub fn[A] SparsePolynomial::get_checked(Self[A], @core.ExponentVector) -> A?
pub fn[A] SparsePolynomial::to_terms(Self[A]) -> Array[(@core.ExponentVector, A)]
pub fn[A] SparsePolynomial::size(Self[A]) -> Int
pub fn[A] SparsePolynomial::term_count(Self[A]) -> Int
pub fn[A] SparsePolynomial::is_empty(Self[A]) -> Bool
pub fn[A] SparsePolynomial::is_zero(Self[A]) -> Bool
pub fn[A] SparsePolynomial::arity(Self[A]) -> Int
pub fn[A] SparsePolynomial::total_degree(Self[A]) -> UInt?
pub fn[A] SparsePolynomial::shape(Self[A]) -> @core.PolynomialShape
```

## Mutation

### `SparsePolynomial::set_coefficient`

Sets the coefficient of $x^\alpha$; setting it to zero removes the key. $O(\log m)$.

```mbti
pub fn[A : Eq + @luna-generic.Zero] SparsePolynomial::set_coefficient(Self[A], @core.ExponentVector, A) -> Unit
```

### `SparsePolynomial::add_term_inplace`

Adds $c\,x^\alpha$: inserts a new key, or adds to the existing coefficient and removes the key when the sum is zero. A zero $c$ does nothing. $O(\log m)$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::add_term_inplace(Self[A], @core.ExponentVector, A) -> Unit
```

### `SparsePolynomial::add_inplace`

Adds every term of `other` with `add_term_inplace`, $O(n \log(m + n))$. `p.add_inplace(p)` doubles `p` as long as no coefficient doubles to zero.

> [!WARNING]
> `p.add_inplace(p)` iterates over the map it is changing. When a doubled coefficient is zero (for example $2 \cdot (-2^{31}) = 0$ in `Int`), the key is removed during the iteration and other terms can be added twice or not at all: for $p = -2^{31} + x + x^2 + x^3$ the result is $4x + 2x^2 + 2x^3$ instead of $2x + 2x^2 + 2x^3$. Write `p.add_inplace(p.copy())` to double a polynomial in place.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::add_inplace(Self[A], Self[A]) -> Unit
```

### `SparsePolynomial::mul_inplace`

Replaces the contents by `self * other`; the product is computed first, so `p.mul_inplace(p)` squares `p`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] SparsePolynomial::mul_inplace(Self[A], Self[A]) -> Unit
```

### `SparsePolynomial::scale_inplace`

Replaces the contents by $c\,x^\gamma \cdot p$.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] SparsePolynomial::scale_inplace(Self[A], @core.ExponentVector, A) -> Unit
```

### `SparsePolynomial::clear`

Removes every term (also `Clearable::clear`).

```mbti
pub fn[A] SparsePolynomial::clear(Self[A]) -> Unit
```

```moonbit
test "mutation" {
  let x = @mutable.ExponentVector::from_array([1U])
  let p : @mutable.SparsePolynomial[Int] = @mutable.SparsePolynomial::new()
  p.set_coefficient(x, 3)
  p.add_term_inplace(x, -1)
  debug_inspect(p.get(x), content="Some(2)")
  p.add_term_inplace(@mutable.ExponentVector::one(), 5)
  p.add_inplace(p)
  inspect(p, content="10 + 4 * x")
  p.set_coefficient(x, 0)
  inspect(p, content="10")
  p.clear()
  assert_true(p.is_empty())
}
```

## Non-mutating operations

### `SparsePolynomial::add`, `SparsePolynomial::sub`, `SparsePolynomial::mul`, `SparsePolynomial::neg`, `SparsePolynomial::scale`, `SparsePolynomial::pow`

The operators and arithmetic methods, returning new polynomials, as in immut. `+` copies the receiver and calls `add_inplace`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] SparsePolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] SparsePolynomial::mul(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] SparsePolynomial::neg(Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Mul] SparsePolynomial::scale(Self[A], @core.ExponentVector, A) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::pow(Self[A], UInt) -> Self[A]
```

### `SparsePolynomial::eval`, `SparsePolynomial::eval_checked`, `SparsePolynomial::equal`, `SparsePolynomial::to_string`, `SparsePolynomial::ops`

Evaluation, equality, printing and the [`MultivariateOps`](../core.md#multivariateops) record, as in immut.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::eval(Self[A], Array[A]) -> A
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::eval_checked(Self[A], Array[A]) -> A?
pub fn[A : Eq] SparsePolynomial::equal(Self[A], Self[A]) -> Bool
pub fn[A : Show + @luna-generic.Zero] SparsePolynomial::to_string(Self[A]) -> String
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::ops() -> @core.MultivariateOps[Self[A], A]
```

```moonbit
test "non-mutating" {
  let p = @mutable.SparsePolynomial::from_array([([1U], 1), ([], 1)])
  let q = p * p
  inspect(q, content="1 + 2 * x + 1 * x^2")
  inspect(p, content="1 + 1 * x")
  inspect(q.eval([2]), content="9")
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
