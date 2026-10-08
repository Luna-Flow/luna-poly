# luna-poly

`luna-poly` provides canonical polynomial types for MoonBit: dense univariate polynomials, multivariate polynomials as sorted term arrays or ordered maps, and polynomials over named variables with evaluation, partial evaluation and substitution. Every type comes in an immutable flavour, where polynomials are values, and a mutable flavour, where explicitly named methods update a container in place. This manual describes version 0.2.0.

## What you get

- **Canonical forms.** Every representation removes zero terms and keeps one normal form, so `==` is equality of polynomials.
- **A shared monomial model.** Exponent vectors without a fixed number of variables, ordered by a graded monomial order.
- **Algorithms with stated costs.** Schoolbook and Karatsuba multiplication, Horner evaluation, composition, formal derivatives, binary powers, and simultaneous substitution as a ring homomorphism.
- **Generic code.** Small capability traits, operation records, and the algebra traits of [`luna-generic`](https://lunaflow.cn/en/luna-generic/) re-exported by both facades.
- **Named variables** through variable contexts, bridged to [`type_theory`](https://lunaflow.cn/en/type_theory/) names.
- **Checked variants** of every partial operation, returning `None` instead of aborting.

## Packages

| Package | Role | Pages |
| --- | --- | --- |
| `core` | exponent vectors, variables and contexts, shapes, capability traits, operation records | [API](api/core.md) · [tutorial](tutorial/core.md) · [design](design/core.md) |
| `immut` | facade of the immutable layer | [API](api/immut.md) · [tutorial](tutorial/immut.md) · [design](design/immut.md) |
| `immut/dense` | immutable dense univariate `DensePolynomial` | [API](api/immut/dense.md) · [tutorial](tutorial/immut/dense.md) · [design](design/immut/dense.md) |
| `immut/term` | immutable sorted-term `TermPolynomial` | [API](api/immut/term.md) · [tutorial](tutorial/immut/term.md) · [design](design/immut/term.md) |
| `immut/sparse` | immutable ordered-map `SparsePolynomial` | [API](api/immut/sparse.md) · [tutorial](tutorial/immut/sparse.md) · [design](design/immut/sparse.md) |
| `immut/context` | immutable named-variable `ContextPolynomial` and substitution | [API](api/immut/context.md) · [tutorial](tutorial/immut/context.md) · [design](design/immut/context.md) |
| `mutable` | facade of the mutable layer | [API](api/mutable.md) · [tutorial](tutorial/mutable.md) · [design](design/mutable.md) |
| `mutable/dense` | mutable `DensePolynomial` | [API](api/mutable/dense.md) · [tutorial](tutorial/mutable/dense.md) · [design](design/mutable/dense.md) |
| `mutable/term` | mutable `TermPolynomial` | [API](api/mutable/term.md) · [tutorial](tutorial/mutable/term.md) · [design](design/mutable/term.md) |
| `mutable/sparse` | mutable `SparsePolynomial` | [API](api/mutable/sparse.md) · [tutorial](tutorial/mutable/sparse.md) · [design](design/mutable/sparse.md) |
| `mutable/context` | mutable `ContextPolynomial` | [API](api/mutable/context.md) · [tutorial](tutorial/mutable/context.md) · [design](design/mutable/context.md) |
| `internal` | module-private helpers (natural powers) | [API](api/internal.md) · [tutorial](tutorial/internal.md) · [design](design/internal.md) |
| `consistency` | test-only package checking that layers and representations agree | [API](api/consistency.md) · [tutorial](tutorial/consistency.md) · [design](design/consistency.md) |

The [architecture guide](architecture.md) shows how the packages depend on each other.

## Reading paths

**New to the library.** Read the [immut tutorial](tutorial/immut.md), then the tutorial of the representation you need: [dense](tutorial/immut/dense.md) for one variable, [term](tutorial/immut/term.md) or [sparse](tutorial/immut/sparse.md) for several, [context](tutorial/immut/context.md) for named variables and substitution.

**Using it in an application.** Keep the [immut API](api/immut.md) and the per-representation API pages at hand; they state every precondition, failure case and cost. Read the [mutable tutorial](tutorial/mutable.md) when profiling shows that intermediate values matter.

**Writing generic code or a new representation.** Read the [core tutorial](tutorial/core.md) and the [core design](design/core.md), which derives the monomial order and explains the capability traits and operation records.

**Contributing.** Read the [architecture guide](architecture.md), the design pages of the packages you touch, the [consistency](design/consistency.md) page, and the [contributing guide](contributing.md).

## Requirements and installation

`luna-poly` needs the MoonBit toolchain with `moonc` 0.10 or later. Add it to a module with

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

and import a facade in `moon.pkg`:

```text
import {
  "Luna-Flow/luna-poly/immut",
}
```

It depends on `Luna-Flow/luna-generic`, `Luna-Flow/arithmetic` and `Luna-Flow/type_theory`, which `moon` installs automatically.

## A first example

```moonbit
test "first example" {
  let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  inspect(p.pow(2).eval(2), content="289")

  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let q = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [
    ([(x, 2U)], 1),
    ([(x, 1U), (y, 1U)], 3),
    ([], 4),
  ])
  inspect(q.eval_named([(x, 2), (y, 5)]), content="38")
  inspect(q.eval_partial([(x, 2)]), content="8 + 6 * y")
}
```

## Version 0.2.0 layout

Version 0.2.0 replaced the former single root package by `core`, the implementation packages and the two facades. Import `Luna-Flow/luna-poly/immut` or `Luna-Flow/luna-poly/mutable` explicitly; code written for the old root package does not compile unchanged.
