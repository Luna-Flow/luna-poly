# core tutorial

This tutorial shows how to use the shared layer of `luna-poly`: exponent vectors, named variables, shapes, capability traits and operation records. By the end you can write one function that works for every polynomial representation in the library, and plug your own representation into it.

| I want to | Use |
| --- | --- |
| build a monomial $x_0 x_1^2$ | `ExponentVector::from_array([1U, 2U])` |
| read or change one exponent | `v[i]`, `get_checked`, `with_exponent` |
| sort monomials the way the library does | `<`, `compare` (graded, ties at the last variable) |
| name variables | `VariableContext::from_names`, `require_variable` |
| map variables to `type_theory` names and back | `to_type_theory_name`, `variable_by_type_theory_name` |
| write one function for every representation | the `Has*` traits or an operation record from `ops()` |
| check that two polynomials can be combined | `shape().is_compatible_with(...)` |
| avoid aborts | the `*_checked` variants, which return `None` |

## Quick start

Add the module:

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

Import the package with an alias, so that it does not clash with `Luna-Flow/type_theory/core`, and the immutable facade for concrete polynomials:

```text
import {
  "Luna-Flow/luna-poly/core" @poly_core,
  "Luna-Flow/luna-poly/immut",
}
```

The smallest useful program builds two monomials and multiplies them:

```moonbit
test "quick start" {
  let xy = @poly_core.ExponentVector::from_array([1U, 1])
  let x2 = @poly_core.ExponentVector::from_array([2U])
  let product = xy * x2
  inspect(product, content="x^3x_1")
  inspect(product.degree(), content="4")
}
```

`[1, 1]` is $x_0 x_1$ and `[2]` is $x_0^2$; their product $x_0^3 x_1$ is printed as `x^3x_1`. Every type in this tutorial is also re-exported by the [`immut`](immut.md) and [`mutable`](mutable.md) facades, so `@immut.ExponentVector` is the same type as `@poly_core.ExponentVector`.

## Everyday tasks

### Read and update exponent vectors

An exponent vector never stores trailing zeros, and reading past its end gives `0`:

```moonbit
test "exponent vector basics" {
  let v = @poly_core.ExponentVector::from_array([2U, 0, 1, 0, 0])
  debug_inspect(v.to_array(), content="[2, 0, 1]")
  inspect(v.length(), content="3")
  inspect(v[2], content="1")
  inspect(v[10], content="0")
  let w = v.with_exponent(2, 0)
  debug_inspect(w.to_array(), content="[2]")
  debug_inspect(v.to_array(), content="[2, 0, 1]")
  assert_true(@poly_core.ExponentVector::from_array([1U, 0]) == @poly_core.ExponentVector::from_array([1U]))
}
```

`with_exponent` returns a new vector; `v` is unchanged.

### Sort monomials

Monomials are ordered by total degree first, then by the highest-indexed variable where they differ:

```moonbit
test "monomial order" {
  let monomials = [
    @poly_core.ExponentVector::from_array([1U, 0, 1]),
    @poly_core.ExponentVector::from_array([0U, 2]),
    @poly_core.ExponentVector::one(),
    @poly_core.ExponentVector::from_array([3U]),
    @poly_core.ExponentVector::from_array([1U]),
  ]
  monomials.sort()
  inspect(
    monomials.map(m => m.to_string()).join(" < "),
    content="1 < x < x_1^2 < xx_2 < x^3",
  )
}
```

$x_1^2$ and $x_0 x_2$ both have degree $2$; they differ last at variable $2$, where $x_0 x_2$ has the larger exponent, so $x_1^2 < x_0 x_2$. The [core design](../design/core.md#the-monomial-order) explains why this order is a monomial order.

### Name your variables

A `VariableContext` gives each name a stable index:

```moonbit
test "contexts" {
  let ctx = @poly_core.VariableContext::from_names(["x", "y"])
  let (ctx, t) = ctx.extend_with("t")
  inspect(ctx, content="VariableContext(x, y, t)")
  inspect(t.index(), content="2")
  match ctx.variable("y") {
    Some(y) => inspect(y.index(), content="1")
    None => fail("y should exist")
  }
  assert_true(ctx.variable("z") is None)
  assert_true(ctx.extend_checked("x") is None)
}
```

Contexts are values: `extend_with` returns a new context and the variable it added, and never renumbers existing variables.

### Talk to `type_theory`

When names come from `Luna-Flow/type_theory`, convert in both directions through the context:

```moonbit
test "type theory names" {
  let ctx = @poly_core.VariableContext::from_names(["x", "y"])
  let y = ctx.require_variable("y")
  let name : @tt_core.Name = y.to_type_theory_name()
  inspect(name.text(), content="y")
  assert_true(ctx.variable_by_type_theory_name(name) == Some(y))
  assert_true(ctx.variable_by_type_theory_name(@tt_core.Name::new("q")) is None)
}
```

This needs `"Luna-Flow/type_theory/core" @tt_core` in your imports. The name forgets the index; the context restores it.

### Write one function for every representation

Bound a type parameter by a capability bundle and call the trait methods in qualified form:

```moonbit
fn[P : @poly_core.MultivariatePolynomial] summary(p : P) -> String {
  if @poly_core.IsZero::is_zero(p) {
    return "zero"
  }
  "\{@poly_core.HasTermCount::term_count(p)} terms in \{@poly_core.HasArity::arity(p)} variables"
}

test "generic over representations" {
  let terms = [([2U, 1], 3), ([0U, 0, 1], 1), ([], -2)]
  let a = @immut.TermPolynomial::from_array(terms)
  let b = @immut.SparsePolynomial::from_array(terms)
  let c = @mutable.SparsePolynomial::from_array(terms)
  inspect(summary(a), content="3 terms in 3 variables")
  inspect(summary(b), content="3 terms in 3 variables")
  inspect(summary(c), content="3 terms in 3 variables")
  inspect(summary(@immut.TermPolynomial::from_array([([1U], 0)])), content="zero")
}
```

When an algorithm also needs construction or arithmetic, pass the type's operation record:

```moonbit
fn[P, A] square_all(ops : @poly_core.UnivariateOps[P, A], ps : Array[P]) -> Array[A] {
  ps.map(p => ops.eval(ops.pow(p, 2), ops.coefficient(p, 0)))
}

test "operation records" {
  let p = @immut.DensePolynomial::from_coefficients([1, 1])
  let q = @mutable.DensePolynomial::from_coefficients([2, 0, 1])
  debug_inspect(square_all(@immut.DensePolynomial::ops(), [p]), content="[4]")
  debug_inspect(square_all(@mutable.DensePolynomial::ops(), [q]), content="[36]")
}
```

`square_all` computes $p(c)^2$ where $c$ is the constant term, for any univariate representation: $(1 + 1)^2 = 4$ and $(2 + 2^2)^2 = 36$.

### Check before you combine

Shapes tell you whether two values live in the same polynomial ring:

```moonbit
test "shapes" {
  let ctx = @poly_core.VariableContext::from_names(["x"])
  let other = @poly_core.VariableContext::from_names(["u"])
  let x = ctx.require_variable("x")
  let u = other.require_variable("u")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U)], 1)])
  let q = @immut.ContextPolynomial::from_named_terms_as_sparse(other, [([(u, 1U)], 1)])
  let sp = @poly_core.HasShape::shape(p)
  let sq = @poly_core.HasShape::shape(q)
  assert_false(sp.is_compatible_with(sq))
  assert_true(p.add_checked(q) is None)
  inspect(sp.arity(), content="1")
}
```

## Going further

### Plug in your own representation

The capability traits are open, so a type of your own can join generic code. Implement the observations and the bundle:

```moonbit
struct Monic {
  degree : Int
}

impl @poly_core.HasShape for Monic with fn shape(self) {
  @poly_core.PolynomialShape::univariate(self.degree + 1)
}

impl @poly_core.HasLength for Monic with fn length(self) {
  self.degree + 1
}

impl @poly_core.HasDegree for Monic with fn degree(self) {
  Some(self.degree)
}

impl @poly_core.IsZero for Monic with fn is_zero(_self) {
  false
}

impl @poly_core.UnivariatePolynomial for Monic

fn[P : @poly_core.UnivariatePolynomial] describe_degree(p : P) -> String {
  match @poly_core.HasDegree::degree(p) {
    Some(d) => "degree \{d}"
    None => "zero polynomial"
  }
}

test "own representation" {
  inspect(describe_degree(Monic::{ degree: 3 }), content="degree 3")
  inspect(describe_degree(@immut.DensePolynomial::from_coefficients([0, 0])), content="zero polynomial")
}
```

For operations, build a record with `UnivariateOps::new`, `MultivariateOps::new` or `ContextOps::new`, passing your functions in the order listed in the [core API](../api/core.md#operation-records).

### Handle failures without aborting

Every aborting accessor has a `*_checked` twin that returns `None` instead. Chain them with `Option` combinators or `match`:

```moonbit
fn exponent_of(v : @poly_core.ExponentVector, i : Int) -> String {
  match v.get_checked(i) {
    Some(e) => e.to_string()
    None => "invalid index"
  }
}

test "checked" {
  let v = @poly_core.ExponentVector::from_array([4U])
  inspect(exponent_of(v, 0), content="4")
  inspect(exponent_of(v, -1), content="invalid index")
}
```

The `Option` does not say *why* an operation failed; check the preconditions yourself when you need a message.

## Common pitfalls

- **Import aliases.** `Luna-Flow/luna-poly/core` and `Luna-Flow/type_theory/core` both default to `@core`. Give at least one an alias, as in the quick start.
- **Exponents are `UInt`.** Write literals as `1U` (at least the first element of an array), and remember that exponent sums wrap modulo $2^{32}$.
- **Printed monomials have no separator.** `x * x_1` prints as `xx_1`. Use `to_array()` when you need an unambiguous form.
- **Multi-bound type parameters.** Inside `fn[P : A + B]`, or when a method comes from a supertrait, write `Trait::method(p)` instead of `p.method()`.
- **Contexts are structural.** Two contexts built from the same names in the same order are equal, and their polynomials can be combined.
- **Shapes ignore size.** Two multivariate shapes are compatible whatever their arities; compatibility only rules out mixing families or contexts.

## Next steps

- The [core API](../api/core.md) lists every item with its signature.
- The [core design](../design/core.md) derives the monomial order and the name round trip.
- Continue with the [`immut` tutorial](immut.md) for concrete polynomials, or the [context tutorial](immut/context.md) for named variables and substitution.
- [`Luna-Flow/type_theory`](https://lunaflow.cn/en/type_theory/) documents the `Name` type.
