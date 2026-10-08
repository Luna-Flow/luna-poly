# immut/context API

## Purpose

`Luna-Flow/luna-poly/immut/context` provides `ContextPolynomial[A]`, an immutable multivariate polynomial bound to a [`VariableContext`](../core.md#variablecontext). Terms refer to variables by name through the context, and the package adds named evaluation, partial evaluation and simultaneous substitution of variables by scalars or polynomials, including by `Luna-Flow/type_theory` names.

The polynomial is stored either as a [`TermPolynomial`](term.md) or as a [`SparsePolynomial`](sparse.md); you choose when you build it, and the choice affects cost, not results. The mathematics of substitution is in the [immut/context design](../../design/immut/context.md).

Most operations come in pairs: the plain form aborts on a contract violation, and the `*_checked` form returns `None` instead. The contract violations are listed with each item.

## Importing

The type is re-exported by the [`immut`](../immut.md) facade, which the examples use:

```moonbit nocheck
import {
  "Luna-Flow/luna-poly/immut",
}
```

To depend on this package alone, import `"Luna-Flow/luna-poly/immut/context"` instead; its names are the same.

## Types

### `ContextPolynomial`

A polynomial in the variables of a context $\Gamma$, together with $\Gamma$ itself.

```mbti
type ContextPolynomial[A] derive(@debug.Debug)
pub impl[A : Eq + @luna-generic.AddMonoid] Add for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Neg] Sub for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul] Mul for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + Neg] Neg for ContextPolynomial[A]
pub impl[A : Show + @luna-generic.Zero] Show for ContextPolynomial[A]
pub impl[A] @core.ContextualPolynomial for ContextPolynomial[A]
pub impl[A] @core.HasArity for ContextPolynomial[A]
pub impl[A] @core.HasContext for ContextPolynomial[A]
pub impl[A] @core.HasShape for ContextPolynomial[A]
pub impl[A] @core.HasTermCount for ContextPolynomial[A]
pub impl[A] @core.IsZero for ContextPolynomial[A]
```

There is no `Eq` instance; compare `to_terms()` (and `context()`) instead.

### `ContextSubstitutionValue`

The replacement for one variable in a substitution: a coefficient or a polynomial over the same context.

```mbti
pub(all) enum ContextSubstitutionValue[A] {
  Scalar(A)
  Polynomial(ContextPolynomial[A])
}
```

The constructors are type-directed, so inside a substitution list you can write `Scalar(2)` and `Polynomial(q)` without qualification.

## Construction

### `ContextPolynomial::from_named_terms_as_terms`, `ContextPolynomial::from_named_terms_as_sparse`

Build a polynomial from named terms, each a list of `(variable, exponent)` factors and a coefficient, stored as a term array or as a sparse map. Repeated factors of one variable add their exponents, and equal monomials merge. They abort when a factor uses a variable outside the context.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_terms(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_sparse(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]
```

### `ContextPolynomial::from_named_terms_as_terms_checked`, `ContextPolynomial::from_named_terms_as_sparse_checked`

Like the above, returning `None` when a factor uses a variable that the context does not contain.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_terms_checked(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_sparse_checked(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]?
```

### `ContextPolynomial::from_term_polynomial`, `ContextPolynomial::from_sparse_polynomial`

Bind an index-addressed polynomial to a context: variable $i$ of the polynomial becomes the context's variable with index $i$.

```mbti
pub fn[A] ContextPolynomial::from_term_polynomial(@Luna-Flow/luna-poly/core.VariableContext, @term.TermPolynomial[A]) -> Self[A]
pub fn[A] ContextPolynomial::from_sparse_polynomial(@Luna-Flow/luna-poly/core.VariableContext, @sparse.SparsePolynomial[A]) -> Self[A]
```

> [!WARNING]
> These two constructors do not check that the polynomial's arity is at most `context.size()`. If it is larger, `eval_named`, `eval_named_checked` and `to_string` abort with an index error instead of returning `None`. Check `polynomial.arity() <= context.size()` before calling them with untrusted input.

### `ContextPolynomial::constant`

The constant polynomial $c$ over a context, stored sparse.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::constant(@Luna-Flow/luna-poly/core.VariableContext, A) -> Self[A]
```

### `ContextPolynomial::variable`

The polynomial consisting of one variable of the context, stored sparse. It aborts when the context does not contain the variable.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + @luna-generic.One] ContextPolynomial::variable(@Luna-Flow/luna-poly/core.VariableContext, @Luna-Flow/luna-poly/core.Variable) -> Self[A]
```

### `ContextPolynomial::variable_checked`

Like `variable`, returning `None` for a variable outside the context.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + @luna-generic.One] ContextPolynomial::variable_checked(@Luna-Flow/luna-poly/core.VariableContext, @Luna-Flow/luna-poly/core.Variable) -> Self[A]?
```

```moonbit
test "construction" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [
    ([(x, 2U)], 1),
    ([(x, 1U), (y, 1U)], 3),
    ([(y, 1U), (x, 1U)], 1),
    ([], 4),
  ])
  inspect(p, content="4 + 1 * x^2 + 4 * x * y")
  let q : @immut.ContextPolynomial[Int] = @immut.ContextPolynomial::variable(ctx, y)
  inspect(q, content="1 * y")
  let stranger = @immut.VariableContext::from_names(["z"]).require_variable("z")
  let missing : @immut.ContextPolynomial[Int]? = @immut.ContextPolynomial::variable_checked(ctx, stranger)
  assert_true(missing is None)
}
```

## Queries and conversion

### `ContextPolynomial::context`

Returns the context the polynomial is bound to.

```mbti
pub fn[A] ContextPolynomial::context(Self[A]) -> @Luna-Flow/luna-poly/core.VariableContext
```

### `ContextPolynomial::to_terms`

Returns the index-addressed terms in the order of the storage: descending for term storage, ascending for sparse storage.

```mbti
pub fn[A] ContextPolynomial::to_terms(Self[A]) -> Array[(@Luna-Flow/luna-poly/core.ExponentVector, A)]
```

### `ContextPolynomial::to_term_polynomial`, `ContextPolynomial::to_sparse_polynomial`

Return the polynomial in the requested index-addressed storage, converting if needed. The context is dropped.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::to_term_polynomial(Self[A]) -> @term.TermPolynomial[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::to_sparse_polynomial(Self[A]) -> @sparse.SparsePolynomial[A]
```

### `ContextPolynomial::term_count`, `ContextPolynomial::arity`, `ContextPolynomial::is_zero`, `ContextPolynomial::shape`

The number of terms, the number of variables in use (the highest used index plus one), whether there are no terms, and `PolynomialShape::Contextual(context~, arity~, term_count~)`.

```mbti
pub fn[A] ContextPolynomial::term_count(Self[A]) -> Int
pub fn[A] ContextPolynomial::arity(Self[A]) -> Int
pub fn[A] ContextPolynomial::is_zero(Self[A]) -> Bool
pub fn[A] ContextPolynomial::shape(Self[A]) -> @Luna-Flow/luna-poly/core.PolynomialShape
```

### `ContextPolynomial::to_string`

Renders the terms in storage order as `c * x^2 * y`, using the context's variable names; zero prints as the coefficient zero.

```mbti
pub fn[A : Show + @luna-generic.Zero] ContextPolynomial::to_string(Self[A]) -> String
```

## Evaluation

### `ContextPolynomial::eval`

Evaluates with values given by index, like `TermPolynomial::eval`: `values[i]` is the value of the context's variable $i$. It aborts when `values.length() < arity()`.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval(Self[A], Array[A]) -> A
```

### `ContextPolynomial::eval_checked`

Like `eval`, returning `None` when `values` is shorter than `arity()`.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_checked(Self[A], Array[A]) -> A?
```

### `ContextPolynomial::eval_named`

Evaluates with values given by variable. Every context variable with index below `arity()` must be assigned exactly once; assignments to later variables of the context are accepted and ignored. It aborts on a variable outside the context, a missing assignment, or a duplicate assignment.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_named(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> A
```

### `ContextPolynomial::eval_named_checked`

Like `eval_named`, returning `None` in the same situations.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_named_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> A?
```

```moonbit
test "evaluation" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_terms(ctx, [([(x, 2U)], 1), ([(x, 1U), (y, 1U)], 3)])
  inspect(p.eval([2, 5]), content="34")
  inspect(p.eval_named([(y, 5), (x, 2)]), content="34")
  assert_true(p.eval_named_checked([(x, 2)]) is None)
  assert_true(p.eval_named_checked([(x, 2), (x, 3), (y, 5)]) is None)
}
```

## Partial evaluation and substitution

All forms below return a polynomial over the *same* context; assigned variables simply no longer occur in it. Replacements are applied simultaneously, in one pass: replacement polynomials are not substituted into again.

### `ContextPolynomial::substitute`

Replaces each listed variable by a scalar or by a polynomial over an equal context, leaving unlisted variables unchanged. It aborts when a variable is outside the context, a variable is listed twice, or a replacement polynomial has a different context.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, ContextSubstitutionValue[A])]) -> Self[A]
```

### `ContextPolynomial::substitute_checked`

Like `substitute`, returning `None` in the same situations.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, ContextSubstitutionValue[A])]) -> Self[A]?
```

### `ContextPolynomial::substitute_names`

Like `substitute`, with variables named by `Luna-Flow/type_theory` `Name` values, resolved in the polynomial's context. It also aborts when a name is not in the context; two entries with the same name count as a duplicate.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_names(Self[A], Array[(@Luna-Flow/type_theory/core.Name, ContextSubstitutionValue[A])]) -> Self[A]
```

### `ContextPolynomial::substitute_names_checked`

Like `substitute_names`, returning `None` in the same situations.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_names_checked(Self[A], Array[(@Luna-Flow/type_theory/core.Name, ContextSubstitutionValue[A])]) -> Self[A]?
```

### `ContextPolynomial::eval_partial`, `ContextPolynomial::eval_partial_checked`

Substitute scalars for some variables: `eval_partial(a)` is `substitute` with every value wrapped in `Scalar`, with the same failure cases.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> Self[A]?
```

### `ContextPolynomial::eval_partial_named`, `ContextPolynomial::eval_partial_named_checked`

The same with `type_theory` names: `substitute_names` with scalar values.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_named(Self[A], Array[(@Luna-Flow/type_theory/core.Name, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_named_checked(Self[A], Array[(@Luna-Flow/type_theory/core.Name, A)]) -> Self[A]?
```

The result of every substitution is stored sparse, whatever the input storage.

```moonbit
test "substitution" {
  let ctx = @immut.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 2U)], 1), ([(y, 1U)], 1)])
  let y_plus_1 = @immut.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(y, 1U)], 1), ([], 1)])
  inspect(p.substitute([(x, Polynomial(y_plus_1))]), content="1 + 3 * y + 1 * y^2")
  inspect(p.eval_partial([(x, 3)]), content="9 + 1 * y")
  let named = p.eval_partial_named([(y.to_type_theory_name(), 10)])
  inspect(named, content="10 + 1 * x^2")
  assert_true(p.substitute_checked([(x, Scalar(1)), (x, Scalar(2))]) is None)
  assert_true(p.substitute_names_checked([(@tt_core.Name::new("w"), Scalar(1))]) is None)
}
```

## Arithmetic

### `ContextPolynomial::add`, `ContextPolynomial::sub`, `ContextPolynomial::mul`, `ContextPolynomial::neg`

The operators `+`, `-`, `*` and unary `-`. Binary operators abort when the two contexts differ. Two term-stored operands give a term-stored result, two sparse ones a sparse result, and mixed operands a sparse result. Negation keeps the storage.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] ContextPolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] ContextPolynomial::mul(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] ContextPolynomial::neg(Self[A]) -> Self[A]
```

### `ContextPolynomial::add_checked`, `ContextPolynomial::mul_checked`

Like `+` and `*`, returning `None` when the contexts differ.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::add_checked(Self[A], Self[A]) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] ContextPolynomial::mul_checked(Self[A], Self[A]) -> Self[A]?
```

### `ContextPolynomial::pow`

Returns $p^e$ in the same storage; `pow(0)` is the constant one.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::pow(Self[A], UInt) -> Self[A]
```

```moonbit
test "arithmetic" {
  let ctx = @immut.VariableContext::from_names(["x"])
  let x = ctx.require_variable("x")
  let a = @immut.ContextPolynomial::from_named_terms_as_terms(ctx, [([(x, 1U)], 1)])
  let b = @immut.ContextPolynomial::constant(ctx, 1)
  inspect((a + b).pow(2), content="1 + 2 * x + 1 * x^2")
  let other = @immut.ContextPolynomial::constant(@immut.VariableContext::from_names(["t"]), 1)
  assert_true(a.add_checked(other) is None)
  assert_true(a.mul_checked(b) is Some(_))
}
```

## Generic access

### `ContextPolynomial::ops`

Returns the [`ContextOps`](../core.md#contextops) record: `from_terms` builds a term-stored polynomial, and `eval_named_checked`, `add_checked` and `mul_checked` are the methods above.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::ops() -> @Luna-Flow/luna-poly/core.ContextOps[Self[A], A]
```

```moonbit
test "ops" {
  let ctx = @immut.VariableContext::from_names(["x"])
  let x = ctx.require_variable("x")
  let ops = @immut.ContextPolynomial::ops()
  let p = ops.from_terms(ctx, [(@immut.ExponentVector::from_array([1U]), 2)])
  debug_inspect(ops.eval_named_checked(p, [(x, 5)]), content="Some(10)")
}
```

## Deprecated

Hidden method forms kept for source compatibility:

| Deprecated | Replacement |
| --- | --- |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
