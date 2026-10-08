# immut/sparse design

## Design goal

`SparsePolynomial[A]` stores a multivariate polynomial as an ordered map from monomials to coefficients. It is the representation to use when an algorithm asks "what is the coefficient of $x^\alpha$?" more often than it traverses the whole polynomial, and it gives that answer in logarithmic time while staying an immutable value.

## Mathematical background

A polynomial is a finitely supported function $f : \mathbb{N}^{(\infty)} \to R$, $\alpha \mapsto f_\alpha$ (see the [core design](../core.md#mathematical-background)). Its support $\operatorname{supp} f = \{ \alpha \mid f_\alpha \neq 0 \}$ is finite, and $f$ is determined by its restriction to the support. A sparse polynomial stores exactly that restriction, the finite partial map

$$
\operatorname{supp} f \to R \setminus \{0\}, \qquad \alpha \mapsto f_\alpha ,
$$

so coefficient lookup is evaluation of the partial map, with absent keys meaning $0$. Two polynomials are equal exactly when these partial maps are equal.

## Design decisions

### A balanced search tree keyed by the monomial order

**Problem.** Lookup by exponent vector needs an index. A hash map would give expected $O(1)$ lookup but no order; a sorted array gives $O(\log m)$ lookup but $O(m)$ insertion.

**Choice.** The terms live in a `@sorted_map.SortedMap[ExponentVector, A]`, an AVL tree ordered by `ExponentVector::compare`. AVL trees keep their height below $1.44 \log_2(m + 2)$, so `get` performs $O(\log m)$ key comparisons, each $O(\ell)$ in the vector length.[^avl] The map is ordered by the same monomial order as `TermPolynomial`, so iteration yields the canonical term list, here in *ascending* order: the constant term first and the leading term last.

[^avl]: Adelson-Velsky and Landis, 1962. The height bound follows from the Fibonacci-like recurrence for the minimum number of nodes in an AVL tree of height $h$.

The tree also matches the cost profile of the other operations: building it from $m$ sorted terms is $O(m \log m)$, the same as sorting.

### Canonical content: no zero values

**Invariant.** Every stored value is non-zero. Construction reuses the normalization of the term representation (sort, merge equal keys, drop zero sums) and inserts the survivors; `neg` and `scale` skip results that compare equal to zero, which can happen with zero divisors. Since keys are canonical exponent vectors and values are non-zero, the stored map *is* the partial map $\alpha \mapsto f_\alpha$ on $\operatorname{supp} f$, and

$$
\texttt{p == q} \iff \texttt{p.to\_terms() == q.to\_terms()} \iff p = q .
$$

`get(α)` returning `None` therefore means exactly $f_\alpha = 0$.

### Immutability by encapsulation

`SortedMap` is a mutable structure, but the field holding it is private, and no function in this package modifies a map after the polynomial has been returned. Every operation, including `add_term`, builds a fresh map. This gives value semantics without a persistent tree, at the price that adding a single term rebuilds the map in $O(m \log m)$. Workloads that add terms one at a time should use [`mutable/sparse`](../mutable/sparse.md), whose `add_term_inplace` updates the tree in $O(\log m)$.

### Arithmetic shared with the term representation

Addition and multiplication collect the term lists (all $mn$ products for `*`) and rebuild the map through the shared normalization, exactly as for [`TermPolynomial`](term.md#arithmetic-by-concatenation-and-renormalization). Both representations therefore compute the same canonical result, and the costs are the same up to the constant factor of tree insertion. `eval` is the same term-by-term evaluation homomorphism, with the same arity precondition.

### Two multivariate representations

The two types describe the same polynomials and differ only in their access paths:

| Operation | `TermPolynomial` | `SparsePolynomial` |
| --- | --- | --- |
| coefficient of $x^\alpha$ | $O(m)$ scan of `to_terms()` | $O(\log m)$ `get` |
| leading term | first element | last element |
| iteration order | descending | ascending |
| build from $m$ terms | $O(m \log m)$ | $O(m \log m)$ |
| add one term (immutable) | $O(m \log m)$ via `+` | $O(m \log m)$ `add_term` |
| `+`, `*` | $O((m+n)\log(m+n))$, $O(mn\log(mn))$ | same |
| memory | flat array | one tree node per term |

Conversions go through `to_terms()`, which keeps the implementation packages independent of each other; the facade and [`ContextPolynomial`](context.md) are where both meet.

## Correctness / invariants

- **Keys** are canonical `ExponentVector` values; **values** are non-zero.
- **Equality** compares the ascending term lists and coincides with polynomial equality.
- **Lookup.** `get(α) == Some(c)` iff $f_\alpha = c \neq 0$; `None` iff $f_\alpha = 0$. `get_checked` is the same function.
- **Agreement.** For the same input terms, `SparsePolynomial` and `TermPolynomial` hold the same term set, and `+`, `-`, `*`, `pow`, `scale` and `eval` agree.
- **Value semantics.** No public function mutates an existing `SparsePolynomial`.

## Alternatives rejected

- **Hash map storage.** Expected $O(1)$ lookup, but iteration order would be arbitrary, so equality, printing and the leading term would all need a sort.
- **Persistent (path-copying) tree.** The core library's `@immut/sorted_map` would make `add_term` $O(\log m)$ without any mutation. The package keeps the mutable `SortedMap` behind a private field instead and leaves incremental construction to [`mutable/sparse`](../mutable/sparse.md).
- **One multivariate type with a storage flag.** That is what [`ContextPolynomial`](context.md) does internally; at the index-addressed level two explicit types keep each cost model visible in the signature.

## Boundaries

- No `Compare` or `Hash` instance; sparse polynomials cannot be map keys.
- `add_term` is not incremental; it rebuilds the map.
- Variables are positional; named variables and substitution belong to [`ContextPolynomial`](context.md).
- No division or Gröbner-basis algorithms.
- Exponents are `UInt` and wrap on overflow; coefficients follow the semantics of `A`.
