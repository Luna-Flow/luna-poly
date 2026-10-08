# immut/dense design

## Design goal

`DensePolynomial[A]` is the univariate polynomial as a value: a canonical coefficient vector that can be shared freely, compared with `==`, and combined with the ring operators. It targets polynomials whose coefficients are mostly non-zero, where storing every coefficient up to the degree is both the simplest and the fastest layout.

## Mathematical background

A univariate polynomial over $R$ is a finitely supported sequence $(c_0, c_1, \dots)$, written $f = \sum_i c_i x^i$. Its degree is $\deg f = \max\{ i \mid c_i \neq 0 \}$, with $\deg 0 = -\infty$ (returned as `None`). Addition is coefficient-wise and multiplication is the Cauchy product

$$
(fg)_k = \sum_{i + j = k} f_i \, g_j .
$$

If $R$ is a commutative ring then so is $R[x]$; if $R$ is only a semiring (such as `UInt`) then $R[x]$ is a semiring. The degree satisfies

$$
\deg(f + g) \le \max(\deg f, \deg g), \qquad
\deg(fg) \le \deg f + \deg g ,
$$

with equality in the second exactly when the product of the leading coefficients is non-zero, which always holds when $R$ has no zero divisors.

## Design decisions

### Canonical form: trim trailing zeros

**Problem.** The sequences $(1, 2)$ and $(1, 2, 0, 0)$ describe the same polynomial. If both could be stored, `==`, `degree`, `length` and hashing would all have to normalize first.

**Choice.** Every constructor and every operation trims trailing zeros before returning, and the zero polynomial is the empty vector. Trimming defines a bijection between polynomials and words $(c_0, \dots, c_{n-1})$ with $c_{n-1} \neq 0$ (plus the empty word), so

$$
\texttt{p == q} \iff p = q \text{ in } R[x], \qquad
\texttt{p.length()} = \deg p + 1 .
$$

Trimming after *every* operation, not only after construction, matters because the degree inequalities above can be strict. In `Int`, which is $\mathbb{Z}/2^{32}$, $(2^{16} x + 1)^2 = 2^{32} x^2 + 2^{17} x + 1 = 2^{17} x + 1$: the leading coefficient vanishes, and the trimmed result correctly has degree $1$.

The vector is a persistent `@immut/vector.Vector`, and `from_coefficients` copies its input, so a caller mutating its array afterwards cannot change a polynomial.

### Minimal coefficient bounds per operation

**Problem.** One bound such as `A : Ring` on the whole type would exclude useful coefficient types: `UInt` has no negation, and some types have multiplication without a unit.

**Choice.** Each function states the smallest set of `luna-generic` capabilities it uses. Addition needs `Eq + AddMonoid` (`Eq` and `Zero` to trim), multiplication adds `Mul` but not `One`, negation needs `Neg` but not `Mul`, and only `variable`, `one`, `pow` and `karatsuba` need `One`. The type itself has no bound, so `zero()`, `length()` and `degree()` work for any `A`.

### Schoolbook multiplication by default

`*` computes the Cauchy product with two nested loops over the stored coefficients, $mn$ coefficient multiplications and additions for lengths $m$ and $n$, then trims. For the short polynomials that dominate typical use this is faster than any recursive method, needs no `Neg`, and is exact for exact coefficient types.

### Karatsuba as an explicit method

**Problem.** For long operands, $O(mn)$ becomes the bottleneck.

**Derivation.** Split each operand at $k$: $a = a_0 + a_1 y$ and $b = b_0 + b_1 y$ with $y = x^k$ and $\deg a_0, \deg b_0 < k$. Then

$$
\begin{aligned}
ab &= a_0 b_0 + (a_0 b_1 + a_1 b_0)\, y + a_1 b_1 \, y^2, \\
a_0 b_1 + a_1 b_0 &= (a_0 + a_1)(b_0 + b_1) - a_0 b_0 - a_1 b_1 ,
\end{aligned}
$$

where the second line is distributivity alone, so it holds over any ring. Three half-size products replace four. With $T(n)$ the cost for length $n$ and $c\,n$ for the additions and shifts,

$$
T(n) = 3\,T(n/2) + c\,n
\;\Rightarrow\;
T(n) = c\,n \sum_{j=0}^{\log_2 n} \left(\tfrac{3}{2}\right)^j = O\!\left(n \cdot \left(\tfrac32\right)^{\log_2 n}\right) = O\!\left(n^{\log_2 3}\right) \approx O(n^{1.585}).
$$

**Choice.** `karatsuba` splits at half the longer length, recurses on the three products, and falls back to `*` when the shorter operand has at most $32$ coefficients, where the recursion overhead outweighs the saved multiplications. The subtraction needs `Neg`, and the shift by $y$ is `scale(k, One::one())`, which needs `One`. It is a separate method rather than the implementation of `*` so that `*` keeps its weaker bounds and its predictable cost; a test checks that both agree above the threshold.

### Horner evaluation

$p(a)$ is computed as

$$
p(a) = c_0 + a\bigl(c_1 + a\bigl(c_2 + \cdots + a\,(c_{n-1})\bigr)\bigr),
$$

one multiplication and one addition per stored coefficient, starting from zero. Horner's rule uses the fewest multiplications possible for evaluating a general polynomial without preprocessing its coefficients.[^horner] It needs only `AddMonoid + Mul`, so it evaluates over any coefficient type, and it never forms the powers $a^i$, which keeps intermediate values small for fixed-width integers and well-conditioned for floating point.

[^horner]: Ostrowski proved the optimality for degree at most 4 (1954) and Pan for every degree (1966): any algorithm evaluating a generic polynomial of degree $n$ needs at least $n$ multiplications and $n$ additions.

### Composition is evaluation at a polynomial

`substitute(q)` runs the same Horner loop with polynomial arithmetic, computing $p(q) = \sum_i c_i q^i$. For commutative $R$ this is the evaluation homomorphism $\mathrm{ev}_q : R[x] \to R[x]$, $x \mapsto q$, the unique ring homomorphism fixing $R$ and sending $x$ to $q$. On monomials,

$$
\mathrm{ev}_q(x^i \cdot x^j) = q^{i+j} = q^i q^j = \mathrm{ev}_q(x^i)\,\mathrm{ev}_q(x^j),
$$

and both sides are bilinear, so $\mathrm{ev}_q(fg) = \mathrm{ev}_q(f)\,\mathrm{ev}_q(g)$ and $\mathrm{ev}_q(f + g) = \mathrm{ev}_q(f) + \mathrm{ev}_q(g)$. Composition is associative, $p(q(r)) = (p(q))(r)$, because both sides are homomorphisms that agree on $x$.

With $\deg p = n$ and $\deg q = d$, step $j$ of Horner multiplies a polynomial of degree $jd$ by $q$, so the schoolbook cost is $\sum_{j=1}^{n} (jd + 1)(d + 1) = O(n^2 d^2)$, and the result has degree at most $nd$.

### Formal derivative through the canonical map from ℕ

`derivative` computes $D\bigl(\sum_i c_i x^i\bigr) = \sum_{i \ge 1} (i \cdot 1_R)\, c_i\, x^{i-1}$, mapping the integer $i$ into $R$ with `NatHomomorphism::from_nat`. $D$ is additive and satisfies the Leibniz rule. On monomials,

$$
\begin{aligned}
D(x^i x^j) &= (i + j)\, x^{i+j-1} \\
&= i\,x^{i-1} x^j + x^i\, j\,x^{j-1} \\
&= D(x^i)\,x^j + x^i\,D(x^j),
\end{aligned}
$$

and both sides of $D(fg) = D(f)\,g + f\,D(g)$ are bilinear in $(f, g)$, so the rule extends to all polynomials. Because $i$ is taken modulo the characteristic, $D(x^p) = p\,x^{p-1} = 0$ in characteristic $p$, exactly as in algebra. `luna-generic` provides `NatHomomorphism` for `Float`, `Double` and `BigInt`; fixed-width integer coefficients have no derivative until they get such an instance (the trait is being replaced by `FromNat` upstream).

### Powers by binary exponentiation

`pow(e)` delegates to the package-internal `pow_nat`, which keeps the invariant $\text{state} \cdot \text{factor}^{\text{exp}} = p^e$ while halving `exp`. It performs $\lfloor \log_2 e \rfloor$ squarings and at most one multiplication into the state per set bit of $e$, so at most $2\lfloor \log_2 e \rfloor + 1$ polynomial multiplications. Since the operands grow, the last squaring dominates: with schoolbook multiplication the total cost is $O\bigl((e\,\deg p)^2\bigr)$.

`pow(0)` returns `one()` for every $p$, including zero, so $0^0 = 1$. This is the convention of `@arithmetic.PowNatChecked`, which `DensePolynomial` implements by returning `Ok(self.pow(e))`.

### A structural order for containers

The derived `Compare` orders by stored length, then coefficient by coefficient from the constant term. Because of trimming, length is degree plus one, so lower-degree polynomials sort first. The order exists so that polynomials can be keys of sorted maps and sets; it is not a ring order and is not compatible with `+` or `*`.

## Correctness / invariants

- **Canonical form.** After every public operation the last stored coefficient is non-zero, and zero is empty. Equality is therefore polynomial equality.
- **Ring laws.** When the coefficient type satisfies the commutative-ring laws, `DensePolynomial[A]` does: the operations are the textbook formulas on canonical forms. Property tests check the additive identity and idempotent canonicalization.
- **Agreement.** `karatsuba(a, b) == a * b`; `substitute` is $\mathrm{ev}_q$; `derivative` satisfies the Leibniz rule; `pow(e)` equals the $e$-fold product.
- **Value semantics.** No method mutates its receiver or its arguments; constructors copy input arrays.
- **Complexity** for lengths $m, n$: `+`, `-`, `neg`, `scale` $O(m + n)$; `*` $O(mn)$; `karatsuba` $O(n^{\log_2 3})$ for balanced operands above the threshold; `eval` $O(n)$; `substitute` $O(n^2 d^2)$; `pow(e)` $O(\log e)$ multiplications.

## Alternatives rejected

- **Karatsuba inside `*`.** It would force `Neg + One` on every multiplication and change the cost profile of short products. Keeping it explicit leaves the choice to the caller.
- **FFT or number-theoretic multiplication.** These need roots of unity or a suitable modulus in the coefficient type, which a generic `A` does not provide.
- **Storing the degree separately and allowing trailing zeros.** It saves a trim on some operations but makes equality and hashing depend on normalization; trimming once per operation is cheap and removes the question.
- **A sparse univariate type.** Polynomials such as $x^{1000} + 1$ waste space here; use `SparsePolynomial` with one-element exponent vectors for them.

## Boundaries

- Univariate only. Multivariate polynomials are [`TermPolynomial`](term.md) and [`SparsePolynomial`](sparse.md).
- No division, GCD, factorization, root finding or interpolation.
- Exact trimming: a coefficient is dropped only when it `==` zero. With `Float` or `Double` coefficients a leading coefficient that should cancel but carries rounding error is kept, so the stored degree can exceed the mathematical one.
- Fixed-width integer coefficients wrap, so the polynomials are over $\mathbb{Z}/2^k$, with zero divisors and degree drops as shown above.
- `pow` takes a `UInt` exponent; there are no negative powers.
