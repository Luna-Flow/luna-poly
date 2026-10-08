# internal tutorial

This page is for contributors: it shows when to use the `internal` package while working on `luna-poly` itself. Users of the library never import it, and MoonBit does not allow packages outside the module to do so.

| I want to | Use |
| --- | --- |
| implement `pow` for a new representation | `@internal.pow_nat(p, e, one=...)` |
| evaluate $a^e$ for a coefficient | `@internal.pow_nat(a, e, one=One::one())` |

## Quick start

Inside a `luna-poly` package, import it in `moon.pkg`:

```text
import {
  "Luna-Flow/luna-poly/internal",
}
```

and raise a value to a natural power with an explicit unit:

```moonbit nocheck
let cube = @internal.pow_nat(x, 3U, one=@lg.One::one())
```

## Everyday tasks

### Implement `pow` for a new representation

Delegate to `pow_nat` with the representation's own unit, exactly as the existing types do:

```moonbit nocheck
pub fn[A : Eq + AddMonoid + Mul + One] MyPolynomial::pow(
  self : MyPolynomial[A],
  exponent : UInt,
) -> MyPolynomial[A] {
  @internal.pow_nat(self, exponent, one=MyPolynomial::one())
}
```

This gives `pow(0) == one()` for every input and $O(\log e)$ multiplications.

### Evaluate a monomial

Evaluation multiplies the coefficient by $a_i^{\alpha_i}$ for every variable:

```moonbit nocheck
let mut term = coefficient
for i in 0..<exponent.length() {
  term = term * @internal.pow_nat(values[i], exponent[i], one=@lg.One::one())
}
```

## Going further

Add a helper to `internal` only when two or more representation packages need it and it should not become public API. Anything users should call belongs in `core` or in a representation package.

## Common pitfalls

- **Wrong unit.** `pow_nat` multiplies onto `one`; passing anything but the unit gives `one · a^e`.
- **Expecting public access.** Code outside the module cannot import `internal`; expose behaviour through a public method instead.

## Next steps

- The [internal API](../api/internal.md) and [internal design](../design/internal.md).
- The [architecture guide](../architecture.md) shows where `internal` sits in the package graph.
