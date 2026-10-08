# immut/dense API

`Luna-Flow/luna-poly/immut/dense` provides `DensePolynomial[A]`, an immutable univariate polynomial stored as its ascending coefficient vector. Every operation returns a new value in canonical form: no trailing zero coefficients, and the zero polynomial stored as an empty vector.

The type is re-exported by the [`immut`](../immut.md) facade as `@immut.DensePolynomial`, which the examples use. The algorithms and their costs are explained in the [immut/dense design](../../design/immut/dense.md).

## The type

### `DensePolynomial`

`DensePolynomial[A]` represents $c_0 + c_1 x + \dots + c_{n-1} x^{n-1}$ by the coefficients `[c0, c1, ..., c(n-1)]` with $c_{n-1} \neq 0$.

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
pub impl[A] @core.HasDegree for DensePolynomial[A]
pub impl[A] @core.HasLength for DensePolynomial[A]
pub impl[A] @core.HasShape for DensePolynomial[A]
pub impl[A] @core.IsZero for DensePolynomial[A]
pub impl[A] @core.UnivariatePolynomial for DensePolynomial[A]
```

Each operation asks only for the coefficient capabilities it uses: addition needs `Eq + AddMonoid`, negation `Eq + Zero + Neg`, multiplication `Eq + AddMonoid + Mul`, and so on. `Eq` and `Zero` are needed whenever a result has to be trimmed.

## Construction

### `DensePolynomial::from_coefficients`

Builds the polynomial with the given ascending coefficients, dropping trailing zeros. The array is copied.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::from_coefficients(Array[A]) -> Self[A]
```

### `DensePolynomial::constant`

Builds the constant polynomial $c$; `constant(0)` is the zero polynomial.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::constant(A) -> Self[A]
```

### `DensePolynomial::variable`

Builds the polynomial $x$.

```mbti
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] DensePolynomial::variable() -> Self[A]
```

### `DensePolynomial::monomial`

Builds $c\,x^k$ from `power` $k$ and `coefficient` $c$. A zero coefficient gives the zero polynomial; a negative power aborts.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::monomial(Int, A) -> Self[A]
```

### `DensePolynomial::monomial_checked`

Like `monomial`, but returns `None` for a negative power.

```mbti
pub fn[A : Eq + @luna-generic.Zero] DensePolynomial::monomial_checked(Int, A) -> Self[A]?
```

### `DensePolynomial::zero`, `DensePolynomial::one`

The additive and multiplicative identities, also available through `Zero::zero()` and `One::one()`. If the coefficient type has $1 = 0$, `one()` is the zero polynomial.

```mbti
pub fn[A] DensePolynomial::zero() -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] DensePolynomial::one() -> Self[A]
```

```moonbit
test "construction" {
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3, 0, 0])
  debug_inspect(p.to_coefficients(), content="[1, 2, 3]")
  let x : @immut.DensePolynomial[Int] = @immut.DensePolynomial::variable()
  inspect(x, content="1x^1")
  inspect(@immut.DensePolynomial::monomial(3, 5), content="5x^3")
  assert_true(@immut.DensePolynomial::monomial_checked(-1, 5) is None)
  let zero : @immut.DensePolynomial[Int] = @immut.DensePolynomial::zero()
  assert_true(@immut.DensePolynomial::constant(0) == zero)
}
```

## Queries

### `DensePolynomial::to_coefficients`

Returns a fresh array of the canonical coefficients, lowest degree first; `[]` for zero.

```mbti
pub fn[A] DensePolynomial::to_coefficients(Self[A]) -> Array[A]
```

### `DensePolynomial::length`

Returns the number of stored coefficients, which is the degree plus one, or `0` for zero.

```mbti
pub fn[A] DensePolynomial::length(Self[A]) -> Int
```

### `DensePolynomial::degree`

Returns `Some(length() - 1)`, or `None` for the zero polynomial.

```mbti
pub fn[A] DensePolynomial::degree(Self[A]) -> Int?
```

### `DensePolynomial::is_zero`

Returns `true` for the zero polynomial.

```mbti
pub fn[A] DensePolynomial::is_zero(Self[A]) -> Bool
```

### `DensePolynomial::coefficient`

Returns the coefficient of $x^k$; powers beyond the degree read as zero. A negative power aborts.

```mbti
pub fn[A : @luna-generic.Zero] DensePolynomial::coefficient(Self[A], Int) -> A
```

### `DensePolynomial::coefficient_checked`

Returns `None` for a negative power and `Some(coefficient(k))` otherwise.

```mbti
pub fn[A : @luna-generic.Zero] DensePolynomial::coefficient_checked(Self[A], Int) -> A?
```

### `DensePolynomial::leading_term`, `DensePolynomial::leading_coefficient`

`leading_term` returns `(degree, coefficient)` of the highest non-zero term, `leading_coefficient` just the coefficient; both are `None` for zero.

```mbti
pub fn[A] DensePolynomial::leading_term(Self[A]) -> (Int, A)?
pub fn[A] DensePolynomial::leading_coefficient(Self[A]) -> A?
```

### `DensePolynomial::shape`

Returns `PolynomialShape::Univariate(length~)`.

```mbti
pub fn[A] DensePolynomial::shape(Self[A]) -> @core.PolynomialShape
```

```moonbit
test "queries" {
  let p = @immut.DensePolynomial::from_coefficients([4, 0, -1])
  inspect(p.length(), content="3")
  debug_inspect(p.degree(), content="Some(2)")
  inspect(p.coefficient(1), content="0")
  inspect(p.coefficient(9), content="0")
  assert_true(p.coefficient_checked(-1) is None)
  debug_inspect(p.leading_term(), content="Some((2, -1))")
  let zero : @immut.DensePolynomial[Int] = @immut.DensePolynomial::zero()
  debug_inspect(zero.degree(), content="None")
  assert_true(zero.is_zero())
}
```

## Arithmetic

### `DensePolynomial::add`, `DensePolynomial::sub`, `DensePolynomial::neg`

Coefficient-wise addition, subtraction and negation, the operators `+`, `-` and unary `-`. The result is trimmed, so cancelling leading terms lowers the degree. Cost $O(\max(m, n))$ for operands of lengths $m$ and $n$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] DensePolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] DensePolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] DensePolynomial::neg(Self[A]) -> Self[A]
```

### `DensePolynomial::mul`

Multiplies by the schoolbook convolution $(fg)_k = \sum_{i+j=k} f_i g_j$, the operator `*`. Cost $O(mn)$ coefficient multiplications.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] DensePolynomial::mul(Self[A], Self[A]) -> Self[A]
```

### `DensePolynomial::karatsuba`

Multiplies with Karatsuba's divide-and-conquer algorithm. The result equals `self * other`. When the shorter operand has at most 32 coefficients it falls back to `*`; above that the cost is $O(n^{\log_2 3}) \approx O(n^{1.585})$ for operands of length $n$. It needs `Neg` because the middle product is formed by subtraction.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + Neg + @luna-generic.One] DensePolynomial::karatsuba(Self[A], Self[A]) -> Self[A]
```

### `DensePolynomial::scale`

Returns $c\,x^k \cdot p$: shifts the coefficients up by `power` $k$ and multiplies them by `coefficient` $c$. A negative power aborts; a zero coefficient gives zero.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] DensePolynomial::scale(Self[A], Int, A) -> Self[A]
```

### `DensePolynomial::scale_checked`

Like `scale`, but returns `None` for a negative power.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] DensePolynomial::scale_checked(Self[A], Int, A) -> Self[A]?
```

### `DensePolynomial::pow`

Returns $p^e$ by binary exponentiation, with at most $2\lfloor \log_2 e \rfloor + 1$ multiplications. `pow(0)` is `one()`, also for the zero polynomial.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] DensePolynomial::pow(Self[A], UInt) -> Self[A]
```

The same function is available as `@arithmetic.PowNatChecked::pow_nat_checked(p, e, context)`, which always returns `Ok` and ignores the context.

```moonbit
test "arithmetic" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let q = @immut.DensePolynomial::from_coefficients([1, -1])
  inspect(p + q, content="2")
  inspect(p * q, content="1 + -1x^2")
  inspect(p - p, content="0")
  inspect(p.scale(2, 3), content="3x^2 + 3x^3")
  assert_true(p.scale_checked(-1, 3) is None)
  inspect(p.pow(3), content="1 + 3x^1 + 3x^2 + 1x^3")
  let big = @immut.DensePolynomial::from_coefficients(Array::makei(40, i => i % 3 - 1))
  assert_true(big.karatsuba(big) == big * big)
}
```

## Evaluation and calculus

### `DensePolynomial::eval`

Evaluates $p(a)$ with Horner's rule, $(\cdots((c_{n-1} a + c_{n-2}) a + c_{n-3}) \cdots) a + c_0$: $n$ multiplications and $n$ additions for $n$ coefficients.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul] DensePolynomial::eval(Self[A], A) -> A
```

### `DensePolynomial::substitute`

Returns the composition $p(q)$, replacing $x$ by the polynomial $q$, with Horner's rule over polynomials.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] DensePolynomial::substitute(Self[A], Self[A]) -> Self[A]
```

### `DensePolynomial::derivative`

Returns the formal derivative $\sum_{i \ge 1} i\,c_i\,x^{i-1}$. The factor $i$ is mapped into the coefficient type with `@luna-generic.NatHomomorphism::from_nat`, so in characteristic $p$ the derivative of $x^p$ is zero. `luna-generic` implements `NatHomomorphism` for `Float`, `Double` and `BigInt`, so those are the coefficient types with a derivative; `Int` coefficients have none.

```mbti
pub fn[A : @luna-generic.NatHomomorphism + Eq + @luna-generic.Zero + Mul] DensePolynomial::derivative(Self[A]) -> Self[A]
```

```moonbit
test "evaluation and calculus" {
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  inspect(p.eval(2), content="17")
  let shift = @immut.DensePolynomial::from_coefficients([1, 1])
  inspect(p.substitute(shift), content="6 + 8x^1 + 3x^2")
  let f = @immut.DensePolynomial::from_coefficients([5.0, 0.0, 1.0, 2.0])
  debug_inspect(f.derivative().to_coefficients(), content="[0, 2, 6]")
}
```

## Comparison and printing

### `DensePolynomial::equal`

Structural equality of canonical coefficient vectors, which is equality of polynomials. It is `==`.

```mbti
pub fn[A : Eq] DensePolynomial::equal(Self[A], Self[A]) -> Bool
```

### `DensePolynomial::compare`

A structural total order for sorted containers: shorter (lower-degree) polynomials first, then coefficient by coefficient from the constant term up. It is not compatible with the ring operations.

```mbti
pub fn[A : Compare] DensePolynomial::compare(Self[A], Self[A]) -> Int
```

### `DensePolynomial::to_string`

Renders the non-zero terms in ascending degree as `c` for the constant term and `cx^k` otherwise, joined by ` + `; zero prints as the coefficient zero.

```mbti
pub fn[A : Show + Eq + @luna-generic.Zero] DensePolynomial::to_string(Self[A]) -> String
```

```moonbit
test "comparison and printing" {
  let a = @immut.DensePolynomial::from_coefficients([9])
  let b = @immut.DensePolynomial::from_coefficients([0, 1])
  assert_true(a < b)
  inspect(@immut.DensePolynomial::from_coefficients([0, -2, 0, 1]), content="-2x^1 + 1x^3")
}
```

## Generic access

### `DensePolynomial::ops`

Returns the [`UnivariateOps`](../core.md#univariateops) record of this type, wiring `zero`, `one`, `from_coefficients`, `to_coefficients`, `coefficient`, `coefficient_checked`, `eval`, `+`, `*`, `scale`, `scale_checked` and `pow`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] DensePolynomial::ops() -> @core.UnivariateOps[Self[A], A]
```

```moonbit
test "ops" {
  let ops = @immut.DensePolynomial::ops()
  let p = ops.from_coefficients([1, 1])
  inspect(ops.eval(ops.mul(p, p), 3), content="16")
}
```

## Deprecated

These method forms come from trait implementations. They are hidden from the interface file and kept for source compatibility only.

| Deprecated | Replacement |
| --- | --- |
| `p.not_equal(q)` | `p != q` |
| `p.op_lt(q)`, `op_le`, `op_gt`, `op_ge` | `<`, `<=`, `>`, `>=` |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
| `p.pow_nat_checked(e, ctx)` | `@arithmetic.PowNatChecked::pow_nat_checked(p, e, ctx)` or `p.pow(e)` |
