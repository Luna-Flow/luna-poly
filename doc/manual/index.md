# luna-poly

This manual documents the `v0.2.0` release of `Luna-Flow/luna-poly`.

## Overview

`luna-poly` provides canonical polynomial types for MoonBit: dense univariate polynomials, multivariate polynomials as sorted term arrays or ordered maps, and polynomials over named variables with evaluation, partial evaluation and substitution. Every type comes in an immutable flavour, where polynomials are values, and a mutable flavour, where explicitly named methods update a container in place.

- **Canonical forms.** Every representation removes zero terms and keeps one normal form, so `==` is equality of polynomials.
- **A shared monomial model.** Exponent vectors without a fixed number of variables, ordered by a graded monomial order.
- **Algorithms with stated costs.** Schoolbook and Karatsuba multiplication, Horner evaluation, composition, formal derivatives, binary powers, and simultaneous substitution as a ring homomorphism.
- **Generic code.** Small capability traits, operation records, and the algebra traits of [`luna-generic`](https://lunaflow.cn/en/luna-generic/) re-exported by both facades.
- **Named variables** through variable contexts, bridged to [`type_theory`](https://lunaflow.cn/en/type_theory/) names.
- **Checked variants** of every partial operation, returning `None` instead of aborting.

Version 0.2.0 replaced the former single root package by `core`, the implementation packages and the two facades. Import `Luna-Flow/luna-poly/immut` or `Luna-Flow/luna-poly/mutable` explicitly; code written for the old root package does not compile unchanged.

## Install

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

Then import a facade in your `moon.pkg`:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/immut",
}
```

The package needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10). It depends on `Luna-Flow/luna-generic` 0.3.3, `Luna-Flow/arithmetic` 0.2.1 and `Luna-Flow/type_theory` 0.2.0, which `moon` installs automatically.

## Pages

Each package of the module has a tutorial, an API page and a design page. The two facades are the packages most programs import; `internal` and `consistency` are for contributors.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: exponent vectors, variables and contexts, shapes, capability traits, operation records | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |
| `immut`: facade of the immutable layer | [tutorial](tutorial/immut.md) | [API](api/immut.md) | [design](design/immut.md) |
| `immut/dense`: dense univariate `DensePolynomial` | [tutorial](tutorial/immut/dense.md) | [API](api/immut/dense.md) | [design](design/immut/dense.md) |
| `immut/term`: sorted-term `TermPolynomial` | [tutorial](tutorial/immut/term.md) | [API](api/immut/term.md) | [design](design/immut/term.md) |
| `immut/sparse`: ordered-map `SparsePolynomial` | [tutorial](tutorial/immut/sparse.md) | [API](api/immut/sparse.md) | [design](design/immut/sparse.md) |
| `immut/context`: named-variable `ContextPolynomial` and substitution | [tutorial](tutorial/immut/context.md) | [API](api/immut/context.md) | [design](design/immut/context.md) |
| `mutable`: facade of the mutable layer | [tutorial](tutorial/mutable.md) | [API](api/mutable.md) | [design](design/mutable.md) |
| `mutable/dense`: mutable `DensePolynomial` | [tutorial](tutorial/mutable/dense.md) | [API](api/mutable/dense.md) | [design](design/mutable/dense.md) |
| `mutable/term`: mutable `TermPolynomial` | [tutorial](tutorial/mutable/term.md) | [API](api/mutable/term.md) | [design](design/mutable/term.md) |
| `mutable/sparse`: mutable `SparsePolynomial` | [tutorial](tutorial/mutable/sparse.md) | [API](api/mutable/sparse.md) | [design](design/mutable/sparse.md) |
| `mutable/context`: mutable `ContextPolynomial` | [tutorial](tutorial/mutable/context.md) | [API](api/mutable/context.md) | [design](design/mutable/context.md) |
| `internal`: module-private natural powers | [tutorial](tutorial/internal.md) | [API](api/internal.md) | [design](design/internal.md) |
| `consistency`: test-only agreement checks between layers | [tutorial](tutorial/consistency.md) | [API](api/consistency.md) | [design](design/consistency.md) |
| Architecture guide: layers, dependencies, invariants | | | [architecture](architecture.md) |
| Contributing guide | | | [contributing](contributing.md) |

## Representations

- `DensePolynomial`: univariate, ascending coefficient vector; Karatsuba, composition, derivative
- `TermPolynomial`: multivariate, terms in descending monomial order; leading term first
- `SparsePolynomial`: multivariate, ordered map from monomials to coefficients; logarithmic lookup
- `ContextPolynomial`, `ContextSubstitutionValue`: polynomials over named variables, with named evaluation, partial evaluation and substitution

Each exists in `immut` and in `mutable`; the mutable types add `set_coefficient`, `add_term_inplace`, the `*_inplace` methods, `copy`, `clear`, `to_immut` and `from_immut`.

## Shared vocabulary

- Monomials: `ExponentVector`, ordered by a graded monomial order
- Names: `Variable`, `VariableContext`
- Shapes: `PolynomialShape`
- Capability traits: `HasLength`, `HasDegree`, `IsZero`, `HasTermCount`, `HasArity`, `HasTotalDegree`, `HasContext`, `HasShape`, `Clearable`, `Copyable`, and the bundles `UnivariatePolynomial`, `MultivariatePolynomial`, `ContextualPolynomial`, `MutablePolynomial`
- Operation records: `UnivariateOps`, `MultivariateOps`, `ContextOps`
- Algebra traits re-exported from `luna-generic`: `Zero`, `One`, `AddMonoid`, `MulMonoid`, `AddGroup`, `MulGroup`, `Semiring`, `Ring`, `Field`, `Num`

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

## Where to read next

The [immut tutorial](tutorial/immut.md) helps you pick a representation, and the tutorial of that representation shows the everyday tasks. The API pages state every precondition, failure case and cost, and the design pages derive the mathematics: the monomial order in [core](design/core.md), Karatsuba and composition in [immut/dense](design/immut/dense.md), substitution as a ring homomorphism in [immut/context](design/immut/context.md).

- New to the library: read the [immut tutorial](tutorial/immut.md), then the tutorial of the representation you need: [dense](tutorial/immut/dense.md) for one variable, [term](tutorial/immut/term.md) or [sparse](tutorial/immut/sparse.md) for several, [context](tutorial/immut/context.md) for named variables and substitution.
- Using it in a library: keep the [immut API](api/immut.md) and the per-representation API pages at hand. Read the [mutable tutorial](tutorial/mutable.md) when profiling shows that intermediate values matter, and the [core tutorial](tutorial/core.md) to write code that works for every representation.
- Contributing: read the [architecture guide](architecture.md), the [core design](design/core.md), the design pages of the packages you touch, the [consistency](design/consistency.md) page and the [contributing guide](contributing.md).

## Validation

Recommended release checks, from the repository root (`./ready_to_pr.sh` runs them):

```bash
moon fmt
moon check --target all
moon test
moon info
```
