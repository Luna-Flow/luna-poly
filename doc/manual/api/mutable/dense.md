# mutable/dense API

## Purpose

`Luna-Flow/luna-poly/mutable/dense` provides a mutable `DensePolynomial[A]`: the same canonical ascending coefficient storage as [`immut/dense`](../immut/dense.md), held in a growable array that setters and `_inplace` methods update. Operators and all other methods return new values and leave their operands untouched.

Methods marked "as in immut" have exactly the semantics, bounds and costs described on the [immut/dense API](../immut/dense.md) page. The mutation model is explained in the [mutable/dense design](../../design/mutable/dense.md).

## Importing

The type is re-exported by the [`mutable`](../mutable.md) facade, which the examples use:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/mutable",
}
```

To depend on this package alone, import `"Luna-Flow/luna-poly/mutable/dense"` instead; its names are the same.

## The type

### `DensePolynomial`

A mutable dense univariate polynomial whose stored array never ends in a zero coefficient.

```mbti
type DensePolynomial[A] derive(Compare, Eq, @debug.Debug)
pub impl[A] @luna-generic.Zero for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + @luna-generic.One] @luna-generic.One for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] Add for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Neg] Sub for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul] Mul for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + Neg] Neg for DensePolynomial[A]
pub impl[A : Show + Eq + @luna-generic.Zero] Show for DensePolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] @arithmetic.PowNatChecked for DensePolynomial[A]
pub impl[A] @core.Clearable for DensePolynomial[A]
pub impl[A] @core.Copyable for DensePolynomial[A]
pub impl[A] @core.HasDegree for DensePolynomial[A]
pub impl[A] @core.HasLength for DensePolynomial[A]
pub impl[A] @core.HasShape for DensePolynomial[A]
pub impl[A] @core.IsZero for DensePolynomial[A]
pub impl[A] @core.MutablePolynomial for DensePolynomial[A]
pub impl[A] @core.UnivariatePolynomial for DensePolynomial[A]
```

## Construction and conversion

### `DensePolynomial::from_coefficients`, `DensePolynomial::constant`, `DensePolynomial::variable`, `DensePolynomial::monomial`, `DensePolynomial::monomial_checked`, `DensePolynomial::zero`, `DensePolynomial::one`

Build polynomials, as in immut. `from_coefficients` copies its input.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::from_coefficients(Array[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::constant(A) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] DensePolynomial::variable() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::monomial(Int, A) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::monomial_checked(Int, A) -> Self[A]?
pub fn[A] DensePolynomial::zero() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] DensePolynomial::one() -> Self[A]
```

### `DensePolynomial::from_immut`

Returns a new mutable polynomial with the coefficients of an immutable one.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::from_immut(@Luna-Flow/luna-poly/immut/dense.DensePolynomial[A]) -> Self[A]
```

### `DensePolynomial::to_immut`

Returns an immutable snapshot of the current coefficients. Later mutation of the receiver does not affect the snapshot.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::to_immut(Self[A]) -> @Luna-Flow/luna-poly/immut/dense.DensePolynomial[A]
```

### `DensePolynomial::copy`

Returns an independent copy (also `Copyable::copy`). $O(n)$.

```mbti
pub fn[A] DensePolynomial::copy(Self[A]) -> Self[A]
```

## Queries

### `DensePolynomial::to_coefficients`, `DensePolynomial::length`, `DensePolynomial::degree`, `DensePolynomial::is_zero`, `DensePolynomial::coefficient`, `DensePolynomial::coefficient_checked`, `DensePolynomial::leading_term`, `DensePolynomial::leading_coefficient`, `DensePolynomial::shape`

As in immut. `to_coefficients` returns a copy, so mutating the result does not affect the polynomial.

```mbti
pub fn[A] DensePolynomial::to_coefficients(Self[A]) -> Array[A]
pub fn[A] DensePolynomial::length(Self[A]) -> Int
pub fn[A] DensePolynomial::degree(Self[A]) -> Int?
pub fn[A] DensePolynomial::is_zero(Self[A]) -> Bool
pub fn[A : @luna-generic.Zero] DensePolynomial::coefficient(Self[A], Int) -> A
pub fn[A : @luna-generic.Zero] DensePolynomial::coefficient_checked(Self[A], Int) -> A?
pub fn[A] DensePolynomial::leading_term(Self[A]) -> (Int, A)?
pub fn[A] DensePolynomial::leading_coefficient(Self[A]) -> A?
pub fn[A] DensePolynomial::shape(Self[A]) -> @core.PolynomialShape
```

## Mutation

### `DensePolynomial::set_coefficient`

Sets the coefficient of $x^k$, growing the array when $k$ is beyond the degree and trimming afterwards, so setting the leading coefficient to zero lowers the degree. A negative power aborts; there is no checked variant.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::set_coefficient(Self[A], Int, A) -> Unit
```

### `DensePolynomial::clear`

Makes the receiver the zero polynomial (also `Clearable::clear`).

```mbti
pub fn[A] DensePolynomial::clear(Self[A]) -> Unit
```

### `DensePolynomial::add_inplace`

Replaces the receiver by `self + other`, adding into the existing array; $O(\max(m, n))$. `p.add_inplace(p)` doubles `p`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] DensePolynomial::add_inplace(Self[A], Self[A]) -> Unit
```

### `DensePolynomial::mul_inplace`

Replaces the receiver by `self * other` (schoolbook, $O(mn)$). The product is computed into a new array first, so `p.mul_inplace(p)` squares `p`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] DensePolynomial::mul_inplace(Self[A], Self[A]) -> Unit
```

### `DensePolynomial::scale_inplace`

Replaces the receiver by $c\,x^k \cdot p$. A negative power aborts.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] DensePolynomial::scale_inplace(Self[A], Int, A) -> Unit
```

```moonbit
test "mutation" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  let snapshot = p.to_immut()
  p.set_coefficient(4, 1)
  inspect(p, content="1 + 2x^1 + 3x^2 + 1x^4")
  p.set_coefficient(4, 0)
  debug_inspect(p.degree(), content="Some(2)")
  p.add_inplace(@mutable.DensePolynomial::from_coefficients([-1, -2, -3]))
  assert_true(p.is_zero())
  inspect(snapshot, content="1 + 2x^1 + 3x^2")
  let q = @mutable.DensePolynomial::from_coefficients([1, 1])
  q.mul_inplace(q)
  q.scale_inplace(1, 2)
  inspect(q, content="2x^1 + 4x^2 + 2x^3")
}
```

## Non-mutating operations

### `DensePolynomial::add`, `DensePolynomial::sub`, `DensePolynomial::mul`, `DensePolynomial::neg`

The operators `+`, `-`, `*` and unary `-`, returning new polynomials, as in immut.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] DensePolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] DensePolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] DensePolynomial::mul(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] DensePolynomial::neg(Self[A]) -> Self[A]
```

### `DensePolynomial::scale`, `DensePolynomial::scale_checked`, `DensePolynomial::pow`, `DensePolynomial::karatsuba`

As in immut; computed by converting to the immutable type and back.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] DensePolynomial::scale(Self[A], Int, A) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Mul] DensePolynomial::scale_checked(Self[A], Int, A) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] DensePolynomial::pow(Self[A], UInt) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + Neg + @luna-generic.One] DensePolynomial::karatsuba(Self[A], Self[A]) -> Self[A]
```

### `DensePolynomial::eval`, `DensePolynomial::substitute`, `DensePolynomial::derivative`

Horner evaluation, composition $p(q)$ and the formal derivative, as in immut.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul] DensePolynomial::eval(Self[A], A) -> A
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] DensePolynomial::substitute(Self[A], Self[A]) -> Self[A]
pub fn[A : @luna-generic.FromNat + Eq + @luna-generic.Zero + Mul] DensePolynomial::derivative(Self[A]) -> Self[A]
```

### `DensePolynomial::equal`, `DensePolynomial::compare`, `DensePolynomial::to_string`

Structural equality, the structural order (degree first, then coefficients from the constant term) and printing, as in immut.

```mbti
pub fn[A : Eq] DensePolynomial::equal(Self[A], Self[A]) -> Bool
pub fn[A : Compare] DensePolynomial::compare(Self[A], Self[A]) -> Int
pub fn[A : Show + Eq + @luna-generic.Zero] DensePolynomial::to_string(Self[A]) -> String
```

### `DensePolynomial::ops`

The [`UnivariateOps`](../core.md#univariateops) record of the mutable type. Its functions do not mutate their arguments.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] DensePolynomial::ops() -> @core.UnivariateOps[Self[A], A]
```

```moonbit
test "non-mutating" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  let q = p * p
  inspect(p, content="1 + 2x^1 + 3x^2")
  inspect(q.eval(1), content="36")
  let f = @mutable.DensePolynomial::from_coefficients([1.0, 2.0, 3.0])
  debug_inspect(f.derivative().to_coefficients(), content="[2, 6]")
  inspect(@mutable.DensePolynomial::ops().eval(p, 2), content="17")
}
```

## Deprecated

Hidden method forms kept for source compatibility:

| Deprecated | Replacement |
| --- | --- |
| `p.not_equal(q)` | `p != q` |
| `p.op_lt(q)`, `op_le`, `op_gt`, `op_ge` | `<`, `<=`, `>`, `>=` |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
| `p.pow_nat_checked(e, ctx)` | `@arithmetic.PowNatChecked::pow_nat_checked(p, e, ctx)` or `p.pow(e)` |
