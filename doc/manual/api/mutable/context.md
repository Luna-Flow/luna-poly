# mutable/context API

`Luna-Flow/luna-poly/mutable/context` provides a mutable `ContextPolynomial[A]`: a cell holding an [`immut/context`](../immut/context.md) polynomial that `add_inplace`, `mul_inplace` and `clear` replace. Every other operation delegates to the immutable implementation and has its semantics, failure cases and costs.

The types are re-exported by the [`mutable`](../mutable.md) facade, which the examples use. "As in immut" refers to the [immut/context API](../immut/context.md). The design is in [mutable/context design](../../design/mutable/context.md).

## Types

### `ContextPolynomial`

A mutable polynomial over a `VariableContext`.

```mbti
type ContextPolynomial[A] derive(@debug.Debug)
pub impl[A : Eq + @luna-generic.AddMonoid] Add for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Neg] Sub for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid + Mul] Mul for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.Zero + Neg] Neg for ContextPolynomial[A]
pub impl[A : Show + @luna-generic.Zero] Show for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] @core.Clearable for ContextPolynomial[A]
pub impl[A] @core.Copyable for ContextPolynomial[A]
pub impl[A : Eq + @luna-generic.AddMonoid] @core.MutablePolynomial for ContextPolynomial[A]
pub impl[A] @core.ContextualPolynomial for ContextPolynomial[A]
pub impl[A] @core.HasArity for ContextPolynomial[A]
pub impl[A] @core.HasContext for ContextPolynomial[A]
pub impl[A] @core.HasShape for ContextPolynomial[A]
pub impl[A] @core.HasTermCount for ContextPolynomial[A]
pub impl[A] @core.IsZero for ContextPolynomial[A]
```

### `ContextSubstitutionValue`

The replacement for one variable: a scalar or a mutable context polynomial over the same context. It is a separate type from the immutable `ContextSubstitutionValue`; it is converted when the substitution is delegated.

```mbti
pub(all) enum ContextSubstitutionValue[A] {
  Scalar(A)
  Polynomial(ContextPolynomial[A])
}
```

## Construction and conversion

### `ContextPolynomial::from_immut`, `ContextPolynomial::to_immut`

Wrap an immutable context polynomial, and return the immutable value currently held. Neither copies; this is safe because the held value is immutable and mutations replace it rather than change it.

```mbti
pub fn[A] ContextPolynomial::from_immut(@Luna-Flow/luna-poly/immut/context.ContextPolynomial[A]) -> Self[A]
pub fn[A] ContextPolynomial::to_immut(Self[A]) -> @Luna-Flow/luna-poly/immut/context.ContextPolynomial[A]
```

### `ContextPolynomial::from_named_terms_as_terms`, `ContextPolynomial::from_named_terms_as_terms_checked`, `ContextPolynomial::from_named_terms_as_sparse`, `ContextPolynomial::from_named_terms_as_sparse_checked`

Build from named terms, as in immut.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_terms(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_terms_checked(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_sparse(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_named_terms_as_sparse_checked(@Luna-Flow/luna-poly/core.VariableContext, Array[(Array[(@Luna-Flow/luna-poly/core.Variable, UInt)], A)]) -> Self[A]?
```

### `ContextPolynomial::from_term_polynomial`, `ContextPolynomial::from_sparse_polynomial`

Bind a *mutable* term or sparse polynomial to a context. The polynomial is converted to its immutable form, so later mutation of the argument does not affect the result. As in immut, the arity is not checked against the context size.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_term_polynomial(@Luna-Flow/luna-poly/core.VariableContext, @term.TermPolynomial[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::from_sparse_polynomial(@Luna-Flow/luna-poly/core.VariableContext, @sparse.SparsePolynomial[A]) -> Self[A]
```

### `ContextPolynomial::constant`, `ContextPolynomial::variable`, `ContextPolynomial::variable_checked`

As in immut.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::constant(@Luna-Flow/luna-poly/core.VariableContext, A) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + @luna-generic.One] ContextPolynomial::variable(@Luna-Flow/luna-poly/core.VariableContext, @Luna-Flow/luna-poly/core.Variable) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + @luna-generic.One] ContextPolynomial::variable_checked(@Luna-Flow/luna-poly/core.VariableContext, @Luna-Flow/luna-poly/core.Variable) -> Self[A]?
```

### `ContextPolynomial::copy`

Returns a new cell holding the same immutable value, $O(1)$ (also `Copyable::copy`). Mutating either cell afterwards does not affect the other.

```mbti
pub fn[A] ContextPolynomial::copy(Self[A]) -> Self[A]
```

## Queries and conversion

### `ContextPolynomial::context`, `ContextPolynomial::to_terms`, `ContextPolynomial::term_count`, `ContextPolynomial::arity`, `ContextPolynomial::is_zero`, `ContextPolynomial::shape`, `ContextPolynomial::to_string`

As in immut.

```mbti
pub fn[A] ContextPolynomial::context(Self[A]) -> @Luna-Flow/luna-poly/core.VariableContext
pub fn[A] ContextPolynomial::to_terms(Self[A]) -> Array[(@Luna-Flow/luna-poly/core.ExponentVector, A)]
pub fn[A] ContextPolynomial::term_count(Self[A]) -> Int
pub fn[A] ContextPolynomial::arity(Self[A]) -> Int
pub fn[A] ContextPolynomial::is_zero(Self[A]) -> Bool
pub fn[A] ContextPolynomial::shape(Self[A]) -> @Luna-Flow/luna-poly/core.PolynomialShape
pub fn[A : Show + @luna-generic.Zero] ContextPolynomial::to_string(Self[A]) -> String
```

### `ContextPolynomial::to_term_polynomial`, `ContextPolynomial::to_sparse_polynomial`

Return a new *mutable* term or sparse polynomial with the current terms.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::to_term_polynomial(Self[A]) -> @term.TermPolynomial[A]
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::to_sparse_polynomial(Self[A]) -> @sparse.SparsePolynomial[A]
```

## Evaluation and substitution

### `ContextPolynomial::eval`, `ContextPolynomial::eval_checked`, `ContextPolynomial::eval_named`, `ContextPolynomial::eval_named_checked`

As in immut.

```mbti
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval(Self[A], Array[A]) -> A
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_checked(Self[A], Array[A]) -> A?
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_named(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> A
pub fn[A : @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_named_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> A?
```

### `ContextPolynomial::eval_partial`, `ContextPolynomial::eval_partial_checked`, `ContextPolynomial::eval_partial_named`, `ContextPolynomial::eval_partial_named_checked`

Partial evaluation, returning a new mutable polynomial over the same context, as in immut.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, A)]) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_named(Self[A], Array[(@Luna-Flow/type_theory/core.Name, A)]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::eval_partial_named_checked(Self[A], Array[(@Luna-Flow/type_theory/core.Name, A)]) -> Self[A]?
```

### `ContextPolynomial::substitute`, `ContextPolynomial::substitute_checked`, `ContextPolynomial::substitute_names`, `ContextPolynomial::substitute_names_checked`

Simultaneous substitution by scalars or mutable polynomials over the same context, returning a new mutable polynomial, as in immut.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, ContextSubstitutionValue[A])]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_checked(Self[A], Array[(@Luna-Flow/luna-poly/core.Variable, ContextSubstitutionValue[A])]) -> Self[A]?
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_names(Self[A], Array[(@Luna-Flow/type_theory/core.Name, ContextSubstitutionValue[A])]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::substitute_names_checked(Self[A], Array[(@Luna-Flow/type_theory/core.Name, ContextSubstitutionValue[A])]) -> Self[A]?
```

## Arithmetic and mutation

### `ContextPolynomial::add_inplace`, `ContextPolynomial::mul_inplace`

Replace the held value by `self + other` or `self * other`. They abort when the contexts differ; there are no checked variants on the mutable type (use `ops().add_checked` or the immutable `add_checked` through `to_immut`).

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::add_inplace(Self[A], Self[A]) -> Unit
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] ContextPolynomial::mul_inplace(Self[A], Self[A]) -> Unit
```

### `ContextPolynomial::clear`

Replaces the held value by the zero polynomial over the same context (also `Clearable::clear`).

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::clear(Self[A]) -> Unit
```

### `ContextPolynomial::add`, `ContextPolynomial::sub`, `ContextPolynomial::mul`, `ContextPolynomial::neg`, `ContextPolynomial::pow`

Operators and powers returning new cells, as in immut; binary operators abort on different contexts.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid] ContextPolynomial::add(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Neg] ContextPolynomial::sub(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul] ContextPolynomial::mul(Self[A], Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.Zero + Neg] ContextPolynomial::neg(Self[A]) -> Self[A]
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::pow(Self[A], UInt) -> Self[A]
```

### `ContextPolynomial::ops`

The [`ContextOps`](../core.md#contextops) record; its `add_checked` and `mul_checked` return `None` on different contexts.

```mbti
pub fn[A : Eq + @luna-generic.AddMonoid + Mul + @luna-generic.One] ContextPolynomial::ops() -> @Luna-Flow/luna-poly/core.ContextOps[Self[A], A]
```

```moonbit
test "mutable context" {
  let ctx = @mutable.VariableContext::from_names(["x", "y"])
  let x = ctx.require_variable("x")
  let y = ctx.require_variable("y")
  let p = @mutable.ContextPolynomial::from_named_terms_as_sparse(ctx, [([(x, 1U)], 2)])
  let before = p.copy()
  p.add_inplace(@mutable.ContextPolynomial::from_named_terms_as_terms(ctx, [([(y, 1U)], 1)]))
  inspect(p, content="2 * x + 1 * y")
  inspect(before, content="2 * x")
  let y_poly = @mutable.ContextPolynomial::variable(ctx, y)
  inspect(p.substitute([(x, Polynomial(y_poly))]), content="3 * y")
  inspect(p.eval_named([(x, 1), (y, 1)]), content="3")
  p.clear()
  assert_true(p.is_zero())
  inspect(p.context(), content="VariableContext(x, y)")
}
```

## Deprecated

Hidden method forms kept for source compatibility:

| Deprecated | Replacement |
| --- | --- |
| `p.output(logger)` | `to_string` or string interpolation |
| `p.to_repr()` | `Repr(p)` or `debug_inspect` |
