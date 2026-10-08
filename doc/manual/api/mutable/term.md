# mutable/term API

`Luna-Flow/luna-poly/mutable/term` provides a mutable `TermPolynomial[A]`: the canonical descending term array of [`immut/term`](../immut/term.md), held in a mutable field that `_inplace` methods and `clear` replace. Operators and all other methods return new values.

The type is re-exported by the [`mutable`](../mutable.md) facade as `@mutable.TermPolynomial`, which the examples use. "As in immut" means the semantics, bounds and costs of the [immut/term API](../immut/term.md). The mutation model is explained in the [mutable/term design](../../design/mutable/term.md).

## The type

### `TermPolynomial`

A mutable multivariate polynomial whose term array is always sorted in descending monomial order, merged, and free of zero coefficients.

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
pub impl[A] @core.Clearable for TermPolynomial[A]
pub impl[A] @core.Copyable for TermPolynomial[A]
pub impl[A] @core.HasArity for TermPolynomial[A]
pub impl[A] @core.HasShape for TermPolynomial[A]
pub impl[A] @core.HasTermCount for TermPolynomial[A]
pub impl[A] @core.HasTotalDegree for TermPolynomial[A]
pub impl[A] @core.IsZero for TermPolynomial[A]
pub impl[A] @core.MultivariatePolynomial for TermPolynomial[A]
pub impl[A] @core.MutablePolynomial for TermPolynomial[A]
```

## Construction and conversion

### `TermPolynomial::from_terms`, `TermPolynomial::from_array`, `TermPolynomial::zero`, `TermPolynomial::one`

Build polynomials, as in immut. The input array is copied.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::from_terms(Array[(@core.ExponentVector, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::from_array(Array[(Array[UInt], A)]) -> Self[A]
pub fn[A] TermPolynomial::zero() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] TermPolynomial::one() -> Self[A]
```

### `TermPolynomial::from_immut`, `TermPolynomial::to_immut`

Convert from and to the immutable type. Both copy, so later mutation never affects the other value. `to_immut` re-normalizes the terms, $O(m \log m)$.

```mbti
pub fn[A] TermPolynomial::from_immut(@Luna-Flow/luna-poly/immut/term.TermPolynomial[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::to_immut(Self[A]) -> @Luna-Flow/luna-poly/immut/term.TermPolynomial[A]
```

### `TermPolynomial::copy`

Returns an independent copy (also `Copyable::copy`).

```mbti
pub fn[A] TermPolynomial::copy(Self[A]) -> Self[A]
```

## Queries

### `TermPolynomial::to_terms`, `TermPolynomial::coefficients`, `TermPolynomial::size`, `TermPolynomial::term_count`, `TermPolynomial::is_zero`, `TermPolynomial::arity`, `TermPolynomial::total_degree`, `TermPolynomial::shape`

As in immut. `to_terms` and `coefficients` return fresh arrays, leading term first.

```mbti
pub fn[A] TermPolynomial::to_terms(Self[A]) -> Array[(@core.ExponentVector, A)]
pub fn[A] TermPolynomial::coefficients(Self[A]) -> Array[A]
pub fn[A] TermPolynomial::size(Self[A]) -> Int
pub fn[A] TermPolynomial::term_count(Self[A]) -> Int
pub fn[A] TermPolynomial::is_zero(Self[A]) -> Bool
pub fn[A] TermPolynomial::arity(Self[A]) -> Int
pub fn[A] TermPolynomial::total_degree(Self[A]) -> UInt?
pub fn[A] TermPolynomial::shape(Self[A]) -> @core.PolynomialShape
```

## Mutation

### `TermPolynomial::add_term_inplace`

Adds $c\,x^\alpha$ to the receiver: merges with an existing term of the same exponent vector and removes it if the sum is zero. The whole array is renormalized, $O(m \log m)$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::add_term_inplace(Self[A], @core.ExponentVector, A) -> Unit
```

### `TermPolynomial::add_inplace`

Replaces the receiver by `self + other` by adding the terms of `other` one at a time with `add_term_inplace`. For $n$ terms in `other` this costs $O(n\,(m + n)\log(m + n))$; for large operands prefer `p = p + q` or `from_terms` on the concatenated terms.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::add_inplace(Self[A], Self[A]) -> Unit
```

### `TermPolynomial::mul_inplace`

Replaces the receiver by `self * other`; the product is computed first, so `p.mul_inplace(p)` squares `p`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] TermPolynomial::mul_inplace(Self[A], Self[A]) -> Unit
```

### `TermPolynomial::scale_inplace`

Replaces the receiver by $c\,x^\gamma \cdot p$, keeping the order without re-sorting.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] TermPolynomial::scale_inplace(Self[A], @core.ExponentVector, A) -> Unit
```

### `TermPolynomial::clear`

Makes the receiver zero (also `Clearable::clear`).

```mbti
pub fn[A] TermPolynomial::clear(Self[A]) -> Unit
```

```moonbit
test "mutation" {
  let p = @mutable.TermPolynomial::from_array([([1U], 2)])
  p.add_term_inplace(@mutable.ExponentVector::from_array([0U, 1]), 3)
  inspect(p, content="3 * x_1 + 2 * x")
  p.add_term_inplace(@mutable.ExponentVector::from_array([1U, 0]), -2)
  inspect(p, content="3 * x_1")
  p.mul_inplace(p)
  p.scale_inplace(@mutable.ExponentVector::from_array([1U]), 2)
  inspect(p, content="18 * xx_1^2")
  p.clear()
  assert_true(p.is_zero())
}
```

## Non-mutating operations

### `TermPolynomial::add`, `TermPolynomial::sub`, `TermPolynomial::mul`, `TermPolynomial::neg`

The operators `+`, `-`, `*` and unary `-`, as in immut. `+` copies the receiver and calls `add_inplace`, so it has that method's cost; `*` delegates to the immutable product.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] TermPolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] TermPolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] TermPolynomial::mul(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] TermPolynomial::neg(Self[A]) -> Self[A]
```

### `TermPolynomial::scale`, `TermPolynomial::pow`, `TermPolynomial::eval`, `TermPolynomial::eval_checked`

As in immut.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] TermPolynomial::scale(Self[A], @core.ExponentVector, A) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::pow(Self[A], UInt) -> Self[A]
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::eval(Self[A], Array[A]) -> A
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::eval_checked(Self[A], Array[A]) -> A?
```

### `TermPolynomial::equal`, `TermPolynomial::to_string`, `TermPolynomial::ops`

Structural equality, printing and the [`MultivariateOps`](../core.md#multivariateops) record, as in immut.

```mbti
pub fn[A : Eq] TermPolynomial::equal(Self[A], Self[A]) -> Bool
pub fn[A : Show + @luna-generic.Zero] TermPolynomial::to_string(Self[A]) -> String
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] TermPolynomial::ops() -> @core.MultivariateOps[Self[A], A]
```

```moonbit
test "non-mutating" {
  let p = @mutable.TermPolynomial::from_array([([1U], 1), ([], 1)])
  let q = p.pow(2)
  inspect(q, content="1 * x^2 + 2 * x + 1")
  inspect(p, content="1 * x + 1")
  inspect(q.eval([3]), content="16")
  assert_true(q.to_immut() == @immut.TermPolynomial::from_array([([2U], 1), ([1U], 2), ([], 1)]))
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
