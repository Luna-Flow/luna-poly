# mutable/dense tutorial

This tutorial shows how to build and update a univariate polynomial in place: set coefficients one at a time, accumulate sums and products into one container, keep snapshots, and hand the result back to immutable code.

| I want to | Use |
| --- | --- |
| set one coefficient | `set_coefficient` |
| add or multiply into an existing polynomial | `add_inplace`, `mul_inplace`, `scale_inplace` |
| keep the old value | `copy()` before mutating, or use the operators |
| hand the result to immutable code | `to_immut` |
| reuse the container | `clear` |

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.3.0
```

```text
import {
  "Luna-Flow/luna-poly/mutable",
}
```

```moonbit
test "mutable dense quick start" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  p.set_coefficient(1, 5)
  inspect(p, content="1 + 5x^1 + 3x^2")
}
```

`set_coefficient(1, 5)` changes the coefficient of $x$ in `p` itself.

## Everyday tasks

### Fill coefficients one at a time

Start from zero and set the coefficients you know; the array grows as needed:

```moonbit
test "filling" {
  let p : @mutable.DensePolynomial[Int] = @mutable.DensePolynomial::zero()
  for k in 0..<5 {
    p.set_coefficient(k, k * k)
  }
  inspect(p, content="1x^1 + 4x^2 + 9x^3 + 16x^4")
  p.set_coefficient(4, 0)
  debug_inspect(p.degree(), content="Some(3)")
}
```

Setting the leading coefficient to zero lowers the degree, because the polynomial stays canonical.

### Accumulate into one container

`add_inplace` and `mul_inplace` update the receiver, which keeps loops free of intermediate values:

```moonbit
test "accumulate" {
  let x_plus_1 = @mutable.DensePolynomial::from_coefficients([1, 1])
  let product : @mutable.DensePolynomial[Int] = @mutable.DensePolynomial::one()
  let sum : @mutable.DensePolynomial[Int] = @mutable.DensePolynomial::zero()
  for _ in 0..<3 {
    product.mul_inplace(x_plus_1)
    sum.add_inplace(product)
  }
  inspect(product, content="1 + 3x^1 + 3x^2 + 1x^3")
  inspect(sum, content="3 + 6x^1 + 4x^2 + 1x^3")
}
```

`sum` is $(x+1) + (x+1)^2 + (x+1)^3$.

### Keep a snapshot

`copy` and `to_immut` take independent snapshots before you mutate further:

```moonbit
test "snapshots" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 1])
  let saved = p.copy()
  let frozen = p.to_immut()
  p.scale_inplace(2, 10)
  inspect(p, content="10x^2 + 10x^3")
  inspect(saved, content="1 + 1x^1")
  inspect(frozen, content="1 + 1x^1")
}
```

### Operators do not mutate

Use operators when you want a new value; the operands stay as they are:

```moonbit
test "operators" {
  let p = @mutable.DensePolynomial::from_coefficients([1, 2])
  let q = p * p + p
  inspect(q, content="2 + 6x^1 + 4x^2")
  inspect(p, content="1 + 2x^1")
}
```

## Going further

### Build mutably, publish immutably

Do the incremental work in a mutable buffer and return an immutable value, so callers get value semantics:

```moonbit
fn truncated_exp_numerators(n : Int) -> @immut.DensePolynomial[Int] {
  // n! * (1 + x + x^2/2! + ... + x^n/n!)
  let buffer : @mutable.DensePolynomial[Int] = @mutable.DensePolynomial::zero()
  let mut falling = 1
  for k = n; k >= 0; k = k - 1 {
    buffer.set_coefficient(k, falling)
    falling = falling * (if k == 0 { 1 } else { k })
  }
  buffer.to_immut()
}

test "publish" {
  inspect(truncated_exp_numerators(3), content="6 + 6x^1 + 3x^2 + 1x^3")
}
```

### Generic code across both layers

The operation records and capability traits have the same shape for mutable and immutable types:

```moonbit
fn[P : @mutable.UnivariatePolynomial] is_linear(p : P) -> Bool {
  @mutable.HasDegree::degree(p) == Some(1)
}

test "generic" {
  inspect(is_linear(@mutable.DensePolynomial::from_coefficients([0, 3])), content="true")
  inspect(is_linear(@immut.DensePolynomial::from_coefficients([1, 0, 2])), content="false")
}
```

### Reset and reuse

`clear` (also `@mutable.Clearable::clear`) resets a buffer to zero for reuse:

```moonbit
test "reuse" {
  let buffer = @mutable.DensePolynomial::from_coefficients([4, 5])
  @mutable.Clearable::clear(buffer)
  assert_true(buffer.is_zero())
  buffer.set_coefficient(2, 1)
  inspect(buffer, content="1x^2")
}
```

## Common pitfalls

- **Shared containers.** `let q = p` makes `q` the same container; mutating `q` changes `p`. Use `p.copy()`.
- **No checked setter.** `set_coefficient` aborts on a negative power.
- **Derivatives** need `Float`, `Double` or `BigInt` coefficients, as in the immutable type.
- **Delegated operations convert.** `pow`, `substitute` and `karatsuba` copy the coefficients to the immutable type and back; that is cheap compared with the operation, but not free.

## Next steps

- The [mutable/dense API](../../api/mutable/dense.md) marks which methods mutate.
- The [mutable/dense design](../../design/mutable/dense.md) explains the invariants and aliasing.
- The [immut/dense tutorial](../immut/dense.md) covers the mathematics of the operations.
