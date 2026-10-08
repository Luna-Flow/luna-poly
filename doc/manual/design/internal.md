# internal design

## Design goal

`internal` keeps code that several representation packages need, but that is not part of the public surface, in one place. Today it contains a single function, the natural-power routine behind every `pow` and every evaluation of $x_i^{\alpha_i}$.

## Constraints

- MoonBit makes an `internal` package importable only inside its module, so the helpers here are not part of the public API.
- Every representation needs natural powers, of polynomials and of coefficients, with the smallest possible bound on the element type.

## Mathematical background

For an element $a$ of a monoid with unit $1$ and $e \in \mathbb{N}$, $a^e$ is the $e$-fold product, $a^0 = 1$. Writing $e$ in binary, $e = \sum_j b_j 2^j$, gives

$$
a^e = \prod_{j : b_j = 1} a^{2^j},
$$

and the factors $a^{2^j}$ are obtained by repeated squaring.

## Design decisions

### Binary exponentiation with an explicit loop invariant

`pow_nat` keeps three values, `state`, `exp` and `factor`, initially $1$, $e$ and $a$, and maintains

$$
\text{state} \cdot \text{factor}^{\text{exp}} = a^e .
$$

Each step with $\text{exp} \ge 2$ replaces $(\text{state}, \text{exp}, \text{factor})$ by $(\text{state}\cdot\text{factor}^{b}, \lfloor \text{exp}/2 \rfloor, \text{factor}^2)$ where $b = \text{exp} \bmod 2$. The invariant is preserved:

$$
\begin{aligned}
\text{state}\cdot\text{factor}^{b} \cdot (\text{factor}^2)^{\lfloor \text{exp}/2 \rfloor}
&= \text{state}\cdot\text{factor}^{\,b + 2\lfloor \text{exp}/2 \rfloor} \\
&= \text{state}\cdot\text{factor}^{\text{exp}} = a^e .
\end{aligned}
$$

The loop stops at $\text{exp} = 0$ with result `state`, or at $\text{exp} = 1$ with result $\text{state}\cdot\text{factor}$; in both cases the invariant gives $a^e$. `exp` halves each step, so there are $\lfloor \log_2 e \rfloor$ squarings. All multiplied values are powers of $a$, which commute with each other, so only associativity of `*` is used.

### The unit is a parameter

The unit is passed as `one~` instead of being taken from a `One` instance. Callers already know their unit (`DensePolynomial::one()`, `One::one()` for coefficients), and the helper then needs only `Mul`, which keeps its bound minimal.

## Correctness / invariants

- `pow_nat(a, e, one=u) = u · a^e` for associative `*`; with `u` the unit this is $a^e$.
- $e = 0$ returns `one` without multiplying, so $0^0 = 1$.
- At most $2\lfloor\log_2 e\rfloor + 1$ multiplications.

## Alternatives rejected

- **Repeated multiplication**, $e - 1$ products, is too slow for polynomial powers.
- **A trait method** on each representation would duplicate the loop four times.

## Boundaries

- Not importable outside `luna-poly`.
- Natural exponents only; no negative powers and no modular exponentiation.
- The cost of each multiplication is the caller's: for polynomials the final squaring dominates.
