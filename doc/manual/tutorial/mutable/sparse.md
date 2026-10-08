# mutable/sparse tutorial

This tutorial shows how to use the mutable `SparsePolynomial` as an accumulator: set and add coefficients by exponent vector in logarithmic time, expand products term by term, and freeze the result.

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

```text
import {
  "Luna-Flow/luna-poly/mutable",
}
```

```moonbit
test "mutable sparse quick start" {
  let x = @mutable.ExponentVector::from_array([1U])
  let p : @mutable.SparsePolynomial[Int] = @mutable.SparsePolynomial::new()
  p.set_coefficient(x, 3)
  p.add_term_inplace(x, -1)
  debug_inspect(p.get(x), content="Some(2)")
}
```

## Everyday tasks

### Count monomials

Use the polynomial as a multiset of monomials: every occurrence adds one to its coefficient.

```moonbit
test "counting" {
  let words = [[1U], [0U, 1], [1U], [1U, 0], [0U, 2]]
  let counts : @mutable.SparsePolynomial[Int] = @mutable.SparsePolynomial::new()
  for w in words {
    counts.add_term_inplace(@mutable.ExponentVector::from_array(w), 1)
  }
  inspect(counts, content="3 * x + 1 * x_1 + 1 * x_1^2")
}
```

`[1]` and `[1, 0]` are the same monomial, so $x$ is counted three times.

### Expand a product term by term

```moonbit
test "expansion" {
  let a = @mutable.SparsePolynomial::from_array([([1U], 1), ([0U, 1], 1)])
  let b = @mutable.SparsePolynomial::from_array([([1U], 1), ([0U, 1], -1)])
  let out : @mutable.SparsePolynomial[Int] = @mutable.SparsePolynomial::new()
  for ta in a.to_terms() {
    for tb in b.to_terms() {
      out.add_term_inplace(ta.0 * tb.0, ta.1 * tb.1)
    }
  }
  inspect(out, content="1 * x^2 + -1 * x_1^2")
  assert_true(out == a * b)
}
```

The cross terms $xy - xy$ cancel during accumulation and never stay in the map.

### Remove and replace terms

```moonbit
test "set and remove" {
  let p = @mutable.SparsePolynomial::from_array([([2U], 4), ([], 1)])
  p.set_coefficient(@mutable.ExponentVector::from_array([2U]), 0)
  inspect(p, content="1")
  p.set_coefficient(@mutable.ExponentVector::from_array([0U, 3]), 7)
  inspect(p, content="1 + 7 * x_1^3")
}
```

## Going further

### Freeze for sharing

```moonbit
test "freeze" {
  let p = @mutable.SparsePolynomial::from_array([([1U], 2)])
  let frozen = p.to_immut()
  p.add_term_inplace(@mutable.ExponentVector::one(), 9)
  inspect(frozen, content="2 * x")
  inspect(p, content="9 + 2 * x")
}
```

### Generic accumulation

`MutablePolynomial` code can reset and copy any mutable container:

```moonbit
fn[P : @mutable.MutablePolynomial] reset_copy(p : P) -> P {
  let snapshot = @mutable.Copyable::copy(p)
  @mutable.Clearable::clear(p)
  snapshot
}

test "generic" {
  let p = @mutable.SparsePolynomial::from_array([([1U], 5)])
  let before = reset_copy(p)
  inspect(before, content="5 * x")
  assert_true(p.is_zero())
}
```

## Common pitfalls

- **`copy` cost.** Copying rebuilds the tree, $O(m \log m)$.
- **Bounds on `copy`.** It needs `Eq + AddMonoid` coefficients, so generic code bounded only by `MutablePolynomial` works for sparse polynomials only with such coefficients.
- **Ascending order.** Printing and `to_terms` start with the constant term.

## Next steps

- The [mutable/sparse API](../../api/mutable/sparse.md) and [mutable/sparse design](../../design/mutable/sparse.md).
- The [immut/sparse tutorial](../immut/sparse.md) for lookup patterns, and [mutable/context](context.md) for named variables.
