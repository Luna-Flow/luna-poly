# mutable/context tutorial

This tutorial shows how to accumulate a named-variable polynomial in place and how to substitute and evaluate it with the same calls as in the immutable layer.

## Quick start

```bash
moon add Luna-Flow/luna-poly@0.2.0
```

```text
import {
  "Luna-Flow/luna-poly/mutable",
}
```

```moonbit
test "mutable context quick start" {
  let ctx = @mutable.VariableContext::from_names(["x"])
  let x = ctx.require_variable("x")
  let p = @mutable.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U)], 2)])
  p.add_inplace(@mutable.ContextPolynomial::constant(ctx, 1))
  inspect(p, content="1 + 2 * x")
  inspect(p.eval_named([(x, 4)]), content="9")
}
```

## Everyday tasks

### Accumulate a sum of products

```moonbit
test "accumulate" {
  let ctx = @mutable.VariableContext::from_names(["a", "b"])
  let a : @mutable.ContextPolynomial[Int] = @mutable.ContextPolynomial::variable(ctx, ctx.require_variable("a"))
  let b : @mutable.ContextPolynomial[Int] = @mutable.ContextPolynomial::variable(ctx, ctx.require_variable("b"))
  let total = @mutable.ContextPolynomial::constant(ctx, 0)
  for k in 1..<=3 {
    let term = a.pow(k.reinterpret_as_uint())
    term.mul_inplace(b)
    total.add_inplace(term)
  }
  inspect(total, content="1 * a * b + 1 * a^2 * b + 1 * a^3 * b")
}
```

### Substitute and evaluate

Substitution returns a new polynomial and leaves the receiver as it was:

```moonbit
test "substitute" {
  let ctx = @mutable.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @mutable.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 2U)], 1), ([(y, 1U)], 1)])
  let q = p.eval_partial([(y, 5)])
  inspect(q, content="5 + 1 * x^2")
  inspect(p, content="1 * y + 1 * x^2")
  let named = p.substitute_names([(x.to_type_theory_name(), Scalar(3))])
  inspect(named, content="9 + 1 * y")
}
```

### Snapshot and reset

```moonbit
test "snapshot" {
  let ctx = @mutable.VariableContext::from_names(["x"])
  let x = ctx.require_variable("x")
  let p = @mutable.ContextPolynomial::from_named_terms_as_terms(ctx, [([(x, 3U)], 1)])
  let saved = p.copy()
  let frozen = p.to_immut()
  p.clear()
  inspect(saved, content="1 * x^3")
  inspect(frozen, content="1 * x^3")
  assert_true(p.is_zero())
}
```

## Going further

### Check contexts without aborting

The mutable type has no `add_checked`; use the operation record:

```moonbit
test "checked through ops" {
  let ops = @mutable.ContextPolynomial::ops()
  let p = @mutable.ContextPolynomial::constant(@mutable.VariableContext::from_names(["x"]), 1)
  let q = @mutable.ContextPolynomial::constant(@mutable.VariableContext::from_names(["t"]), 1)
  assert_true(ops.add_checked(p, q) is None)
  assert_true(ops.add_checked(p, p) is Some(_))
}
```

## Common pitfalls

- **Context mismatches abort.** `add_inplace`, `mul_inplace` and the operators abort when contexts differ.
- **Separate payload type.** In the mutable layer, `Polynomial(p)` takes a mutable `ContextPolynomial`.
- **Binding trusts arity**, as in the immutable layer.

## Next steps

- The [mutable/context API](../../api/mutable/context.md) and [mutable/context design](../../design/mutable/context.md).
- The [immut/context tutorial](../immut/context.md) explains substitution and partial evaluation in depth.
