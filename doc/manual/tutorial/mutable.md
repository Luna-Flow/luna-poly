# mutable tutorial

This tutorial is the entry point for updating polynomials in place. It shows the one import you need, how mutation differs from the operators, how to move between the mutable and immutable layers, and where each representation's tutorial continues.

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
test "mutable quick start" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  let snapshot = p.copy()
  p.set_coefficient(1, 5)
  p.add_inplace(@mutable.DensePolynomial::from_coefficients([-1, -5, -3]))
  assert_true(p.is_zero())
  inspect(snapshot, content="1 + 2x^1 + 3x^2")
}
```

`set_coefficient` and `add_inplace` change `p`; the copy taken before is unaffected.

## Everyday tasks

### Pick a container

| You want to | Use | Tutorial |
| --- | --- | --- |
| set and accumulate univariate coefficients | `DensePolynomial` | [mutable/dense](mutable/dense.md) |
| keep multivariate terms sorted while adding | `TermPolynomial` | [mutable/term](mutable/term.md) |
| add or set multivariate terms in $O(\log m)$ | `SparsePolynomial` | [mutable/sparse](mutable/sparse.md) |
| accumulate polynomials in named variables | `ContextPolynomial` | [mutable/context](mutable/context.md) |

### Know what mutates

Methods ending in `_inplace`, the setters and `clear` mutate; operators never do:

```moonbit
test "what mutates" {
  let p = @mutable.SparsePolynomial::from_array([([1U], 1)])
  let q = p * p
  inspect(p, content="1 * x")
  p.mul_inplace(p)
  inspect(p, content="1 * x^2")
  assert_true(p == q)
}
```

### Cross the boundary to `immut`

Convert at module boundaries so that callers receive values:

```moonbit
fn build_power_sum(n : Int) -> @immut.DensePolynomial[Int] {
  let acc : @mutable.DensePolynomial[Int] = @mutable.DensePolynomial::zero()
  for k in 0..<n {
    acc.set_coefficient(k, 1)
  }
  acc.to_immut()
}

test "boundary" {
  inspect(build_power_sum(4), content="1 + 1x^1 + 1x^2 + 1x^3")
}
```

## Going further

### Generic code for both layers

The capability traits and operation records are the same for both facades:

```moonbit
fn[P, A] eval_square(ops : @mutable.UnivariateOps[P, A], p : P, a : A) -> A {
  ops.eval(ops.mul(p, p), a)
}

test "both layers" {
  inspect(eval_square(@mutable.DensePolynomial::ops(), @mutable.DensePolynomial::from_coefficients([1, 1]), 2), content="9")
  inspect(eval_square(@immut.DensePolynomial::ops(), @immut.DensePolynomial::from_coefficients([1, 1]), 2), content="9")
}
```

### Reset buffers generically

Every mutable container implements `MutablePolynomial` (`Clearable + Copyable`):

```moonbit
fn[P : @mutable.MutablePolynomial] fresh_copy_and_clear(p : P) -> P {
  let c = @mutable.Copyable::copy(p)
  @mutable.Clearable::clear(p)
  c
}

test "generic reset" {
  let t = @mutable.TermPolynomial::from_array([([2U], 1)])
  inspect(fresh_copy_and_clear(t), content="1 * x^2")
  assert_true(t.is_zero())
}
```

## Common pitfalls

- **Bindings share containers.** `let q = p` does not copy; use `p.copy()`.
- **Large additions into term arrays.** `TermPolynomial::add_inplace` inserts one term at a time; prefer sparse containers for accumulation.
- **Context mismatches abort** in `add_inplace` and `mul_inplace`; there are no checked in-place forms.
- **Mixing layers.** A `@mutable.DensePolynomial` is not an `@immut.DensePolynomial`; convert with `to_immut` / `from_immut`.

## Next steps

- The per-container tutorials linked above.
- The [mutable API](../api/mutable.md) and the [mutable design](../design/mutable.md), which lists every difference from `immut`.
- The [immut tutorial](immut.md) for the value-oriented layer.
