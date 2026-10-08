# immut/dense tutorial

This tutorial teaches you to compute with univariate polynomials as immutable values: build them, do arithmetic, evaluate, compose and differentiate them, and pick the right multiplication for long inputs.

| I want to | Use |
| --- | --- |
| build $1 + 2x + 3x^2$ | `DensePolynomial::from_coefficients([1, 2, 3])` |
| build $x$, a constant or $c\,x^n$ | `variable`, `constant`, `monomial` |
| read a coefficient or the degree | `coefficient`, `degree`, `leading_term` |
| add, subtract, multiply | `+`, `-`, `*` |
| evaluate at a point | `eval` (Horner) |
| compose $p(q(x))$ | `substitute` |
| differentiate | `derivative` |
| multiply long polynomials | `karatsuba` |
| raise to a power | `pow` |
| avoid aborting on a negative power index | `coefficient_checked`, `monomial_checked`, `scale_checked` |

## Quick start

Add the module and import the immutable facade, which re-exports `DensePolynomial`:

```bash
moon add Luna-Flow/luna-poly@0.3.0
```

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

```moonbit
test "dense quick start" {
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  inspect(p, content="1 + 2x^1 + 3x^2")
  inspect(p.eval(2), content="17")
}
```

Coefficients are listed from the constant term up, so `[1, 2, 3]` is $1 + 2x + 3x^2$, and $p(2) = 1 + 4 + 12 = 17$. You can also import `Luna-Flow/luna-poly/immut/dense` directly; the type is the same.

## Everyday tasks

### Build polynomials

Use `from_coefficients` for a whole polynomial, and `constant`, `variable` and `monomial` for building blocks that you combine with operators:

```moonbit
test "building polynomials" {
  let x : @immut.DensePolynomial[Int] = @immut.DensePolynomial::variable()
  let two = @immut.DensePolynomial::constant(2)
  let p = x * x - two * x + @immut.DensePolynomial::monomial(0, 1)
  inspect(p, content="1 + -2x^1 + 1x^2")
  debug_inspect(p.to_coefficients(), content="[1, -2, 1]")
  inspect(@immut.DensePolynomial::from_coefficients([0, 0, 0]).is_zero(), content="true")
}
```

Trailing zeros are dropped everywhere, so `[0, 0, 0]` is the zero polynomial and `to_coefficients` always returns the shortest form.

### Read coefficients and degree

```moonbit
test "reading" {
  let p = @immut.DensePolynomial::from_coefficients([5, 0, 7])
  debug_inspect(p.degree(), content="Some(2)")
  inspect(p.coefficient(0), content="5")
  inspect(p.coefficient(10), content="0")
  debug_inspect(p.leading_coefficient(), content="Some(7)")
  let zero : @immut.DensePolynomial[Int] = @immut.DensePolynomial::zero()
  debug_inspect(zero.degree(), content="None")
}
```

The zero polynomial has no degree, so `degree` returns `None` rather than `0`.

### Do arithmetic without losing old values

Every operation returns a new polynomial; the operands stay as they were:

```moonbit
test "value semantics" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let q = p * p
  let r = q.scale(1, 2)
  inspect(p, content="1 + 1x^1")
  inspect(q, content="1 + 2x^1 + 1x^2")
  inspect(r, content="2x^1 + 4x^2 + 2x^3")
  inspect(p.pow(4), content="1 + 4x^1 + 6x^2 + 4x^3 + 1x^4")
}
```

`scale(k, c)` multiplies by $c\,x^k$, and `pow(e)` is repeated multiplication done by repeated squaring.

### Evaluate, compose and differentiate

```moonbit
test "calculus" {
  let p = @immut.DensePolynomial::from_coefficients([1.0, -3.0, 0.0, 1.0])
  inspect(p.eval(2.0), content="3")
  let shift = @immut.DensePolynomial::from_coefficients([1.0, 1.0])
  let moved = p.substitute(shift)
  inspect(moved.eval(1.0), content="3")
  let dp = p.derivative()
  debug_inspect(dp.to_coefficients(), content="[-3, 0, 3]")
  inspect(dp.eval(1.0), content="0")
}
```

`p.substitute(q)` is the composition $p(q(x))$, so `moved` is $p(x + 1)$ and `moved.eval(1.0)` equals `p.eval(2.0)`. `derivative` is the formal derivative; here $p' = 3x^2 - 3$ vanishes at $1$.

### Multiply long polynomials faster

`*` is the schoolbook product, $O(mn)$. For long operands call `karatsuba`, which gives the same result in about $O(n^{1.585})$:

```moonbit
test "karatsuba" {
  let a = @immut.DensePolynomial::from_coefficients(Array::makei(200, i => i % 5 - 2))
  let b = @immut.DensePolynomial::from_coefficients(Array::makei(150, i => i % 3 - 1))
  let fast = a.karatsuba(b)
  assert_true(fast == a * b)
  inspect(fast.length(), content="349")
}
```

Below 33 coefficients in the shorter operand `karatsuba` simply calls `*`, so it is never slower in practice.

## Going further

### Generic algorithms over coefficient types

Write algorithms with `luna-generic` bounds, re-exported by the facade, and they work for every coefficient type that has the capabilities:

```moonbit
fn[A : @immut.AddMonoid + Mul + Eq] square_eval(p : @immut.DensePolynomial[A], a : A) -> A {
  (p * p).eval(a)
}

test "generic coefficients" {
  inspect(square_eval(@immut.DensePolynomial::from_coefficients([1, 1]), 2), content="9")
  inspect(square_eval(@immut.DensePolynomial::from_coefficients([1U, 1U]), 2U), content="9")
  inspect(square_eval(@immut.DensePolynomial::from_coefficients([0.5, 0.5]), 1.0), content="1")
}
```

`UInt` coefficients work although `UInt` has no negation, because `*` and `eval` do not ask for one.

### Generic algorithms over representations

`DensePolynomial::ops()` packages the operations as a record, so the same code can run on the mutable representation too:

```moonbit
fn[P, A] horner_check(ops : @immut.UnivariateOps[P, A], p : P, a : A) -> A {
  ops.eval(ops.pow(p, 3), a)
}

test "ops records" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let m = @mutable.DensePolynomial::from_coefficients([1, 1])
  inspect(horner_check(@immut.DensePolynomial::ops(), p, 1), content="8")
  inspect(horner_check(@mutable.DensePolynomial::ops(), m, 1), content="8")
}
```

### Errors without aborts

`monomial`, `coefficient` and `scale` abort on a negative power. Their `_checked` forms return `None` instead:

```moonbit
fn safe_shift(p : @immut.DensePolynomial[Int], k : Int) -> @immut.DensePolynomial[Int] {
  p.scale_checked(k, 1).unwrap_or(p)
}

test "checked" {
  let p = @immut.DensePolynomial::from_coefficients([3])
  inspect(safe_shift(p, 2), content="3x^2")
  inspect(safe_shift(p, -2), content="3")
}
```

### Powers through `arithmetic`

`DensePolynomial` implements `@arithmetic.PowNatChecked`, so code written against `Luna-Flow/arithmetic` can raise polynomials to natural powers:

```moonbit
test "pow nat checked" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let ctx = @arithmetic.ArithmeticContext::new(0)
  match @arithmetic.PowNatChecked::pow_nat_checked(p, 2, ctx) {
    Ok(q) => inspect(q, content="1 + 2x^1 + 1x^2")
    Err(_) => fail("pow_nat_checked never fails for polynomials")
  }
}
```

## Common pitfalls

- **Coefficient order.** The array is ascending: `[a, b, c]` is $a + bx + cx^2$, not $ax^2 + bx + c$.
- **`degree` of zero.** It is `None`. Use `length()` if you want `0` for the zero polynomial.
- **Fixed-width overflow.** `Int` coefficients wrap, and a leading coefficient can wrap to zero, lowering the degree:

  ```moonbit
  test "wrapping" {
    let p = @immut.DensePolynomial::from_coefficients([1, 65536])
    inspect((p * p).degree().unwrap(), content="1")
  }
  ```

- **Floating-point trimming.** Only coefficients that compare equal to zero are trimmed. `0.1 + 0.2 - 0.3` is not zero, so such a coefficient stays.
- **Derivatives need `FromNat`.** `derivative` works for every numeric type that luna-generic supports (`Int`, `Int64`, `UInt`, `Float`, `Double`, `BigInt`, ...). For fixed-width integers such as `Int` the factor $i$ wraps modulo $2^{32}$, and a custom coefficient type needs a `FromNat` instance. Before 0.3.0 the bound was `NatHomomorphism`, and `Int` coefficients had no derivative.
- **`0^0`.** `pow(0)` returns one for every polynomial, including zero.
- **Printing.** `to_string` writes `x^1` explicitly and skips zero terms; use `to_coefficients` for exact output.

## Next steps

- The [immut/dense API](../../api/immut/dense.md) lists every method with its signature and cost.
- The [immut/dense design](../../design/immut/dense.md) derives Karatsuba, Horner and the Leibniz rule.
- For several variables, continue with the [term tutorial](term.md) or the [sparse tutorial](sparse.md); for in-place updates, the [mutable/dense tutorial](../mutable/dense.md).
