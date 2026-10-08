# mutable/context design

## Design goal

The mutable `ContextPolynomial[A]` gives named-variable polynomials the same in-place interface as the other mutable containers (`add_inplace`, `mul_inplace`, `clear`, `copy`) without a second implementation of contexts, named evaluation and substitution.

## Mathematical background

The semantics are those of [`immut/context`](../immut/context.md#mathematical-background): a pair $(\Gamma, f)$ with $f \in R[\Gamma]$, substitution as the ring homomorphism $\varphi_\sigma$, and partial evaluation as substitution by scalars. A mutable context polynomial is a variable whose value is such a pair; in-place operations are assignments $f \leftarrow f + g$ and $f \leftarrow f g$ inside the fixed ring $R[\Gamma]$.

## Design decisions

### A mutable cell around an immutable value

**Choice.** The type is a record with one mutable field holding an `immut/context` polynomial. Every query, evaluation and substitution forwards to the held value; `add_inplace`, `mul_inplace` and `clear` compute a new immutable value and store it in the field.

**Why.** Context handling has the most validation rules of the library (membership, duplicates, name resolution, context equality). Implementing them once guarantees that both layers accept and reject exactly the same calls and produce the same canonical results. Because the held value is immutable, sharing it is safe:

- `copy` is $O(1)$: the new cell holds the same immutable value, and a later in-place operation on either cell replaces that cell's value without touching the other;
- `to_immut` returns the held value without copying, and `from_immut` wraps a value without copying, for the same reason.

### A separate substitution payload

`ContextSubstitutionValue` is redefined here so that `Polynomial(p)` can carry a *mutable* context polynomial. Substitution converts each payload to the immutable one by reading the held value, then delegates. The result is a new mutable cell; the receiver is not changed by substitution or partial evaluation.

### Only the binary in-place operations are added

The in-place set is `add_inplace`, `mul_inplace` and `clear`. Substitution and partial evaluation return new cells, matching the immutable API, because a substitution result is a different polynomial rather than an update of the old one. The mutable type has no `add_checked` or `mul_checked` methods; the checked forms are reachable through `ops()` or through `to_immut()`.

### Clearing keeps the context

`clear` sets the value to the zero polynomial over the *same* context, stored sparse. The container stays in $R[\Gamma]$, so later `add_inplace` calls with polynomials over $\Gamma$ remain valid.

## Correctness / invariants

- **Same semantics as immut.** Every non-mutating method returns `from_immut(self.to_immut().op(...))`.
- **Context fixed.** In-place operations abort on a different context, so the context of a cell never changes.
- **Isolation.** Mutating one cell never changes another cell or an immutable value obtained with `to_immut`.
- **Costs** are those of the immutable operations; `copy`, `from_immut` and `to_immut` are $O(1)$.

## Alternatives rejected

- **A mutable re-implementation** over mutable term and sparse containers would allow true in-place term updates but would duplicate every validation rule.
- **Mutating substitution** (`substitute_inplace`) is not provided; substitution is a homomorphism applied to a value, and assigning its result back is one line.

## Boundaries

- No per-term in-place updates; convert with `to_sparse_polynomial()` for that and bind the result again.
- No checked binary methods on the type itself.
- All [immut/context boundaries](../immut/context.md#boundaries) apply, including the unchecked arity of `from_term_polynomial` and `from_sparse_polynomial`.
