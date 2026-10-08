# immut tutorial

This tutorial is the entry point for using polynomials as values. It shows one import that gives you every immutable representation, helps you pick the right one, and moves a polynomial between them. Each representation has its own tutorial for the details.

| I want to | Use |
| --- | --- |
| get every immutable type with one import | `"Luna-Flow/luna-poly/immut"` |
| compute with one variable | `DensePolynomial` |
| traverse terms in order or read the leading term | `TermPolynomial` |
| look up single coefficients | `SparsePolynomial` |
| use named variables and substitution | `ContextPolynomial` |
| convert between representations | `to_terms` and `from_terms`, or the context conversions |
| write code that runs on every representation | the capability traits and `ops()` |
| update a polynomial in place | the [mutable layer](mutable.md), via `from_immut` |

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.3.0
```

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

```moonbit
test "immut quick start" {
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  let q = p.pow(2)
  inspect(q, content="1 + 4x^1 + 10x^2 + 12x^3 + 9x^4")
  inspect(q.eval(2), content="289")
  inspect(p, content="1 + 2x^1 + 3x^2")
}
```

`p.pow(2)` returns a new polynomial; `p` itself is unchanged, as it is after every operation in this layer.

## Everyday tasks

### Pick a representation

| You have | Use | Tutorial |
| --- | --- | --- |
| one variable, most coefficients non-zero | `DensePolynomial` | [immut/dense](immut/dense.md) |
| several variables, process terms in order | `TermPolynomial` | [immut/term](immut/term.md) |
| several variables, look up coefficients | `SparsePolynomial` | [immut/sparse](immut/sparse.md) |
| named variables, evaluation or substitution by name | `ContextPolynomial` | [immut/context](immut/context.md) |

All four share the operators `+`, `-`, `*`, unary `-` and the method `pow`.

### Same polynomial, three representations

```moonbit
test "three representations" {
  let dense = @immut.DensePolynomial::from_coefficients([1, 2, 1])
  let term = @immut.TermPolynomial::from_array([([2U], 1), ([1U], 2), ([], 1)])
  let sparse = @immut.SparsePolynomial::from_terms(term.to_terms())
  inspect(dense.eval(3), content="16")
  inspect(term.eval([3]), content="16")
  inspect(sparse.eval([3]), content="16")
}
```

$x^2 + 2x + 1$ at $x = 3$ is $16$ in each representation.

### Move between representations

Multivariate representations convert through their term lists; a context polynomial binds or releases a context:

```moonbit
test "conversions" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let term = @immut.TermPolynomial::from_array([([1U, 1], 2), ([], 1)])
  let sparse = @immut.SparsePolynomial::from_terms(term.to_terms())
  let named = @immut.ContextPolynomial::from_sparse_polynomial(ctx, sparse)
  inspect(named, content="1 + 2 * x * y")
  let back = named.to_term_polynomial()
  assert_true(back == term)
}
```

### Rely on value semantics

Keep old versions around freely, for example to compare before and after:

```moonbit
test "history" {
  let history = [@immut.DensePolynomial::from_coefficients([0, 1])]
  for _ in 0..<3 {
    let last = history[history.length() - 1]
    history.push(last * last + @immut.DensePolynomial::constant(1))
  }
  inspect(history.map(p => p.length()).map(n => n.to_string()).join(" "), content="2 3 5 9")
  inspect(history[1], content="1 + 1x^2")
}
```

## Going further

### Write generic code once

The facade re-exports the capability traits and the `luna-generic` algebra traits, so both kinds of bounds need only this import:

```moonbit
fn[P : @immut.MultivariatePolynomial] degree_or_minus_one(p : P) -> Int {
  match @immut.HasTotalDegree::total_degree(p) {
    Some(d) => d.reinterpret_as_int()
    None => -1
  }
}

fn[A : @immut.Ring + Eq] square_minus_one(p : @immut.DensePolynomial[A]) -> @immut.DensePolynomial[A] {
  p * p - @immut.DensePolynomial::one()
}

test "generic" {
  inspect(degree_or_minus_one(@immut.TermPolynomial::from_array([([1U, 2], 1)])), content="3")
  inspect(degree_or_minus_one(@immut.SparsePolynomial::from_array([([1U], 0)])), content="-1")
  inspect(square_minus_one(@immut.DensePolynomial::from_coefficients([1, 1])), content="2x^1 + 1x^2")
}
```

### Hand values to the mutable layer

When a hot loop needs in-place updates, convert at the boundary and convert back:

```moonbit
test "to mutable and back" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let buffer = @mutable.DensePolynomial::from_immut(p)
  for _ in 0..<3 {
    buffer.mul_inplace(@mutable.DensePolynomial::from_immut(p))
  }
  inspect(buffer.to_immut(), content="1 + 4x^1 + 6x^2 + 4x^3 + 1x^4")
  inspect(p, content="1 + 1x^1")
}
```

## Common pitfalls

- **Different types, same polynomial.** `DensePolynomial` and `TermPolynomial` cannot be added to each other; convert first.
- **Substitution constructors.** `@immut.Polynomial(p)` does not exist; write `Polynomial(p)` inside a substitution list, or `@immut.ContextSubstitutionValue::Polynomial(p)`.
- **Two `core` packages.** If you also import `Luna-Flow/type_theory/core`, alias it (for example `@tt_core`); the facade itself does not need `luna-poly/core`.
- **Rebuild costs.** Immutable updates rebuild their result; use the mutable layer for long incremental constructions.

## Next steps

- The per-representation tutorials linked in the table above.
- The [immut API](../api/immut.md) for the list of re-exports, and the [immut design](../design/immut.md) for the reasoning behind the facade.
- The [mutable tutorial](mutable.md) for the execution-oriented layer.
