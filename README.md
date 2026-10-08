# luna-poly

`luna-poly` 0.3.0 provides canonical polynomial types for MoonBit: dense univariate polynomials, multivariate polynomials as sorted term arrays or ordered maps, and polynomials over named variables with evaluation, partial evaluation and substitution. Every type exists as an immutable value and as a mutable container with explicit `_inplace` updates, and both share one canonical form, so `==` is equality of polynomials.

## Install

```bash
moon add Luna-Flow/luna-poly@0.3.0
```

Then import a facade in `moon.pkg`:

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

## Example

```moonbit
test "readme example" {
  // 1 + 2x + 3x^2, squared and evaluated at 2
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  inspect(p.pow(2).eval(2), content="289")

  // in-place updates
  let buffer = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  buffer.set_coefficient(1, 5)
  buffer.add_inplace(@mutable.DensePolynomial::from_coefficients([-1, -5, -3]))
  assert_true(buffer.is_zero())

  // named variables, partial evaluation and substitution
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let q = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [
    ([(x, 2U)], 1),
    ([(x, 1U), (y, 1U)], 3),
    ([], 4),
  ])
  inspect(q.eval_named([(x, 2), (y, 5)]), content="38")
  inspect(q.eval_partial_named([(x.to_type_theory_name(), 2)]), content="8 + 6 * y")
  let y_plus_1 = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(y, 1U)], 1), ([], 1)])
  inspect(q.substitute([(x, Polynomial(y_plus_1))]), content="5 + 5 * y + 4 * y^2")
}
```

## Packages

| Package | Contents |
| --- | --- |
| `Luna-Flow/luna-poly/core` | `ExponentVector`, `Variable`, `VariableContext`, `PolynomialShape`, capability traits, operation records |
| `Luna-Flow/luna-poly/immut` | facade: immutable `DensePolynomial`, `TermPolynomial`, `SparsePolynomial`, `ContextPolynomial`, plus `core` and `luna-generic` re-exports |
| `Luna-Flow/luna-poly/immut/{dense,term,sparse,context}` | the immutable implementations |
| `Luna-Flow/luna-poly/mutable` | facade: the same names as mutable containers |
| `Luna-Flow/luna-poly/mutable/{dense,term,sparse,context}` | the mutable implementations |

Checked variants (`*_checked`) return `None` on contract violations; the plain forms abort. Natural powers also implement `Luna-Flow/arithmetic`'s `PowNatChecked`, and substitution accepts `Luna-Flow/type_theory` names.

## Requirements

MoonBit toolchain with `moonc` 0.10 or later. Dependencies: `Luna-Flow/luna-generic`, `Luna-Flow/arithmetic`, `Luna-Flow/type_theory`.

## Documentation

The manual, with API references, tutorials and design notes for every package, is published at <https://lunaflow.cn/en/luna-poly/> in English, Chinese and Japanese. Its English source is [`doc/manual/index.md`](doc/manual/index.md); start with the [immut tutorial](doc/manual/tutorial/immut.md), and read the [architecture guide](doc/manual/architecture.md) before contributing. Changes between versions are listed in [`CHANGELOG.md`](CHANGELOG.md).

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and the [contribution guide](doc/manual/contributing.md).

## License

Apache-2.0. See [`LICENSE`](LICENSE).
