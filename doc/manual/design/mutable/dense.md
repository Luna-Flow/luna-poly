# mutable/dense design

## Design goal

The mutable `DensePolynomial[A]` lets an algorithm build or update a univariate polynomial in place (set coefficients one by one, accumulate sums, multiply into a running product) without allocating a new value for every step, while giving exactly the same mathematical results as [`immut/dense`](../immut/dense.md).

## Mathematical background

The represented object is the same as in the immutable package: a polynomial $f = \sum_i c_i x^i \in R[x]$ stored as its trimmed coefficient word (see the [immut/dense design](../immut/dense.md#canonical-form-trim-trailing-zeros)). A mutable container is a *variable* holding such a value. An in-place operation $\mathtt{op\_inplace}(p, q)$ is the assignment $p \leftarrow p \circ q$; it must leave the container holding the canonical word of the new value.

## Design decisions

### The same canonical form, restored after every mutation

**Invariant.** Between public calls, the stored array never ends in a zero coefficient.

Each mutating method re-establishes it. `set_coefficient(k, c)` grows the array with zeros when $k \ge n$, writes $c$, and trims: if $c = 0$ was written at the top, the degree drops to the next non-zero coefficient. `add_inplace` adds into the existing array and trims, because cancellation can lower the degree. `mul_inplace` and `scale_inplace` assign a freshly computed canonical array. Because the invariant holds, `degree`, `length`, `==` and `compare` mean exactly what they mean for the immutable type.

### Mutation is explicit and limited

Only `set_coefficient`, `clear`, `add_inplace`, `mul_inplace` and `scale_inplace` change the receiver. The operators `+`, `-`, `*`, unary `-` and every other method return new values: `a + b` copies `a` and adds `b` into the copy. Code that reads `p * q` therefore never has a hidden side effect, and mutation is visible at the call site by its name.

### Aliasing is safe

Passing the receiver as the argument is allowed. For `p.add_inplace(p)`, the loop computes $c_i \leftarrow c_i + c_i$ index by index; at step $i$ both operands read index $i$ before it is written, and later steps read only later indexes, so the result is $2p$. `mul_inplace` and `scale_inplace` compute the whole result before assigning it, so $p \leftarrow p \cdot p$ squares $p$ correctly.

### Delegation to the immutable implementation

Operations that would duplicate non-trivial algorithms (`scale`, `pow`, `karatsuba`, `substitute`, `derivative`, `monomial_checked`) convert to the immutable type, call it, and convert back. Each conversion copies the coefficients, $O(n)$, which is dominated by the algorithm itself. The two layers therefore cannot drift apart on these operations. Addition, schoolbook multiplication and Horner evaluation, which are short, are implemented directly on the array; the consistency tests check that they agree with the immutable ones.

### Conversion copies

`from_immut` copies the immutable coefficients into a new array, and `to_immut` builds an immutable value from a copy. A snapshot taken with `to_immut` stays unchanged however the mutable polynomial is modified afterwards, and an immutable value handed to `from_immut` is never affected by later mutation. `copy` (the `Copyable` capability) duplicates the array, so the copy and the original evolve independently.

### Costs compared with the immutable type

| Operation | `immut/dense` | `mutable/dense` |
| --- | --- | --- |
| set one coefficient | rebuild with `from_coefficients`, $O(n)$ | `set_coefficient`, $O(n)$ (the trim copies) |
| $p \leftarrow p + q$ | new value, $O(n)$ | `add_inplace`, $O(n)$, reuses the array |
| $p \leftarrow p \cdot q$ | $O(mn)$ | $O(mn)$, plus one assignment |
| `pow`, `substitute`, `karatsuba` | direct | the same plus $O(n)$ conversions |

Trimming in `set_coefficient` copies the array, so each call is $O(n)$ in the current implementation; the saving over the immutable type comes from avoiding a new polynomial value per step and from `add_inplace` working on the existing storage.

## Correctness / invariants

- **Canonical form** after every public call; `==` is polynomial equality.
- **Agreement with immut.** For every non-mutating operation, `from_immut(a).op(...).to_immut() == a.op(...)`; in-place operations leave the receiver equal to the corresponding operator result.
- **Isolation.** `copy`, `to_immut`, `from_immut` and `to_coefficients` never share storage with the receiver.
- **Aliasing.** `p.add_inplace(p)`, `p.mul_inplace(p)` compute $2p$ and $p^2$.
- **Aborts.** `set_coefficient`, `scale_inplace`, `scale`, `coefficient` and `monomial` abort on a negative power, like their immutable counterparts.

## Alternatives rejected

- **Mutating operators.** Making `+` or `*` update the left operand would be cheaper in loops but would make every arithmetic expression a potential side effect.
- **Sharing the array with immutable snapshots.** Copy-on-write would make `to_immut` $O(1)$ but needs reference tracking that MoonBit arrays do not provide.
- **A separate algorithm set.** Re-implementing Karatsuba or composition for the mutable type would double the code that has to be kept consistent.

## Boundaries

- No `set_coefficient_checked`; validate the power yourself or use the immutable `scale_checked` / `monomial_checked`.
- Mutating a polynomial while another computation iterates over its `to_coefficients()` result is safe only because that result is a copy.
- A mutable container shared between two parts of a program is updated for both; give each part its own `copy()` when that is not intended.
- Everything that [`immut/dense`](../immut/dense.md#boundaries) does not do, this package does not do either.
