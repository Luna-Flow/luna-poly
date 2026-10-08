# core design

## Design goal

`core` fixes the meaning that every representation in `luna-poly` shares: what a monomial is, in which order monomials are listed, what a named variable is, and which observations a generic algorithm may make about a polynomial without knowing its storage. Dense, term-array, sparse and context-bound polynomials, immutable or mutable, all build on these definitions, so they agree on equality, ordering and naming by construction rather than by convention.

## Mathematical background

### Polynomial rings

Let $R$ be a commutative ring (or, for the additive operations alone, a commutative monoid). A polynomial in the variables $x_0, \dots, x_{n-1}$ is a finitely supported function $f : \mathbb{N}^n \to R$, written

$$
f = \sum_{\alpha \in \mathbb{N}^n} f_\alpha \, x^\alpha,
\qquad x^\alpha = x_0^{\alpha_0} x_1^{\alpha_1} \cdots x_{n-1}^{\alpha_{n-1}} .
$$

The $x^\alpha$ are the monomials and $\alpha$ is the exponent vector. Polynomials form the ring $R[x_0, \dots, x_{n-1}]$ with pointwise addition and the convolution product

$$
(fg)_\gamma = \sum_{\alpha + \beta = \gamma} f_\alpha \, g_\beta ,
$$

which is the bilinear extension of $x^\alpha x^\beta = x^{\alpha + \beta}$. In other words $R[x_0, \dots, x_{n-1}]$ is the monoid ring $R[\mathbb{N}^n]$, and everything about monomials is a statement about the additive monoid $\mathbb{N}^n$.

### Exponent vectors without a fixed arity

`ExponentVector` does not carry $n$. It represents an element of

$$
\mathbb{N}^{(\infty)} = \{\, \alpha : \mathbb{N} \to \mathbb{N} \mid \alpha_i = 0 \text{ for all but finitely many } i \,\},
$$

the free commutative monoid on countably many variables. Padding with zeros, $\iota_n(\alpha_0, \dots, \alpha_{n-1}) = (\alpha_0, \dots, \alpha_{n-1}, 0, 0, \dots)$, is an injective monoid homomorphism $\mathbb{N}^n \to \mathbb{N}^{(\infty)}$, so

$$
R[x_0] \subset R[x_0, x_1] \subset \cdots \subset R[x_0, x_1, \dots] = R[\mathbb{N}^{(\infty)}]
$$

and a polynomial written with two variables is literally the same element as the one written with three variables of which the last is unused.

Every $\alpha \neq 0$ has a last non-zero position $\ell(\alpha) = \max\{ i \mid \alpha_i \neq 0 \}$, and the finite word $(\alpha_0, \dots, \alpha_{\ell(\alpha)})$ determines $\alpha$. That word is the canonical form stored by `ExponentVector`; the unit $0$ is stored as the empty word. Two consequences follow directly:

- canonical forms are unique, so structural equality of stored words is equality in $\mathbb{N}^{(\infty)}$, which is why `[1, 0] == [1]`;
- the *arity* of a polynomial, the maximum stored length over its terms, is the least $n$ with $f \in R[x_0, \dots, x_{n-1}]$.

The total degree $|\alpha| = \sum_i \alpha_i$ is a monoid homomorphism $\mathbb{N}^{(\infty)} \to \mathbb{N}$, $|\alpha + \beta| = |\alpha| + |\beta|$. It is computed once when a vector is built and stored next to the exponents.

## Design decisions

### One monomial type for every representation

**Problem.** Dense univariate storage only needs integer powers, but term-array, sparse and context-bound polynomials all need exponent vectors, an order on them, and hashing.

**Options.** Each representation could define its own key type; or one shared type could live in `core`.

**Choice.** `ExponentVector` lives in `core` and is re-exported by both facades, so `immut` and `mutable` polynomials exchange terms without conversion and agree on equality and order. The vector is immutable (it wraps a persistent `@immut/vector.Vector`), which makes it safe as a key inside the mutable containers too.

### The monomial order

**Problem.** Term-array storage must keep its terms sorted, and the sorted map in sparse storage needs a key order. The order should also be a *monomial order* so that the leading term means something algebraically.

**Choice.** `ExponentVector::compare` implements

$$
\alpha \prec \beta
\iff
|\alpha| < |\beta|
\;\text{ or }\;
\bigl( |\alpha| = |\beta| \text{ and } \alpha_k < \beta_k \text{ for } k = \max\{ i \mid \alpha_i \neq \beta_i \} \bigr).
$$

Ties in total degree are broken at the *highest-indexed* variable that differs. This is the graded lexicographic order for the variable priority $x_0 \prec x_1 \prec x_2 \prec \cdots$; it is not graded reverse lexicographic.[^grlex] For example, in degree $2$ with three variables, $(1,0,1) - (0,2,0) = (1,-2,1)$ has its last non-zero entry positive, so $x_0 x_2 \succ x_1^2$, whereas graded reverse lexicographic order with $x_0 > x_1 > x_2$ puts $x_1^2$ first.

[^grlex]: Cox, Little and O'Shea, *Ideals, Varieties, and Algorithms*, §2.2, define grlex by the *leftmost* non-zero entry of $\alpha - \beta$ for $x_1 > x_2 > \cdots > x_n$. Reading the vector from the right is the same order with the variables listed in reverse.

The order has the four properties a monomial order needs, derived below for $\mathbb{N}^{(\infty)}$.

*It is total.* If $\alpha \neq \beta$ and $|\alpha| = |\beta|$, the set $\{ i \mid \alpha_i \neq \beta_i \}$ is non-empty and finite because both vectors are finitely supported, so its maximum $k$ exists and $\alpha_k \neq \beta_k$ decides.

*It is compatible with multiplication.* For any $\gamma$,

$$
\begin{aligned}
|\alpha + \gamma| - |\beta + \gamma| &= |\alpha| - |\beta|, \\
(\alpha + \gamma)_i - (\beta + \gamma)_i &= \alpha_i - \beta_i \quad \text{for every } i,
\end{aligned}
$$

so the degree comparison, the set of differing positions, its maximum $k$ and the sign at $k$ are all unchanged: $\alpha \prec \beta \Rightarrow \alpha + \gamma \prec \beta + \gamma$.

*The unit is least.* $|0| = 0 \le |\alpha|$ with equality only for $\alpha = 0$.

*It is a well-order,* even with unboundedly many variables. Suppose $\alpha^{(1)} \succ \alpha^{(2)} \succ \cdots$ were infinite. The degrees form a non-increasing sequence of naturals, so from some $N$ on they equal a constant $d$. Let $m = \ell(\alpha^{(N)})$. Any later $\beta$ with $|\beta| = d$ and $\beta \prec \alpha^{(N)}$ has $\beta_i = 0$ for every $i > m$: otherwise let $j > m$ be the largest index with $\beta_j > 0$; the two vectors agree above $j$ (both are zero there) and $\beta_j > 0 = \alpha^{(N)}_j$, so $k = j$ and $\beta \succ \alpha^{(N)}$, a contradiction. The tail of the chain therefore lies in $\{ \beta \in \mathbb{N}^{m+1} \mid |\beta| = d \}$, a set of $\binom{d+m}{m}$ elements, and a strictly decreasing chain in a finite set is finite.

**Why this order.** Grading by total degree makes the first terms of a term-array polynomial its highest-degree part, which is what a reader expects to see first, and breaking ties at the last variable is a single backward scan over two short vectors. Compatibility with multiplication is what the representations rely on: [`TermPolynomial::scale`](../api/immut/term.md#termpolynomialscale) multiplies every term by the same monomial and keeps the array without re-sorting, because $\alpha \mapsto \alpha + \gamma$ is strictly increasing.

### Equality, order and hashing agree

`compare` returns $0$ exactly when the degrees are equal and no position differs, that is exactly when the canonical words are equal, which is `equal`. `hash` combines the degree and the stored exponents, both functions of the canonical word, so equal vectors hash equally. Sorted maps (ordered by `compare`) and hash maps (keyed by `hash` and `equal`) therefore identify the same monomials.

### Names live in contexts, positions live in vectors

**Problem.** Users think in named variables ($x$, $y$, $t$); arithmetic needs positions.

**Options.** Store names inside every monomial; or keep monomials positional and put names in a separate table.

**Choice.** Monomials stay positional. A `VariableContext` is a list $\Gamma = (s_0, \dots, s_{k-1})$ of distinct names, and the variable $s_i$ is the pair $(s_i, i)$. Because the names are distinct, the maps $i \mapsto s_i$ and $s_i \mapsto i$ are mutually inverse bijections between $\{0, \dots, k-1\}$ and the names of $\Gamma$, so a context translates between named terms and exponent vectors in both directions.

Indexes are positions counted from the start of the context, like de Bruijn *levels*: extending $\Gamma$ with a new name appends it and never renumbers an existing variable. A variable obtained from $\Gamma$ keeps its meaning in every extension of $\Gamma$.

Contexts compare structurally. Two contexts built separately from the same names are equal, and their variables are interchangeable. This keeps contexts plain values that need no identity or allocation tracking.

### A bridge to `type_theory` names, not a dependency on its syntax

`Luna-Flow/type_theory` owns the shared vocabulary for names, binding and substitution. `Variable::to_type_theory_name` maps a variable to its name and forgets the index; `VariableContext::variable_by_type_theory_name` resolves a name back inside a context. Write $N(v)$ for the first map and $L_\Gamma$ for the second. For every variable $v$ of $\Gamma$,

$$
\begin{aligned}
L_\Gamma(N(v)) &= \text{the variable of } \Gamma \text{ named } v.\text{name} && \text{(definition of } L_\Gamma) \\
&= \Gamma[v.\text{index}] && \text{(names are unique, and } v \in \Gamma) \\
&= v , && \text{(}\texttt{contains}\text{ means } \Gamma[v.\text{index}] = v)
\end{aligned}
$$

and conversely $N(L_\Gamma(t)) = t$ whenever $L_\Gamma(t)$ is defined. Inside one context, names and variables are therefore interchangeable, which lets the name-based substitution APIs resolve names first and reuse the variable-based ones unchanged.

Polynomials have no binders: every variable of a context is free in every polynomial over it. Capture-avoiding substitution, the hard part of substitution in `type_theory`, is vacuous here, because there is no bound variable a replacement could be captured by. So `luna-poly` takes only `Name` from `type_theory` and keeps its own term structure and canonical forms.

### Capabilities are observations, not algebra

**Problem.** Generic code needs to ask "how many variables, how many terms, is it zero?" without depending on a storage type, while algebraic structure already has its own vocabulary in `luna-generic`.

**Choice.** The `Has*` traits each expose one observation, and the bundles `UnivariatePolynomial`, `MultivariatePolynomial`, `ContextualPolynomial` and `MutablePolynomial` group them per family. Ring operations stay on the standard `Add`, `Mul`, `Neg`, `Sub`, `Zero` and `One` traits that the concrete types implement. The traits are `pub(open)` so downstream packages can implement them for their own representations.

`PolynomialShape` makes the observations comparable. `is_compatible_with` is an equivalence relation: it is reflexive and symmetric case by case, and transitive because "same constructor" is transitive and, for `Contextual`, context equality is. Arity and term count are deliberately ignored: by the embedding above, two multivariate polynomials always lie in a common ring $R[x_0, \dots, x_{\max(n, n') - 1}]$, and two univariate polynomials always lie in $R[x]$. Only context-bound polynomials can fail to share a ring, when their contexts differ.

### Operation records instead of multi-parameter traits

**Problem.** A generic algorithm over "a polynomial type $P$ with coefficients $A$" needs a trait with two type parameters, or an associated coefficient type.

**Constraint.** MoonBit traits have only `Self`; there are no multi-parameter traits and no associated types.

**Choice.** `UnivariateOps[P, A]`, `MultivariateOps[P, A]` and `ContextOps[P, A]` are records of functions, built by each concrete type's `ops()` and passed explicitly (dictionary passing). The record type mentions both parameters, so a function such as `fn[P, A] f(ops : MultivariateOps[P, A], ...)` can relate polynomials to coefficients. The fields are private and only reachable through the accessor methods, so the record layout can grow without breaking callers.

### Checked variants return `Option`

Every partial operation has an aborting form and a `*_checked` form that returns `None` on a contract violation (a negative index, a duplicate name, an unknown variable). The `Option` carries no reason, so a caller that needs one checks the preconditions itself. This predates the Luna Flow convention of `Result` with a structured error value used by `linear-algebra`, `arithmetic` and `type_theory`; the pages document the current `Option` contract as it is.

## Correctness / invariants

- **Canonical exponent vectors.** A stored word never ends in $0$; `degree` equals the sum of the stored exponents. Every constructor and `with_exponent` re-trims.
- **Order.** `compare` is a total monomial order and a well-order on $\mathbb{N}^{(\infty)}$ (derived above), consistent with `equal` and `hash`.
- **Contexts.** Names are pairwise distinct and the variable at position $i$ has index $i$. `extend_checked` and `from_names_checked` enforce this; nothing else constructs contexts.
- **Name round trip.** $L_\Gamma(N(v)) = v$ for $v \in \Gamma$, and $N(L_\Gamma(t)) = t$ when defined.
- **Shape compatibility** is an equivalence relation.
- **Complexity.** `ExponentVector` construction, `mul` and `compare` are $O(\ell)$ in the stored length; `degree` is $O(1)$. Context lookup by name is a linear scan, $O(k)$ string comparisons; `get` and `contains` are $O(1)$ apart from comparing one variable.

## Alternatives rejected

- **A fixed arity per polynomial.** Carrying $n$ in every vector would make `[1, 0]` and `[1]` different keys for the same monomial and force explicit lifting between $R[x_0]$ and $R[x_0, x_1]$. Trimming trailing zeros gets the inclusion for free.
- **Lexicographic order.** Plain lex is a monomial order too, but it is not graded: a term-array polynomial would list $x_1$ before $x_0^{100}$, and the order would not group terms by degree.
- **Names inside monomials.** Storing names would make every monomial product compare strings and would tie arithmetic to one naming scheme; positional vectors plus a context keep arithmetic purely numeric.
- **A `Polynomial` god-trait.** One trait carrying construction, arithmetic and evaluation could not mention the coefficient type and would hide which operations a function really needs. Small observation traits plus explicit operation records state the requirement precisely.
- **Implementing `type_theory` binding syntax.** Polynomials bind nothing, so the binding machinery would add obligations without adding meaning.

## Boundaries

- No storage, arithmetic or evaluation: those belong to the representation packages.
- Exponents are `UInt`. Products of monomials and total degrees wrap modulo $2^{32}$ silently; past that point the order is no longer compatible with multiplication.
- Only one monomial order is provided. There is no API to choose lex, grevlex or a weight order, and no Gröbner-basis machinery.
- Contexts are compared structurally, not by identity; two contexts with the same names in the same order are the same context.
- The capability traits state observations only. They carry no algebraic laws, and the operation records do not check that the functions they hold satisfy any.
- `type_theory` provides names only; `luna-poly` does not implement its binding or rewriting interfaces.
