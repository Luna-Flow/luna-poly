# mutable/sparse design

## Design goal

The mutable `SparsePolynomial[A]` is the accumulator of the library: a multivariate polynomial that absorbs terms one at a time in logarithmic time, as needed by algorithms that generate terms incrementally (expanding products, collecting contributions, building polynomials from data).

## Constraints

- Single-term updates must be logarithmic, which is the reason to choose this container.
- The stored map must stay zero-free after every call, so equality and `get` keep their meaning.
- Results must equal those of `immut/sparse`.

## Mathematical background

The container holds the partial map $\operatorname{supp} f \to R \setminus \{0\}$, $\alpha \mapsto f_\alpha$, of a polynomial $f$ (see the [immut/sparse design](../immut/sparse.md#mathematical-background)). Adding a term is a pointwise update of that map:

$$
(f + c\,x^\alpha)_\beta =
\begin{cases}
f_\alpha + c & \beta = \alpha, \\
f_\beta & \beta \neq \alpha,
\end{cases}
$$

so only the key $\alpha$ changes, and it leaves the support exactly when $f_\alpha + c = 0$.

## Design decisions

### Pointwise updates on the tree

**Choice.** `set_coefficient` and `add_term_inplace` implement the formula above directly on the AVL tree: one lookup, then an insertion, an update or a removal, each $O(\log m)$ comparisons. The invariant "no zero values" is maintained locally: `set_coefficient(α, 0)` removes the key, and `add_term_inplace` removes it when the sum becomes zero and ignores a zero increment. `add_inplace(g)` is $n$ such updates, $O(n \log(m + n))$, which is the reason to choose this container over [`mutable/term`](term.md) for accumulation.

`p.add_inplace(p)` iterates over the tree it is updating. While every update only rewrites the value of the key being visited, the tree keeps its shape and the result is $2p$. When a doubled coefficient is zero, which happens with zero divisors such as $2 \cdot (-2^{31}) = 0$ in `Int`, `add_term_inplace` *removes* that key, the AVL tree rebalances in the middle of the iteration, and later keys can be visited twice or skipped. For $p = -2^{31} + x + x^2 + x^3$ over `Int`, `p.add_inplace(p)` gives $4x + 2x^2 + 2x^3$ instead of $2x + 2x^2 + 2x^3$. Iterating over a snapshot (`other.to_terms()`) would remove the problem; until then, write `p.add_inplace(p.copy())`.

### Whole-polynomial operations delegate

`*`, `mul_inplace`, `pow` and `to_immut` go through the immutable type, and `mul_inplace` and `scale_inplace` compute their result fully before clearing and refilling the tree. Results therefore agree with `immut/sparse` by construction, and `p.mul_inplace(p)` squares `p`.

### Copies rebuild

`copy` rebuilds a new tree from the term list through `from_terms`, $O(m \log m)$. This needs `Eq + AddMonoid` on the coefficients, so `Copyable` and the `MutablePolynomial` bundle carry that bound for this type, unlike the dense and term containers whose `copy` is an unbounded array copy.

### Costs compared with the other multivariate containers

| Operation | `immut/sparse` | `mutable/term` | `mutable/sparse` |
| --- | --- | --- | --- |
| add one term | $O(m \log m)$ | $O(m \log m)$ | $O(\log m)$ |
| add $n$ terms | $O((m+n)\log(m+n))$ | $O(n(m+n)\log(m+n))$ | $O(n \log(m+n))$ |
| set a coefficient | rebuild | not available | $O(\log m)$ |
| coefficient lookup | $O(\log m)$ | $O(m)$ | $O(\log m)$ |

## Correctness / invariants

- **No zero values; canonical keys.** Maintained by every mutating method; `==` (comparing ascending term lists) is polynomial equality.
- **Agreement with immut**: `from_immut(a).op(...).to_immut() == a.op(...)`, and in-place operations leave the receiver equal to the operator result.
- **Isolation**: `copy`, `to_terms`, `from_immut` and `to_immut` build new storage.
- **Aliasing**: `mul_inplace(p)` on itself gives $p^2$. `add_inplace(p)` on itself gives $2p$ only when no coefficient doubles to zero; otherwise the result is wrong, as shown above.

## Alternatives rejected

- **A hash map.** Expected $O(1)$ updates, but unordered: equality and printing would need sorting, and iteration order would differ from the immutable type.
- **Allowing zero values and filtering on read.** Simpler updates, but `size`, `is_zero` and `==` would all need to skip zeros.

## Boundaries

- `copy` is $O(m \log m)$, not a constant-time snapshot.
- No ordered traversal from the leading term downwards without materializing `to_terms()`.
- Variables are positional; for names use [`mutable/context`](context.md).
- Everything [`immut/sparse`](../immut/sparse.md#boundaries) excludes is excluded here as well.
