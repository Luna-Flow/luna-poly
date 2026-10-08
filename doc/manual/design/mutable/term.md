# mutable/term design

## Design goal

The mutable `TermPolynomial[A]` is a container for a multivariate polynomial in distributed form that algorithms can update step by step (add a term, multiply in a factor, scale by a monomial) while it keeps the canonical sorted term array of [`immut/term`](../immut/term.md) at every observable point.

## Mathematical background

The container holds the canonical term list of some $f \in R[x_0, x_1, \dots]$: terms $(\alpha_k, c_k)$ with $\alpha_1 \succ \alpha_2 \succ \cdots$ in the [monomial order](../core.md#the-monomial-order) and every $c_k \neq 0$. The in-place operations are assignments:

$$
\begin{aligned}
\texttt{add\_term\_inplace}(\alpha, c) &: f \leftarrow f + c\,x^\alpha, \\
\texttt{add\_inplace}(g) &: f \leftarrow f + g, \\
\texttt{mul\_inplace}(g) &: f \leftarrow f g, \\
\texttt{scale\_inplace}(\gamma, c) &: f \leftarrow c\,x^\gamma f .
\end{aligned}
$$

## Design decisions

### Replace the array, never edit it partially

Every mutating method computes a complete canonical array and then assigns it to the private field. A reader can never observe a half-sorted or unmerged state, and aliasing is harmless: in `p.add_inplace(p)` the loop iterates over the old array while the field is reassigned, giving $2p$; `p.mul_inplace(p)` computes $p^2$ before assigning.

### Single-term insertion reuses the shared normalization

`add_term_inplace` appends the new term to a copy of the array and renormalizes it with the immutable constructor, $O(m \log m)$. Binary search followed by an insertion or a merge would be $O(m)$ (dominated by shifting the array), but would duplicate the canonicalization logic. The choice favours one canonicalization routine for both layers.

`add_inplace(g)` inserts the terms of $g$ one at a time, so its cost is $O(n\,(m + n)\log(m + n))$ for $n$ terms in $g$, and `+` (which copies and calls `add_inplace`) inherits that cost. This is the main performance difference from `immut/term`, whose `+` normalizes once in $O((m+n)\log(m+n))$. For large sums, convert with `to_immut`, add there, and convert back, or build the term list and call `from_terms` once.

### Scaling keeps the order

`scale_inplace` maps $(\alpha, a) \mapsto (\alpha + \gamma, ac)$ and drops vanishing products without sorting, by the same argument as for the immutable type: $\alpha \mapsto \alpha + \gamma$ is strictly increasing in a monomial order, so a strictly descending array stays strictly descending ([derivation](../immut/term.md#scaling-and-negation-keep-the-order)).

### Products and powers delegate

`*`, `mul_inplace` and `pow` convert both operands to the immutable type, multiply there and convert back. The conversions cost $O(m \log m)$ each, which is small next to the $O(mn \log(mn))$ product, and they guarantee the same result as the immutable layer.

## Correctness / invariants

- **Canonical form** (strictly descending, merged, zero-free) after every public call; the derived `==` is polynomial equality.
- **Agreement with immut**: `from_immut(a).op(...).to_immut() == a.op(...)` for every operation, and in-place operations leave the receiver equal to the corresponding operator result.
- **Isolation**: `copy`, `to_terms`, `coefficients`, `from_immut` and `to_immut` never share the array with the receiver.
- **Complexity**: `add_term_inplace` $O(m \log m)$; `add_inplace` and `+` $O(n(m+n)\log(m+n))$; `mul_inplace` and `*` $O(mn\log(mn))$; `scale_inplace` $O(m)$.

## Alternatives rejected

- **Lazy normalization** (append now, sort on read): cheap insertions, but every query would have to check or restore canonical form, and `==` would depend on hidden state.
- **A linked or tree structure** for the terms: that is what [`mutable/sparse`](sparse.md) provides; the term container stays a flat array for fast ordered traversal.

## Boundaries

- No coefficient lookup by exponent; use `mutable/sparse`.
- `add_inplace` is not optimized for large operands (see above).
- Variables are positional; for names use [`mutable/context`](context.md).
- Everything [`immut/term`](../immut/term.md#boundaries) excludes is excluded here as well.
