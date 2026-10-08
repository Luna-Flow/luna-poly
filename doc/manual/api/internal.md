# internal API

## Purpose

`Luna-Flow/luna-poly/internal` holds helpers shared by the implementation packages. This page documents the contract the representations rely on. The reasoning is in the [internal design](../design/internal.md).

## Importing

MoonBit restricts an `internal` package to importers inside the same module, so only packages of `luna-poly` can write

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/internal",
}
```

Code outside `luna-poly` cannot call it.

## Powers

### `pow_nat`

Computes $a^e$ for a natural exponent by binary exponentiation, starting from the unit `one`.

```mbti
pub fn[A : Mul] pow_nat(A, UInt, one~ : A) -> A
```

- `pow_nat(a, 0, one=u)` returns `u`, whatever `a` is; this is how every `pow(0)` in the library returns one, including for zero.
- It performs $\lfloor \log_2 e \rfloor$ squarings and at most one further multiplication per set bit of $e$, so at most $2\lfloor \log_2 e \rfloor + 1$ calls of `*`.
- It needs only an associative `*` for which `one` is a left unit; it does not need commutativity, because every factor it multiplies is a power of `a`.

It is used for polynomial powers (`DensePolynomial::pow`, `TermPolynomial::pow`, `SparsePolynomial::pow`) and for coefficient powers $a_i^{\alpha_i}$ during evaluation and substitution.

```moonbit nocheck
// Inside luna-poly only:
let p = @internal.pow_nat(base, 5U, one=DensePolynomial::one())
```
