# immut/context design

## Design goal

`ContextPolynomial[A]` lets users write polynomials in named variables and transform them by evaluation, partial evaluation and substitution, while the arithmetic stays positional and reuses the term and sparse representations. It is also the place where `luna-poly` meets `Luna-Flow/type_theory`: substitutions can be keyed by `type_theory` names, but canonical forms, storage and coefficient arithmetic remain owned by this package.

## Constraints

- Arithmetic must stay positional and reuse `TermPolynomial` and `SparsePolynomial`; names are a layer on top.
- Substitution keyed by `type_theory` names must not import `type_theory`'s binding machinery: polynomials have no binders.
- Every partial operation needs an aborting and a checked form that returns `Option`, as everywhere in `luna-poly`.
- Contexts are plain values compared structurally, with no identity to track.

## Mathematical background

### Polynomials over a context

A [`VariableContext`](../core.md#names-live-in-contexts-positions-live-in-vectors) $\Gamma = (s_0, \dots, s_{k-1})$ names the variables $x_0, \dots, x_{k-1}$. A context polynomial is a pair $(\Gamma, f)$ with

$$
f \in R[\Gamma] := R[x_0, \dots, x_{k-1}] .
$$

A named term such as `[(x, 1), (y, 2), (x, 1)]` is a word in the free commutative monoid on the names; the context maps it to an exponent vector by adding the exponents of each variable at its index. This map is a monoid homomorphism (concatenating words adds exponent vectors), so repeated factors of one variable combine as $x \cdot x = x^2$, and permuted factors give the same monomial.

### Substitution is the universal property

Let $R$ be commutative. For any choice of polynomials $q_0, \dots, q_{k-1} \in R[\Gamma]$ there is exactly one ring homomorphism $\varphi : R[\Gamma] \to R[\Gamma]$ that fixes $R$ and sends $x_i \mapsto q_i$, namely

$$
\varphi\Bigl(\sum_\alpha c_\alpha x^\alpha\Bigr) = \sum_\alpha c_\alpha \prod_{i} q_i^{\alpha_i} .
$$

*It is a homomorphism.* Additivity holds by construction. On monomials,

$$
\begin{aligned}
\varphi(x^\alpha x^\beta) = \varphi(x^{\alpha+\beta})
&= \prod_i q_i^{\alpha_i + \beta_i} \\
&= \prod_i q_i^{\alpha_i} \prod_i q_i^{\beta_i} && (R[\Gamma] \text{ is commutative}) \\
&= \varphi(x^\alpha)\,\varphi(x^\beta),
\end{aligned}
$$

and both sides of $\varphi(fg) = \varphi(f)\varphi(g)$ are bilinear in $(f, g)$, so the identity extends from monomials to all polynomials.

*It is unique.* A homomorphism fixing $R$ is determined on $x^\alpha = \prod_i x_i^{\alpha_i}$ by multiplicativity and on sums by additivity, so its values on $x_0, \dots, x_{k-1}$ determine it.

A substitution $\sigma$ assigns replacements to a subset $S \subseteq \Gamma$ of the variables. It determines the images

$$
q_i = \begin{cases} \sigma(x_i) & x_i \in S, \\ x_i & x_i \notin S, \end{cases}
$$

where a scalar $a \in R$ is read as the constant polynomial $a$, and hence the homomorphism $\varphi_\sigma$. `substitute(σ)` computes $\varphi_\sigma(f)$ term by term exactly as in the formula: each factor $x_i^{\alpha_i}$ becomes $x_i^{\alpha_i}$ (not replaced), the constant $a^{\alpha_i}$ (scalar), or $q_i^{\alpha_i}$ (polynomial).

## Design decisions

### Simultaneous, one-pass substitution

**Problem.** Given $\sigma = \{x \mapsto y,\; y \mapsto 2\}$, should $x + y$ become $y + 2$ or $4$?

**Choice.** Simultaneous: every $q_i$ is taken from $\sigma$ as given, and the replacement polynomials are not themselves substituted into. This is the homomorphism $\varphi_\sigma$ above, so

$$
\varphi_\sigma(x + y) = q_x + q_y = y + 2 .
$$

The sequential reading is a *composition* of two homomorphisms, and the composition rule

$$
\varphi_\tau \circ \varphi_\sigma = \varphi_{\tau \cdot \sigma}, \qquad (\tau \cdot \sigma)(x_i) = \varphi_\tau\bigl(q^\sigma_i\bigr),
$$

holds because both sides are homomorphisms fixing $R$ that agree on every $x_i$. To substitute sequentially, call `substitute` twice: $\varphi_{y \mapsto 2}(\varphi_{x \mapsto y}(x + y)) = \varphi_{y \mapsto 2}(2y) = 4$. Simultaneous substitution is the primitive because it is order-independent: permuting the entries of $\sigma$ cannot change the result.

### Duplicate entries are errors, not overrides

A list that maps the same variable twice does not define a function $\sigma$. Rather than picking the first or last entry, `substitute_checked` returns `None` (and `substitute` aborts). The same rule applies after name resolution, so two different `Name` values with the same text, or the same name twice, are rejected.

### Partial evaluation keeps the context

**Problem.** After assigning $x = 3$ in $p \in R[x, y]$, the result does not depend on $x$. It could live in $R[y]$ or stay in $R[x, y]$.

**Choice.** `eval_partial` is substitution with scalar images only, so its result is in $R[\Gamma]$ with the same context. The assigned variables simply have degree $0$. Keeping $\Gamma$ means the result can be added to, multiplied with and substituted into other polynomials over $\Gamma$ without any context surgery, and it makes partial evaluation compose with full evaluation. Write $a$ for a partial assignment on $S$ and $b$ for an assignment of the remaining variables. Then

$$
\mathrm{ev}_b \circ \varphi_a = \mathrm{ev}_{a \cup b},
$$

because both sides are homomorphisms $R[\Gamma] \to R$ fixing $R$, and on generators $\mathrm{ev}_b(\varphi_a(x_i)) = \mathrm{ev}_b(a_i) = a_i$ for $x_i \in S$ and $\mathrm{ev}_b(\varphi_a(x_i)) = \mathrm{ev}_b(x_i) = b_i$ otherwise. Any value $b$ gives to an already assigned variable is irrelevant, which is why the examples evaluate the partial result with `x = 0`.

### Names from `type_theory` resolve to variables first

`substitute_names` and `eval_partial_named` map every `Name` to a variable with [`VariableContext::variable_by_type_theory_name`](../../api/core.md#variablecontextvariable_by_type_theory_name) and then call the variable-based form. The [name round trip](../core.md#a-bridge-to-type_theory-names-not-a-dependency-on-its-syntax) guarantees that this is lossless inside one context: resolving `v.to_type_theory_name()` gives back `v`. An unknown name makes the whole call fail, so a typo can never silently leave a variable unreplaced. No capture can occur, since polynomials have no binders.

### What makes a call invalid

Each checked operation returns `None` exactly in these situations:

| Operation | Rejected when |
| --- | --- |
| `from_named_terms_*_checked`, `variable_checked` | a variable is not contained in the context |
| `eval_named_checked` | a variable is outside the context; a variable with index below `arity()` is unassigned or assigned twice; `arity()` exceeds the context size |
| `substitute_checked`, `eval_partial_checked` | a variable is outside the context or listed twice; a replacement polynomial has a different context |
| `*_names_checked` | additionally, a name is not in the context |
| `add_checked`, `mul_checked` | the contexts differ |

The `Option` result records only that the call failed. The aborting forms check the same conditions.

### Storage is chosen at construction, results are storage-independent

The polynomial is held as a term array or a sparse map behind a private enum, selected by `from_named_terms_as_terms` / `_as_sparse` or by binding an existing `TermPolynomial` / `SparsePolynomial`. Both storages satisfy the same canonical-form invariants, so every observable result (terms as a set, evaluation, substitution) is the same; only costs and the order of `to_terms()` differ. Binary operations keep the storage when both operands agree and use sparse storage for mixed operands, converting the term-stored side. Substitution and the constructors `constant` and `variable` produce sparse storage.

### Contexts must be equal, not merged

Binary operations require equal contexts. Merging $\Gamma$ and $\Gamma'$ automatically would need an injection of both into a union context and a renumbering of every exponent vector, and the union is not unique when the same name appears at different positions. Requiring equality keeps every operation a plain operation in one ring $R[\Gamma]$. Because contexts compare structurally, polynomials built from separately created but identical contexts combine freely.

## Correctness / invariants

- **Context invariant.** Every exponent vector of a context polynomial has length at most $|\Gamma|$. The named constructors guarantee it. `from_term_polynomial` and `from_sparse_polynomial` do not check it; for a polynomial that violates it, `eval_named_checked` returns `None`, `eval_named` aborts, and `to_string` aborts with an index error. Callers must ensure `polynomial.arity() <= context.size()`.
- **Substitution** computes $\varphi_\sigma$, the unique ring endomorphism with $x_i \mapsto q_i$, for commutative coefficients; the result is canonical (zero terms vanish, as when substituting $x \mapsto 0$).
- **Partial evaluation** satisfies $\mathrm{ev}_b \circ \varphi_a = \mathrm{ev}_{a \cup b}$.
- **Named evaluation** equals indexed evaluation at the values listed by index.
- **Arithmetic** is that of the underlying storage and inherits its laws.
- **Cost.** Substitution evaluates every term as a product of powers and adds it to an accumulator; each addition renormalizes the accumulator. For $m$ terms and a result of $s$ terms, the additions alone cost $O(m\, s \log s)$, on top of the polynomial products. Named lookups are linear in the context size.

## Alternatives rejected

- **Sequential substitution.** Its result depends on the order of the entries, and it is expressible as two simultaneous substitutions.
- **Projecting away assigned variables.** It would change the context of the result and break composition with other polynomials over $\Gamma$.
- **Last-entry-wins for duplicates.** It hides mistakes; rejecting duplicates keeps $\sigma$ a function.
- **Using `type_theory` substitution machinery.** Its capture-avoiding substitution solves a problem polynomials do not have, and its terms would not carry polynomial canonical forms.
- **Implicit context union.** See above: not unique, and it would make every binary operation renumber exponents.

## Boundaries

- No equality instance; compare `context()` and the term lists explicitly.
- No dense univariate storage; a context polynomial is always multivariate.
- No elimination of variables from a context, and no renaming or reordering of contexts.
- Substitution needs commutative coefficients to be a homomorphism; the code does not check commutativity.
- Errors carry no reason (`Option`), and `from_term_polynomial` / `from_sparse_polynomial` trust their arity.
