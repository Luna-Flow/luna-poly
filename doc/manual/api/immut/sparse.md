# immut/sparse API

`Luna-Flow/luna-poly/immut/sparse` provides `SparsePolynomial[A]`, an immutable multivariate polynomial stored as an ordered map from `ExponentVector` to non-zero coefficients. It describes the same polynomials as [`TermPolynomial`](term.md) but supports lookup of a single coefficient in logarithmic time.

The type is re-exported by the [`immut`](../immut.md) facade as `@immut.SparsePolynomial`, which the examples use. Variables are addressed by index. The design is explained in the [immut/sparse design](../../design/immut/sparse.md).

## The type

### `SparsePolynomial`

`SparsePolynomial[A]` maps each exponent vector $\alpha$ with $c_\alpha \neq 0$ to $c_\alpha$. Keys are ordered by the [monomial order](../../design/core.md#the-monomial-order), and the map is iterated in *ascending* order.

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
pub impl[A] @core.HasArity for SparsePolynomial[A]
pub impl[A] @core.HasShape for SparsePolynomial[A]
pub impl[A] @core.HasTermCount for SparsePolynomial[A]
pub impl[A] @core.HasTotalDegree for SparsePolynomial[A]
pub impl[A] @core.IsZero for SparsePolynomial[A]
pub impl[A] @core.MultivariatePolynomial for SparsePolynomial[A]
```

## Construction

### `SparsePolynomial::new`, `SparsePolynomial::zero`

Both return the empty map, the zero polynomial; `zero` is also `Zero::zero()`.

```mbti
pub fn[A] SparsePolynomial::new() -> Self[A]
pub fn[A] SparsePolynomial::zero() -> Self[A]
```

### `SparsePolynomial::one`

Returns the constant $1$, or the zero polynomial if $1 = 0$ in `A`; also `One::one()`.

```mbti
pub fn[A : Eq + @luna-generic.Zero + @luna-generic.One] SparsePolynomial::one() -> Self[A]
```

### `SparsePolynomial::from_terms`

Builds the polynomial of a list of terms, adding coefficients of equal exponent vectors and dropping zero sums. The input is copied. Cost $O(m \log m)$ comparisons.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::from_terms(Array[(@core.ExponentVector, A)]) -> Self[A]
```

### `SparsePolynomial::from_array`

Like `from_terms`, with each exponent vector given as an `Array[UInt]`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::from_array(Array[(Array[UInt], A)]) -> Self[A]
```

### `SparsePolynomial::add_term`

Returns a new polynomial with $c\,x^\alpha$ added; a coefficient that becomes zero removes the key. The receiver is unchanged. The whole map is rebuilt, so the cost is $O(m \log m)$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::add_term(Self[A], @core.ExponentVector, A) -> Self[A]
```

```moonbit
test "construction" {
  let p = @immut.SparsePolynomial::from_array([([2U], 1), ([1U], 2), ([], 1), ([1U, 0], -2)])
  inspect(p, content="1 + 1 * x^2")
  let q = p.add_term(@immut.ExponentVector::from_array([2U]), -1)
  inspect(q, content="1")
  inspect(p, content="1 + 1 * x^2")
}
```

## Queries

### `SparsePolynomial::get`

Returns the coefficient of $x^\alpha$, or `None` when the term is absent (its coefficient is zero). Cost $O(\log m)$ comparisons.

```mbti
pub fn[A] SparsePolynomial::get(Self[A], @core.ExponentVector) -> A?
```

### `SparsePolynomial::get_checked`

Same as `get`. Every exponent vector is a valid key, so there is no extra failure case; the name exists for symmetry with the other checked APIs.

```mbti
pub fn[A] SparsePolynomial::get_checked(Self[A], @core.ExponentVector) -> A?
```

### `SparsePolynomial::to_terms`

Returns the terms as a fresh array in ascending monomial order, the constant term (if any) first. This is the reverse of `TermPolynomial::to_terms`.

```mbti
pub fn[A] SparsePolynomial::to_terms(Self[A]) -> Array[(@core.ExponentVector, A)]
```

### `SparsePolynomial::size`, `SparsePolynomial::term_count`

Both return the number of stored (non-zero) terms.

```mbti
pub fn[A] SparsePolynomial::size(Self[A]) -> Int
pub fn[A] SparsePolynomial::term_count(Self[A]) -> Int
```

### `SparsePolynomial::is_empty`, `SparsePolynomial::is_zero`

Both return `true` for the zero polynomial.

```mbti
pub fn[A] SparsePolynomial::is_empty(Self[A]) -> Bool
pub fn[A] SparsePolynomial::is_zero(Self[A]) -> Bool
```

### `SparsePolynomial::arity`, `SparsePolynomial::total_degree`, `SparsePolynomial::shape`

The number of variables in use, the largest term degree (`None` for zero), and `PolynomialShape::Multivariate(arity~, term_count~)`.

```mbti
pub fn[A] SparsePolynomial::arity(Self[A]) -> Int
pub fn[A] SparsePolynomial::total_degree(Self[A]) -> UInt?
pub fn[A] SparsePolynomial::shape(Self[A]) -> @core.PolynomialShape
```

```moonbit
test "queries" {
  let p = @immut.SparsePolynomial::from_array([([1U, 1], 3), ([2U], 1), ([], 4)])
  debug_inspect(p.get(@immut.ExponentVector::from_array([1U, 1])), content="Some(3)")
  debug_inspect(p.get(@immut.ExponentVector::from_array([0U, 2])), content="None")
  inspect(p.to_terms().map(t => t.0.to_string()).join(", "), content="1, x^2, xx_1")
  inspect(p.arity(), content="2")
  debug_inspect(p.total_degree(), content="Some(2)")
}
```

## Arithmetic

### `SparsePolynomial::add`, `SparsePolynomial::sub`, `SparsePolynomial::neg`

The operators `+`, `-` and unary `-`. Addition collects both term lists and rebuilds the map, $O((m+n)\log(m+n))$; negation is $O(m \log m)$ map insertions.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] SparsePolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] SparsePolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] SparsePolynomial::neg(Self[A]) -> Self[A]
```

### `SparsePolynomial::mul`

Forms all $mn$ term products and rebuilds the map, the operator `*`. Cost $O(mn \log(mn))$.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] SparsePolynomial::mul(Self[A], Self[A]) -> Self[A]
```

### `SparsePolynomial::scale`

Returns $c\,x^\gamma \cdot p$, dropping products that vanish.

```mbti
pub fn[A : Eq + @luna-generic.Zero + Mul] SparsePolynomial::scale(Self[A], @core.ExponentVector, A) -> Self[A]
```

### `SparsePolynomial::pow`

Returns $p^e$ by binary exponentiation; `pow(0)` is `one()`. Also available through `@arithmetic.PowNatChecked`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::pow(Self[A], UInt) -> Self[A]
```

```moonbit
test "arithmetic" {
  let p = @immut.SparsePolynomial::from_array([([1U], 1), ([0U, 1], -1)])
  inspect(p.pow(2), content="1 * x^2 + -2 * xx_1 + 1 * x_1^2")
  inspect(p - p, content="0")
  inspect(p.scale(@immut.ExponentVector::from_array([1U]), 2), content="2 * x^2 + -2 * xx_1")
}
```

## Evaluation

### `SparsePolynomial::eval`, `SparsePolynomial::eval_checked`

Evaluate at `values`, where `values[i]` is the value of variable $i$; at least `arity()` values are required. `eval` aborts on a shorter array, `eval_checked` returns `None`.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::eval(Self[A], Array[A]) -> A
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::eval_checked(Self[A], Array[A]) -> A?
```

```moonbit
test "evaluation" {
  let p = @immut.SparsePolynomial::from_array([([2U], 1), ([1U], 2), ([], 1)])
  inspect(p.eval([2]), content="9")
  assert_true(@immut.SparsePolynomial::from_array([([0U, 1], 1)]).eval_checked([1]) is None)
}
```

## Comparison and printing

### `SparsePolynomial::equal`

Compares the term lists, which is polynomial equality. It is `==`.

```mbti
pub fn[A : Eq] SparsePolynomial::equal(Self[A], Self[A]) -> Bool
```

### `SparsePolynomial::to_string`

Renders the terms in ascending order as `c * monomial` (just `c` for the constant term), joined by ` + `; zero prints as the coefficient zero.

```mbti
pub fn[A : Show + @luna-generic.Zero] SparsePolynomial::to_string(Self[A]) -> String
```

## Generic access

### `SparsePolynomial::ops`

Returns the [`MultivariateOps`](../core.md#multivariateops) record of this type; `eval_indexed` is `eval`.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] SparsePolynomial::ops() -> @core.MultivariateOps[Self[A], A]
```

```moonbit
test "ops" {
  let ops = @immut.SparsePolynomial::ops()
  let p = ops.add(ops.one(), ops.from_terms([(@immut.ExponentVector::from_array([0U, 1]), 3)]))
  inspect(ops.eval_indexed(p, [0, 2]), content="7")
}
```

## Converting to term storage

Go through the term list: `TermPolynomial::from_terms(sparse.to_terms())`. The conversion re-sorts into descending order.

## Deprecated

Hidden method forms kept for source compatibility:

| Deprecated | Replacement |
| --- | --- |
| `p.not_equal(q)` | `p != q` |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
| `p.pow_nat_checked(e, ctx)` | `@arithmetic.PowNatChecked::pow_nat_checked(p, e, ctx)` or `p.pow(e)` |
