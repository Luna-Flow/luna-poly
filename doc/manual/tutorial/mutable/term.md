# mutable/term tutorial

This tutorial shows how to build a multivariate polynomial term by term in a mutable container that stays sorted and canonical, and when to prefer whole-polynomial operations instead.

| I want to | Use |
| --- | --- |
| collect terms from a loop | `add_term_inplace` |
| multiply or scale in place | `mul_inplace`, `scale_inplace` |
| add many terms at once | build an array and call `from_terms` once |
| evaluate the current value | `eval`, `eval_checked` |
| publish the result | `to_immut` |

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
test "mutable term quick start" {
  let p : @mutable.TermPolynomial[Int] = @mutable.TermPolynomial::zero()
  p.add_term_inplace(@mutable.ExponentVector::from_array([1U, 1]), 3)
  p.add_term_inplace(@mutable.ExponentVector::from_array([2U]), 1)
  inspect(p, content="3 * x * x_1 + 1 * x^2")
}
```

The container re-sorts after every insertion, so it always prints leading term first.

## Everyday tasks

### Collect terms from a loop

Terms with the same exponent vector merge, and terms that cancel disappear:

```moonbit
test "collect" {
  let p : @mutable.TermPolynomial[Int] = @mutable.TermPolynomial::zero()
  for i in 0..<4 {
    p.add_term_inplace(@mutable.ExponentVector::from_array([(i % 2).reinterpret_as_uint()]), 1)
  }
  inspect(p, content="2 * x + 2")
  p.add_term_inplace(@mutable.ExponentVector::one(), -2)
  inspect(p, content="2 * x")
}
```

### Multiply and scale in place

```moonbit
test "multiply" {
  let p = @mutable.TermPolynomial::from_array([([1U], 1), ([0U, 1], 1)])
  p.mul_inplace(p)
  inspect(p, content="1 * x_1^2 + 2 * x * x_1 + 1 * x^2")
  p.scale_inplace(@mutable.ExponentVector::from_array([0U, 0, 1]), -1)
  inspect(p.total_degree().unwrap(), content="3")
}
```

### Evaluate while building

Queries work at any point because the container is always canonical:

```moonbit
test "evaluate" {
  let p = @mutable.TermPolynomial::from_array([([2U], 1)])
  inspect(p.eval([3]), content="9")
  p.add_term_inplace(@mutable.ExponentVector::from_array([0U, 1]), 10)
  assert_true(p.eval_checked([3]) is None)
  inspect(p.eval([3, 1]), content="19")
}
```

After adding a term in $x_1$ the polynomial needs two values.

## Going further

### Large sums

`add_inplace` inserts terms one at a time. For large operands, build the sum once:

```moonbit
test "large sums" {
  let parts = Array::makei(50, i => @mutable.TermPolynomial::from_array([([i.reinterpret_as_uint()], 1)]))
  let all_terms : Array[(@mutable.ExponentVector, Int)] = []
  for part in parts {
    for t in part.to_terms() {
      all_terms.push(t)
    }
  }
  let sum = @mutable.TermPolynomial::from_terms(all_terms)
  inspect(sum.size(), content="50")
}
```

One `from_terms` normalizes all terms in $O(N \log N)$.

### Hand over to immutable code

```moonbit
test "freeze" {
  let p = @mutable.TermPolynomial::from_array([([1U], 2)])
  let frozen = p.to_immut()
  p.clear()
  inspect(frozen, content="2 * x")
  assert_true(p.is_zero())
}
```

## Common pitfalls

- **`add_inplace` cost.** It is roughly quadratic for large operands; see above.
- **Shared containers.** Assignment shares; use `copy()` for an independent container.
- **Order.** Like the immutable type, the order is graded with ties broken at the highest variable.

## Next steps

- The [mutable/term API](../../api/mutable/term.md) and [mutable/term design](../../design/mutable/term.md).
- The [immut/term tutorial](../immut/term.md) for the mathematics, and [mutable/sparse](sparse.md) for cheap single-term updates.
