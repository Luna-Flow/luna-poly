# immut/context tutorial

This tutorial shows how to write polynomials in named variables and transform them: evaluate by name, evaluate some variables and keep the rest, substitute polynomials for variables, and do all of this with names coming from `Luna-Flow/type_theory`.

| I want to | Use |
| --- | --- |
| declare named variables | `VariableContext::from_names`, `require_variable` |
| build a polynomial from named terms | `from_named_terms_as_sparse` or `_as_terms` |
| build $x$ or a constant | `ContextPolynomial::variable`, `constant` |
| evaluate by name | `eval_named` |
| fix some variables and keep the rest | `eval_partial` |
| replace variables by polynomials | `substitute` with `Polynomial(q)` |
| use `type_theory` names | `substitute_names`, `eval_partial_named` |
| get `None` instead of an abort | the `*_checked` variants |

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

```text
import {
  "Luna-Flow/luna-poly/immut",
  "Luna-Flow/type_theory/core" @tt_core,
}
```

The `type_theory` import is only needed for the name-based APIs.

```moonbit
test "context quick start" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [
    ([(x, 2U)], 1),
    ([(x, 1U), (y, 1U)], 3),
    ([], 4),
  ])
  inspect(p, content="4 + 1 * x^2 + 3 * x * y")
  inspect(p.eval_named([(x, 2), (y, 5)]), content="38")
}
```

Each term is a list of `(variable, exponent)` factors and a coefficient; `[]` is the constant term.

## Everyday tasks

### Choose a storage

Build with `_as_terms` for traversal in descending order or `_as_sparse` for coefficient lookup. Results are the same; only the printing order differs:

```moonbit
test "storage" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let terms = [([(x, 1U)], 2), ([(y, 2U)], 1), ([], 7)]
  let t = @immut.ContextPolynomial::from_named_terms_as_terms(ctx, terms)
  let s = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, terms)
  inspect(t, content="1 * y^2 + 2 * x + 7")
  inspect(s, content="7 + 2 * x + 1 * y^2")
  inspect(t.eval([1, 3]) == s.eval([1, 3]), content="true")
}
```

### Build with operators

Constants and single variables combine with `+`, `-`, `*` and `pow`:

```moonbit
test "operators" {
  let ctx = @immut.VariableContext::from_names(["a", "b"])
  let a : @immut.ContextPolynomial[Int] = @immut.ContextPolynomial::variable(ctx, ctx.require_variable("a"))
  let b : @immut.ContextPolynomial[Int] = @immut.ContextPolynomial::variable(ctx, ctx.require_variable("b"))
  let p = (a + b).pow(2) - @immut.ContextPolynomial::constant(ctx, 1)
  inspect(p, content="-1 + 1 * a^2 + 2 * a * b + 1 * b^2")
}
```

### Evaluate some variables, keep the others

`eval_partial` replaces the listed variables by values and returns a polynomial over the same context:

```moonbit
test "partial evaluation" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U), (y, 1U)], 3), ([(y, 2U)], 1), ([], 4)])
  let q = p.eval_partial([(x, 2)])
  inspect(q, content="4 + 6 * y + 1 * y^2")
  inspect(q.eval_named([(x, 0), (y, 5)]), content="59")
  inspect(p.eval_named([(x, 2), (y, 5)]), content="59")
}
```

`q` no longer contains `x`, but still lives in the context `(x, y)`, so `eval_named` still lists every variable it reads by index; any value for `x` gives the same result.

### Substitute polynomials for variables

`substitute` replaces variables by scalars (`Scalar`) or polynomials (`Polynomial`) all at once:

```moonbit
test "substitution" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U)], 1), ([(y, 1U)], 1)])
  let y_poly = @immut.ContextPolynomial::variable(ctx, y)
  let once = p.substitute([(x, Polynomial(y_poly)), (y, Scalar(2))])
  inspect(once, content="2 + 1 * y")
  let twice = once.substitute([(y, Scalar(2))])
  inspect(twice, content="4")
}
```

The substitution is simultaneous: `x` becomes `y`, and that new `y` is not replaced by `2` in the same call. Call `substitute` again to continue.

### Use `type_theory` names

When the variables come from a `type_theory` term, use the `_names` variants; names are resolved in the polynomial's context:

```moonbit
test "type theory names" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 2U)], 1), ([], 1)])
  let n = @tt_core.Name::new("x")
  inspect(p.eval_partial_named([(n, 3)]), content="10")
  let y_poly = @immut.ContextPolynomial::variable(ctx, ctx.require_variable("y"))
  inspect(p.substitute_names([(n, Polynomial(y_poly))]), content="1 + 1 * y^2")
  assert_true(p.substitute_names_checked([(@tt_core.Name::new("z"), Scalar(0))]) is None)
}
```

## Going further

### Handle invalid input with checked forms

Every operation that can fail has a `_checked` form returning `None`:

```moonbit
fn try_eval(p : @immut.ContextPolynomial[Int], at : Array[(@immut.Variable, Int)]) -> String {
  match p.eval_named_checked(at) {
    Some(v) => v.to_string()
    None => "invalid assignment"
  }
}

test "checked" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_terms(ctx, [([(x, 1U), (y, 1U)], 1)])
  inspect(try_eval(p, [(x, 2), (y, 3)]), content="6")
  inspect(try_eval(p, [(x, 2)]), content="invalid assignment")
  inspect(try_eval(p, [(x, 2), (y, 3), (y, 4)]), content="invalid assignment")
}
```

### Bind existing index-addressed polynomials

`from_term_polynomial` and `from_sparse_polynomial` attach names to a `TermPolynomial` or `SparsePolynomial`. They trust that the polynomial uses no more variables than the context has, so check it yourself:

```moonbit
fn bind_checked(
  ctx : @immut.VariableContext,
  p : @immut.SparsePolynomial[Int],
) -> @immut.ContextPolynomial[Int]? {
  if p.arity() <= ctx.size() {
    Some(@immut.ContextPolynomial::from_sparse_polynomial(ctx, p))
  } else {
    None
  }
}

test "binding" {
  let ctx = @immut.VariableContext::from_names(["u"])
  let ok = @immut.SparsePolynomial::from_array([([3U], 1)])
  let too_wide = @immut.SparsePolynomial::from_array([([0U, 1], 1)])
  inspect(bind_checked(ctx, ok).unwrap(), content="1 * u^3")
  assert_true(bind_checked(ctx, too_wide) is None)
}
```

### Generic code over context polynomials

The `ContextOps` record and the `ContextualPolynomial` traits work for both `immut` and `mutable` context polynomials:

```moonbit
fn[P, A] add_and_eval(ops : @immut.ContextOps[P, A], a : P, b : P, at : Array[(@immut.Variable, A)]) -> A? {
  match ops.add_checked(a, b) {
    Some(sum) => ops.eval_named_checked(sum, at)
    None => None
  }
}

test "generic" {
  let ctx = @immut.VariableContext::from_names(["x"])
  let x = ctx.require_variable("x")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U)], 2)])
  let q = @immut.ContextPolynomial::constant(ctx, 1)
  debug_inspect(add_and_eval(@immut.ContextPolynomial::ops(), p, q, [(x, 4)]), content="Some(9)")
}
```

## Common pitfalls

- **Contexts must match.** `+`, `-` and `*` abort when the two contexts differ; use `add_checked` and `mul_checked`. Contexts with the same names in the same order are equal even when created separately.
- **Partial evaluation keeps variables in the context.** Do not expect the context of the result to shrink.
- **Substitution is one pass.** Replacements are not substituted into; call `substitute` again for chains.
- **Duplicates fail.** Listing a variable or name twice is an error, not "last one wins".
- **Binding trusts arity.** Check `arity() <= context.size()` before `from_term_polynomial` / `from_sparse_polynomial`.
- **No `==`.** Compare `to_sparse_polynomial()` results (and `context()`) instead.

## Next steps

- The [immut/context API](../../api/immut/context.md) lists every operation and its failure cases.
- The [immut/context design](../../design/immut/context.md) derives substitution as a ring homomorphism.
- [`Luna-Flow/type_theory`](https://lunaflow.cn/en/type_theory/) documents `Name`; the [mutable/context tutorial](../mutable/context.md) covers the mutable wrapper.
