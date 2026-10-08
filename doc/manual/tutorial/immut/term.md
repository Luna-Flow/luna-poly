# immut/term tutorial

This tutorial shows how to work with multivariate polynomials as sorted term lists: build them, read their terms in order, do arithmetic, evaluate them at a point, and write small algorithms that walk the terms.

| I want to | Use |
| --- | --- |
| build a multivariate polynomial | `TermPolynomial::from_array` or `from_terms` |
| read terms from the leading term down | `to_terms`, `coefficients` |
| add, subtract, multiply, raise to a power | `+`, `-`, `*`, `pow` |
| evaluate without aborting on missing values | `eval_checked` |
| multiply by a monomial $c\,x^\gamma$ | `scale` |
| ask for the number of variables, terms or the degree | `arity`, `size`, `total_degree` |
| look up coefficients by exponent | convert to `SparsePolynomial` |
| use names instead of indexes | `ContextPolynomial` |

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
test "term quick start" {
  let p = @immut.TermPolynomial::from_array([([2U], 1), ([1U, 1], 3), ([], 4)])
  inspect(p, content="3 * xx_1 + 1 * x^2 + 4")
  inspect(p.eval([2, 5]), content="38")
}
```

Each term is `(exponents, coefficient)`: `[1, 1]` is $x_0 x_1$, so `p` is $x_0^2 + 3x_0x_1 + 4$, and $p(2, 5) = 4 + 30 + 4 = 38$. Variable $x_0$ prints as `x` and $x_i$ as `x_i`.

## Everyday tasks

### Build from terms

Give terms in any order, with repeats; the constructor sorts, merges and drops zeros:

```moonbit
test "building" {
  let p = @immut.TermPolynomial::from_array([
    ([1U], 2),
    ([0U, 1], 5),
    ([1U, 0, 0], 3),
    ([0U, 1], -5),
  ])
  inspect(p, content="5 * x")
  let v = @immut.ExponentVector::from_array([0U, 0, 2])
  let q = @immut.TermPolynomial::from_terms([(v, 1), (@immut.ExponentVector::one(), -1)])
  inspect(q, content="1 * x_2^2 + -1")
}
```

`from_terms` takes ready-made `ExponentVector` keys; `from_array` builds them for you.

### Read terms in order

Terms come out leading term first, in graded order:

```moonbit
test "reading terms" {
  let p = @immut.TermPolynomial::from_array([([], 1), ([1U], 1), ([0U, 1], 1), ([2U], 1)])
  let (lead, coeff) = p.to_terms()[0]
  inspect(lead, content="x^2")
  inspect(coeff, content="1")
  inspect(p.to_terms().map(t => t.0.to_string()).join(", "), content="x^2, x_1, x, 1")
  inspect(p.size(), content="4")
  debug_inspect(p.total_degree(), content="Some(2)")
}
```

Higher total degree comes first; within a degree, the higher-indexed variable wins, so $x_1$ comes before $x_0$.

### Compute with polynomials

```moonbit
test "arithmetic" {
  let x = @immut.TermPolynomial::from_array([([1U], 1)])
  let y = @immut.TermPolynomial::from_array([([0U, 1], 1)])
  let one : @immut.TermPolynomial[Int] = @immut.TermPolynomial::one()
  let p = (x + y + one).pow(2)
  inspect(p.size(), content="6")
  inspect(p.eval([1, 1]), content="9")
  inspect(p - p, content="0")
}
```

$(x_0 + x_1 + 1)^2$ has six terms and evaluates to $3^2 = 9$ at $(1, 1)$.

### Evaluate safely

`eval` needs a value for every variable the polynomial uses, that is at least `arity()` values:

```moonbit
test "evaluation" {
  let p = @immut.TermPolynomial::from_array([([0U, 0, 1], 2), ([], 1)])
  inspect(p.arity(), content="3")
  assert_true(p.eval_checked([1, 1]) is None)
  debug_inspect(p.eval_checked([0, 0, 5]), content="Some(11)")
}
```

Use `eval_checked` when the point comes from user input; `eval` aborts on a short array.

### Multiply by a monomial

`scale(γ, c)` multiplies by $c\,x^\gamma$ in one linear pass:

```moonbit
test "scale" {
  let p = @immut.TermPolynomial::from_array([([1U], 1), ([], 1)])
  let shifted = p.scale(@immut.ExponentVector::from_array([0U, 2]), 4)
  inspect(shifted, content="4 * xx_1^2 + 4 * x_1^2")
}
```

## Going further

### Walk the terms

Because terms are a plain sorted list, many algorithms are a filter or a fold. Here is the homogeneous part of a given degree:

```moonbit
fn[A : Eq + @immut.AddMonoid] homogeneous_part(
  p : @immut.TermPolynomial[A],
  degree : UInt,
) -> @immut.TermPolynomial[A] {
  @immut.TermPolynomial::from_terms(p.to_terms().filter(t => t.0.degree() == degree))
}

test "homogeneous part" {
  let p = @immut.TermPolynomial::from_array([([2U], 1), ([1U, 1], 3), ([1U], 7), ([], 4)])
  inspect(homogeneous_part(p, 2), content="3 * xx_1 + 1 * x^2")
  inspect(homogeneous_part(p, 5), content="0")
}
```

### Switch to map storage

Convert through the term list when you need lookup by exponent:

```moonbit
test "to sparse" {
  let t = @immut.TermPolynomial::from_array([([1U, 1], 3), ([], 4)])
  let s = @immut.SparsePolynomial::from_terms(t.to_terms())
  debug_inspect(s.get(@immut.ExponentVector::from_array([1U, 1])), content="Some(3)")
}
```

### Generic code

Accept `MultivariateOps` to stay independent of the storage:

```moonbit
fn[P, A] value_of_square(ops : @immut.MultivariateOps[P, A], p : P, at : Array[A]) -> A {
  ops.eval_indexed(ops.mul(p, p), at)
}

test "generic" {
  let terms = [([1U], 1), ([0U, 1], 1)]
  let t = @immut.TermPolynomial::from_array(terms)
  let s = @immut.SparsePolynomial::from_array(terms)
  inspect(value_of_square(@immut.TermPolynomial::ops(), t, [1, 2]), content="9")
  inspect(value_of_square(@immut.SparsePolynomial::ops(), s, [1, 2]), content="9")
}
```

### Named variables and substitution

`TermPolynomial` addresses variables by position and has no substitution. Wrap it in a [`ContextPolynomial`](context.md) to name the variables and substitute them:

```moonbit
test "with names" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let t = @immut.TermPolynomial::from_array([([1U, 1], 2)])
  let p = @immut.ContextPolynomial::from_term_polynomial(ctx, t)
  inspect(p, content="2 * x * y")
}
```

## Common pitfalls

- **`UInt` literals.** Exponent arrays are `Array[UInt]`; write the first element as `1U` so the literal is typed correctly.
- **Trailing zeros do not add variables.** `[1, 0, 0]` is $x_0$, and its arity is `1`, not `3`.
- **Order is graded, not lexicographic.** $x_1$ comes before $x_0$, and $x_0^2$ before both.
- **Printed monomials have no separator.** `xx_1` means $x_0 x_1$.
- **Large products.** `*` materializes all $mn$ products before merging; for very large sparse inputs that costs memory.

## Next steps

- The [immut/term API](../../api/immut/term.md) lists every method with its cost.
- The [immut/term design](../../design/immut/term.md) explains the canonical form and why the leading term is multiplicative.
- The [sparse tutorial](sparse.md) covers map storage, and the [mutable/term tutorial](../mutable/term.md) in-place updates.
