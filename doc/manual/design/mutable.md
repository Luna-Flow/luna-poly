# mutable design

## Design goal

The `mutable` facade gives the execution-oriented half of `luna-poly` a single import, and the layer behind it lets algorithms update polynomials in place while computing exactly what the [`immut`](immut.md) layer computes. Performance comes first in this layer, but its side effects must stay where the caller can see them: in methods whose names say they mutate.

## Constraints

- The mutable layer must compute exactly what the immutable layer computes; two independent implementations of every algorithm would have to be kept in agreement by hand.
- MoonBit has no ownership or borrowing types, so aliasing between containers can only be prevented by copying at the boundaries.
- The facade must export the same names as `immut`.

## Mathematical background

A mutable polynomial is a *variable* whose value is a polynomial; the values are the same mathematical objects as in the immutable layer, in the same canonical forms. An in-place operation is an assignment $p \leftarrow p \circ q$, and the contract of the layer is

$$
\texttt{p.op\_inplace(q)}\ \text{ leaves } p \text{ equal to } \texttt{p\_before op q},
$$

with `p_before op q` computed by the immutable algorithms. Every observation (degree, terms, evaluation, equality) depends only on the current value.

## Design decisions

### A facade with the same names as `immut`

The facade re-exports `core`, the `luna-generic` algebra traits and the four mutable representations under the same names as the `immut` facade. Switching an algorithm between layers is mostly a change of import; generic code written against the capability traits or the operation records runs on both.

### Mutation is opt-in and named

Only `set_coefficient`, `clear`, `add_term_inplace` and the `*_inplace` methods change their receiver. Operators and every other method return new values. `x + y` never changes `x`, even for mutable types, so arithmetic expressions read the same in both layers.

### Canonical form is restored before every return

Each mutating method leaves the container canonical: trimmed coefficient arrays, sorted and merged term arrays, zero-free sparse maps. The invariants are the same as in `immut`, so `==`, `degree`, `size` and the shapes have the same meaning.

### Delegate the algorithms, specialize the updates

Non-trivial algorithms (Karatsuba, composition, derivative, powers, multivariate products, all of the context logic) are implemented once in `immut` and reached by conversion. The mutable packages implement directly only what benefits from in-place storage: coefficient setters, dense in-place addition, sparse single-term updates. The [consistency tests](consistency.md) check that both layers agree.

### Ownership at the boundaries

Every conversion copies or rebuilds storage, except where the stored value is itself immutable (the context cell), so no mutable container ever shares storage with an immutable value or with another container:

- `from_immut` and `to_immut` copy (dense, term, sparse) or share an immutable value (context);
- `copy()` gives an independent container;
- query methods such as `to_coefficients` and `to_terms` return fresh arrays.

### API symmetry with `immut`

The layers match in names, parameter order and checked-variant conventions. The documented differences are:

| Area | `immut` | `mutable` |
| --- | --- | --- |
| conversions | none | `from_immut`, `to_immut` on every type |
| copy and reset | values need neither | `copy`, `clear` (`Copyable`, `Clearable`, `MutablePolynomial`) |
| dense updates | rebuild with `from_coefficients` | `set_coefficient` (no checked form), `add_inplace`, `mul_inplace`, `scale_inplace` |
| term updates | `+`, `scale` | `add_term_inplace`, `add_inplace`, `mul_inplace`, `scale_inplace` |
| sparse updates | `add_term` (returns a new value) | `set_coefficient`, `add_term_inplace`, `add_inplace`, `mul_inplace`, `scale_inplace` |
| context binary ops | `add_checked`, `mul_checked` | `add_inplace`, `mul_inplace` (aborting); checked forms via `ops()` |
| context binding | takes immutable term/sparse polynomials | takes mutable term/sparse polynomials |
| substitution payload | `immut` `ContextSubstitutionValue` | its own `ContextSubstitutionValue` holding mutable polynomials |
| sparse `copy` bound | — | needs `Eq + AddMonoid` coefficients |
| `ExponentVector`, `Variable`, `VariableContext` | `core` types | the same `core` types |

## Correctness / invariants

- Canonical form after every public call, in every container.
- For every operation, the mutable result converted with `to_immut` equals the immutable result on the converted inputs.
- No mutable container shares mutable storage with any other value.
- Passing a container as its own argument (`p.add_inplace(p)`, `p.mul_inplace(p)`) gives $2p$ and $p^2$. The sparse `add_inplace` iterates over a snapshot of its argument so that this also holds when coefficients double to zero (see [mutable/sparse](mutable/sparse.md#pointwise-updates-on-the-tree)).

## Alternatives rejected

- **Mutable-only types without an immutable twin.** Value semantics is the safer default; mutation is an optimization chosen per call site.
- **Mutating operators.** They would make every `a * b` a possible side effect.
- **Independent algorithm implementations** for the mutable layer would double the code that must agree.

## Boundaries

- The facade adds no functions or types of its own.
- Containers are not snapshots: assigning a container to a second binding shares it; use `copy()`.
- Delegated operations pay a conversion cost; the layer optimizes updates, not the algorithms themselves.
- Everything the immutable layer does not do (division, factorization, Gröbner bases), this layer does not do either.
