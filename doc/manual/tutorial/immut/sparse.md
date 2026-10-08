# immut/sparse tutorial

This tutorial shows how to use `SparsePolynomial` when you need to look up individual coefficients of a multivariate polynomial: build one, query coefficients by exponent vector, add terms, compute and evaluate.

| I want to | Use |
| --- | --- |
| build a sparse polynomial | `SparsePolynomial::from_array` or `from_terms` |
| read the coefficient of $x^\alpha$ | `get` (`None` means zero) |
| add one term and get a new polynomial | `add_term` |
| add, multiply, evaluate | `+`, `*`, `eval`, `eval_checked` |
| find the leading term | the last element of `to_terms()` |
| switch to sorted-array storage | `TermPolynomial::from_terms(p.to_terms())` |
| accumulate many terms quickly | the mutable [`SparsePolynomial`](../mutable/sparse.md) |

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

```moonbit
test "sparse quick start" {
  let p = @immut.SparsePolynomial::from_array([([2U], 1), ([1U], 2), ([], 1)])
  inspect(p, content="1 + 2 * x + 1 * x^2")
  debug_inspect(p.get(@immut.ExponentVector::from_array([1U])), content="Some(2)")
}
```

`p` is $x^2 + 2x + 1$; `get` reads the coefficient of $x^1$. Sparse polynomials print in ascending order, constant term first.

## Everyday tasks

### Look up coefficients

`get` returns `None` for a monomial that does not occur, which means its coefficient is zero:

```moonbit
fn coefficient_or_zero(p : @immut.SparsePolynomial[Int], exponents : Array[UInt]) -> Int {
  p.get(@immut.ExponentVector::from_array(exponents)).unwrap_or(0)
}

test "lookup" {
  let p = @immut.SparsePolynomial::from_array([([1U, 1], 6), ([0U, 3], -1)])
  inspect(coefficient_or_zero(p, [1, 1]), content="6")
  inspect(coefficient_or_zero(p, [0, 3]), content="-1")
  inspect(coefficient_or_zero(p, [5]), content="0")
}
```

### Add terms one at a time

`add_term` returns a new polynomial; terms that cancel disappear:

```moonbit
test "add term" {
  let x2 = @immut.ExponentVector::from_array([2U])
  let p = @immut.SparsePolynomial::new().add_term(x2, 3).add_term(@immut.ExponentVector::one(), 1)
  inspect(p, content="1 + 3 * x^2")
  let q = p.add_term(x2, -3)
  inspect(q, content="1")
  inspect(p.size(), content="2")
}
```

Each `add_term` rebuilds the map. For many single-term updates, build an array of terms and call `from_terms` once, or use [`mutable/sparse`](../mutable/sparse.md).

### Compute and evaluate

```moonbit
test "compute" {
  let x = @immut.SparsePolynomial::from_array([([1U], 1)])
  let y = @immut.SparsePolynomial::from_array([([0U, 1], 1)])
  let p = (x * y + x).pow(2)
  inspect(p, content="1 * x^2 + 2 * x^2x_1 + 1 * x^2x_1^2")
  inspect(p.eval([2, 3]), content="64")
  assert_true(p.eval_checked([2]) is None)
}
```

$(xy + x)^2$ at $(2, 3)$ is $(6 + 2)^2 = 64$. `eval_checked` returns `None` because `p` uses two variables and only one value was given.

### Find the leading term

The map is ascending, so the leading term is the last entry:

```moonbit
test "leading term" {
  let p = @immut.SparsePolynomial::from_array([([], 5), ([1U, 1], 2), ([3U], 1)])
  let terms = p.to_terms()
  let (lead, coeff) = terms[terms.length() - 1]
  inspect(lead, content="x^3")
  inspect(coeff, content="1")
}
```

## Going further

### Coefficient extraction in algorithms

A common pattern is to read the coefficients of a fixed set of monomials, for example the linear part:

```moonbit
fn linear_part(p : @immut.SparsePolynomial[Int], variables : Int) -> Array[Int] {
  Array::makei(variables, i => {
    let e = @immut.ExponentVector::one().with_exponent(i, 1)
    p.get(e).unwrap_or(0)
  })
}

test "linear part" {
  let p = @immut.SparsePolynomial::from_array([([1U], 3), ([0U, 0, 1], -2), ([1U, 1], 9), ([], 4)])
  debug_inspect(linear_part(p, 3), content="[3, 0, -2]")
}
```

### Agreement with term storage

Sparse and term polynomials built from the same terms are the same polynomial; only the iteration order differs:

```moonbit
test "agreement" {
  let terms = [([2U], 1), ([1U, 1], 3), ([], 4)]
  let s = @immut.SparsePolynomial::from_array(terms)
  let t = @immut.TermPolynomial::from_array(terms)
  assert_true(@immut.TermPolynomial::from_terms(s.to_terms()) == t)
  inspect(s.eval([1, 2]) == t.eval([1, 2]), content="true")
}
```

### Polynomials over other coefficient types

Any coefficient type with the `luna-generic` capabilities works, for example `Double`:

```moonbit
test "double coefficients" {
  let p = @immut.SparsePolynomial::from_array([([2U], 0.5), ([], -1.0)])
  inspect(p.eval([2.0]), content="1")
}
```

## Common pitfalls

- **Ascending order.** `to_terms()` and printing start with the constant term; `TermPolynomial` starts with the leading term.
- **Keys are canonical.** `[1, 0]` and `[1]` are the same key, so both look up the coefficient of $x_0$.
- **`get_checked` is `get`.** It never fails differently; use `get(...).unwrap_or(0)` to read a coefficient as a number.
- **Rebuilding cost.** `add_term` is $O(m \log m)$ per call in the immutable type.

## Next steps

- The [immut/sparse API](../../api/immut/sparse.md) lists every method.
- The [immut/sparse design](../../design/immut/sparse.md) compares the two multivariate representations.
- For in-place updates, see the [mutable/sparse tutorial](../mutable/sparse.md); for named variables, the [context tutorial](context.md).
