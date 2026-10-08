# immut/term design

## Design goal

`TermPolynomial[A]` is the multivariate polynomial in *distributed* form: a flat, sorted list of non-zero terms. It is the representation for traversing a polynomial in order, for whole-polynomial arithmetic, and for reading the leading term directly, while staying an immutable value with structural equality.

## Constraints

- The term order must be the monomial order of `ExponentVector::compare`, shared with every other representation.
- Values are immutable and compared with the derived `Eq`, so the stored list must be a canonical form.
- Coefficient bounds are per function, as in the dense type; addition may only assume an `AddMonoid`.

## Mathematical background

A polynomial $f \in R[x_0, x_1, \dots]$ is a finite sum $f = \sum_{k=1}^{m} c_k x^{\alpha_k}$ with distinct exponent vectors $\alpha_k \in \mathbb{N}^{(\infty)}$ and non-zero coefficients $c_k$ (see the [core design](../core.md#mathematical-background)). Fix the monomial order $\prec$ of `ExponentVector::compare`. Listing the terms so that $\alpha_1 \succ \alpha_2 \succ \cdots \succ \alpha_m$ gives the *canonical term list* of $f$. The first term $c_1 x^{\alpha_1}$ is the leading term $\operatorname{LT}(f)$, $\alpha_1$ the leading monomial and $c_1$ the leading coefficient.

Since $\prec$ is total and the $\alpha_k$ are distinct, the sorted list exists and is unique, so

$$
f = g \iff \text{the canonical term lists of } f \text{ and } g \text{ are equal}.
$$

## Design decisions

### Canonical form: sorted, merged, without zeros

**Choice.** A `TermPolynomial` stores exactly the canonical term list, in a persistent `@immut/vector.Vector`. The derived `Eq` compares the stored lists, which by the equivalence above is polynomial equality. `from_terms` brings any input into this form in three steps:

1. sort a copy of the input in descending order by `compare`;
2. walk the sorted list and add the coefficients of each run of equal exponent vectors;
3. keep a run only if its sum is non-zero.

Equal vectors are adjacent after step 1 because `compare` returns $0$ exactly for equal vectors. Step 2 sums a run in whatever order the sort left it, which is harmless because `AddMonoid` addition is associative and commutative. Step 3 is what makes $2x_0 - 2x_0$ disappear. Sorting costs $O(m \log m)$ comparisons, each $O(\ell)$ for vectors of length $\ell$.

### Arithmetic by concatenation and renormalization

Addition concatenates the two term lists and calls `from_terms`; multiplication forms all $mn$ products $(\alpha_i + \beta_j,\ c_i d_j)$ and calls `from_terms`. Both are the textbook definitions followed by the canonicalization above, so their correctness reduces to the correctness of `from_terms`. The costs are $O((m+n)\log(m+n))$ and $O(mn \log(mn))$ comparisons.

### Scaling and negation keep the order

`scale(γ, c)` maps every term $(\alpha, a)$ to $(\alpha + \gamma, ac)$ and *does not re-sort*. This is sound because the map $\alpha \mapsto \alpha + \gamma$ is strictly increasing for a monomial order:

$$
\alpha \succ \beta \;\Longrightarrow\; \alpha + \gamma \succ \beta + \gamma
$$

(compatibility, derived in the [core design](../core.md#the-monomial-order)). Strictly descending input therefore gives strictly descending output, and in particular distinct exponents stay distinct. Coefficients $ac$ can still vanish when $R$ has zero divisors (for `Int`, $2^{16} \cdot 2^{16} = 0$), so such terms are filtered out. The result is canonical in $O(m)$ term operations. Negation keeps the exponents, so it only filters.

### The leading term of a product

Storing terms in descending order makes the leading term `to_terms()[0]`, and the monomial order makes it multiplicative. Let $\alpha_1$ and $\beta_1$ be the leading monomials of $f$ and $g$. For any terms $\alpha \preceq \alpha_1$ and $\beta \preceq \beta_1$,

$$
\alpha + \beta \;\preceq\; \alpha_1 + \beta \;\preceq\; \alpha_1 + \beta_1 ,
$$

applying compatibility once with $\beta$ and once with $\alpha_1$; both steps are equalities only when $\alpha = \alpha_1$ and $\beta = \beta_1$. So $\alpha_1 + \beta_1$ arises from exactly one pair of terms, its coefficient in $fg$ is $c_1 d_1$, and

$$
\operatorname{LT}(fg) = \operatorname{LT}(f)\operatorname{LT}(g) \quad \text{whenever } c_1 d_1 \neq 0 .
$$

This is the property that makes graded orders useful for division-style algorithms, and the reason the representation commits to a monomial order rather than an arbitrary key order.

### Evaluation term by term

`eval(values)` computes $\sum_k c_k \prod_i a_i^{\alpha_{k,i}}$, each power by binary exponentiation. For a commutative coefficient ring this is the evaluation homomorphism $\mathrm{ev}_a : R[x_0, \dots, x_{n-1}] \to R$, $x_i \mapsto a_i$; it is a ring homomorphism by the same monomial argument as in the [dense design](dense.md#composition-is-evaluation-at-a-polynomial). Term $k$ costs, for every stored position $i < \ell_k$, one multiplication into the term and at most $2\lfloor\log_2 \alpha_{k,i}\rfloor + 1$ for the power (none when $\alpha_{k,i} = 0$), so the total is $O\bigl(\sum_k (\ell_k + \sum_i \log_2(1 + \alpha_{k,i}))\bigr)$ coefficient multiplications, where $\ell_k$ is the stored length of $\alpha_k$.

The point must supply at least `arity()` values: index $i$ is read for every variable a term uses. `eval` aborts on a shorter array and `eval_checked` returns `None`; values beyond the arity are never read.

### Shape and capability metadata

`arity` is the longest stored exponent vector, `total_degree` the largest term degree, and `term_count` the list length; together they form `PolynomialShape::Multivariate`. All three are computed by one pass over the terms; nothing is cached, because the list is never modified after construction.

## Correctness / invariants

- **Canonical form.** Terms are strictly descending in $\prec$ and every coefficient is non-zero; every constructor and operation re-establishes this, either through `from_terms` or by the order-preservation argument for `scale` and `neg`.
- **Equality** of values is equality of polynomials.
- **Leading term.** `to_terms()[0]` is $\operatorname{LT}(f)$, and $\operatorname{LT}(fg) = \operatorname{LT}(f)\operatorname{LT}(g)$ when the coefficient product is non-zero.
- **`one()`** is the zero polynomial exactly when $1 = 0$ in `A`.
- **Powers.** `pow(e)` performs $O(\log e)$ multiplications and `pow(0)` is `one()`.
- **Complexity** ($m$, $n$ terms): `from_terms` $O(m \log m)$; `+` $O((m+n)\log(m+n))$; `*` $O(mn \log(mn))$; `scale`, `neg`, `arity`, `total_degree` $O(m)$; `eval` $O\bigl(\sum_k (\ell_k + \sum_i \log_2(1 + \alpha_{k,i}))\bigr)$ multiplications. Each comparison costs $O(\ell)$.

## Alternatives rejected

- **Heap-based multiplication** (merging the $m$ sorted streams $\alpha_i + \beta_1, \alpha_i + \beta_2, \dots$ with a priority queue) would lower multiplication to $O(mn \log \min(m, n))$ and avoid materializing all $mn$ products. The current version keeps the simpler sort-based normalization that every operation shares.
- **Merge-based addition** of two sorted lists would be linear; it is not implemented for the same reason.
- **Recursive (nested univariate) representation**, $R[x_0][x_1]\cdots$, makes multivariate Horner evaluation natural but ties the layout to a variable order and makes the leading term of the distributed order expensive to find.
- **Ascending order.** The leading term would be the last element. Descending order shows the highest-degree part first, which matches how polynomials are usually written.

## Boundaries

- No division, normal forms, S-polynomials or Gröbner bases, although the monomial order would support them.
- No exponent lookup by key; use [`SparsePolynomial`](sparse.md) when you need `get` by exponent vector.
- Variables are positional; names are the job of [`ContextPolynomial`](context.md).
- No `Compare` or `Hash` instance, so term polynomials cannot be keys of sorted or hash maps.
- Exponents are `UInt` and wrap on overflow; coefficients follow the semantics of `A` (wrapping integers, rounding floats, exact `== 0` trimming).
