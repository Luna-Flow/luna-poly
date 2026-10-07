# luna-poly

`luna-poly` 0.2.0 provides canonical polynomial types for MoonBit with explicit
immutable and mutable execution models.

## Packages

- `Luna-Flow/luna-poly/core`: shared capability traits, named-variable types,
  exponent vectors, and functional operation records.
- `Luna-Flow/luna-poly/immut/dense`, `/term`, `/sparse`, `/context`:
  immutable implementation packages.
- `Luna-Flow/luna-poly/mutable/dense`, `/term`, `/sparse`, `/context`:
  mutable implementation packages.
- `Luna-Flow/luna-poly/immut`: value-oriented polynomial types. Updates return
  new values and constructors copy caller-owned arrays. This is a facade that
  re-exports `core` capabilities and immutable implementations.
- `Luna-Flow/luna-poly/mutable`: execution-oriented polynomial containers with
  explicit setters and `_inplace` methods. This is a facade that re-exports
  `core` capabilities and mutable implementations.

Both packages provide `DensePolynomial`, `TermPolynomial`, `SparsePolynomial`,
`ExponentVector`, and context-aware polynomial helpers. Dense polynomials use
ascending coefficient arrays; `TermPolynomial` uses a sorted term array;
`SparsePolynomial` uses an ordered map. Every representation removes zero terms
and maintains a canonical form.

`Variable` and `VariableContext` provide the named-variable layer. A
`ContextPolynomial` binds a variable context to either term-array or sparse
storage, supports both indexed and named evaluation, and exposes checked
variants for context or assignment failures.

Context-aware polynomials integrate with `Luna-Flow/type_theory` names for
substitution-facing APIs. `Variable::to_type_theory_name` and
`VariableContext::variable_by_type_theory_name` bridge polynomial variables to
the shared semantic substrate. `ContextPolynomial::substitute_checked` replaces
variables with scalars or same-context polynomials, while
`eval_partial_checked` is the scalar-only partial-evaluation specialization.
These operations preserve polynomial-owned canonicalization; `type_theory`
provides the shared naming/substitution vocabulary, not polynomial storage or
normalization.

External code should use capability traits such as `UnivariatePolynomial`,
`MultivariatePolynomial`, `ContextualPolynomial`, and `MutablePolynomial` when
it does not care about the concrete storage. Concrete types also expose
`Type::ops()` records for functional-style generic algorithms.

The shared `core` layer also exposes lightweight shape metadata through
`PolynomialShape` and `HasShape`. Generic code can inspect univariate length,
multivariate arity and term count, or context compatibility before combining
values. Checked APIs such as `coefficient_checked`, `scale_checked`,
`eval_checked`, substitution, and context `*_checked` methods return `None` for
contract failures; the shorter convenience methods keep the existing aborting
behavior.

The `immut` and `mutable` facades re-export the common algebra traits from
`Luna-Flow/luna-generic`, including `Zero`, `One`, `AddMonoid`, `MulMonoid`,
`Semiring`, `Ring`, `Field`, and `Num`, so polynomial APIs can be used with the
same capability style as `Luna-Flow/linear-algebra`.

Natural powers implement `Luna-Flow/arithmetic.PowNatChecked`. The convenience
`pow(UInt)` methods use the same semantics: exponent zero returns the
multiplicative identity, including for the zero polynomial.

## Example

```moonbit
let p = @immut.DensePolynomial::from_coefficients([1, 2, 3])
let q = p.pow(2)
let value = q.eval(2)

let buffer = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
buffer.set_coefficient(1, 5)
buffer.add_inplace(@mutable.DensePolynomial::from_coefficients([-1, -5, -3]))

let context = @immut.VariableContext::from_names(["x", "y"])
let x = context.require_variable("x")
let y = context.require_variable("y")
let named = @immut.ContextPolynomial::from_named_terms_as_sparse(
  context,
  [([(x, 2U)], 1), ([(x, 1U), (y, 1U)], 3), ([], 4)],
)
let named_value = named.eval_named([(x, 2), (y, 5)])

let partial = named.eval_partial_named([(x.to_type_theory_name(), 2)])
let y_plus_one = @immut.ContextPolynomial::from_named_terms_as_sparse(
  context,
  [([(y, 1U)], 1), ([], 1)],
)
let substituted = named.substitute([(x, @immut.Polynomial(y_plus_one))])
```

The 0.2.0 package layout is intentionally source-incompatible with the former
root package. Import `/immut` or `/mutable` explicitly.

## Documentation

The manual is published at <https://luna-flow.github.io/en/luna-poly/>, with
Chinese and Japanese translations. Its English source lives in
[`doc/manual/`](doc/manual/index.md) and includes API references, tutorials,
and design notes for `immut` and `mutable`.
