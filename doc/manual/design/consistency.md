# consistency design

## Design goal

`luna-poly` promises that its two layers and its representations describe the same mathematics. `consistency` turns that promise into tests that run with `moon test`, in a package that depends on both facades, so that neither layer's own tests need to know about the other.

## Constraints

- Neither layer may depend on the other's tests, so cross-layer checks need a package that imports both facades.
- The package must not add public API: it holds whitebox tests only, and its interface file stays empty.
- Checks must run with a plain `moon test`, without extra tools.

## Mathematical background

Each representation $\rho$ (dense, term, sparse, context; immutable or mutable) comes with an interpretation $[\![\cdot]\!]_\rho$ into a polynomial ring. Consistency is the statement that every operation commutes with interpretation:

$$
[\![\, a \mathbin{\mathrm{op}_\rho} b \,]\!]_\rho = [\![ a ]\!]_\rho \mathbin{\mathrm{op}} [\![ b ]\!]_\rho ,
$$

and that conversions between representations preserve the interpretation. The tests check instances of these equations on concrete inputs.

## Design decisions

### A separate whitebox package

The checks need both `immut` and `mutable`, while `mutable` already depends on `immut`; putting them in either layer would invert or tangle dependencies. A dedicated package with whitebox tests (`core_wbtest.mbt`) imports `Luna-Flow/arithmetic`, `immut` and `mutable` for tests only and contributes nothing to the public API.

### What is checked

- **Layer agreement for dense polynomials:** coefficients, products, composition and evaluation are equal in `immut` and `mutable`.
- **Natural powers:** `PowNatChecked::pow_nat_checked(p, 0, ctx)` is one in both layers, and `pow(5)` agrees.
- **Isolation:** mutating a mutable polynomial after `to_immut` does not change the snapshot.
- **Multivariate agreement:** term and sparse storage, immutable and mutable, evaluate identically and produce the same powers.
- **Capability surface:** functions bounded by `UnivariatePolynomial`, `MultivariatePolynomial`, `Zero`, `One` and the `ops()` records work through both facades; shapes report the expected arity, term count and compatibility.
- **Checked contracts:** the `*_checked` methods return `None` on negative indexes and short evaluation points instead of aborting.
- **Mutable context delegation:** partial evaluation and its failure cases match the immutable behaviour.

The algebraic laws of a single representation (canonicalization idempotence, additive identity, Karatsuba against schoolbook multiplication, minimal coefficient bounds) live in `immut/laws_wbtest.mbt`, next to the code they check.

## Correctness / invariants

The package has no runtime code. Its invariant is that `moon test` passes: every equation above holds on the tested inputs.

## Alternatives rejected

- **Tests inside `mutable`** would let the mutable layer's tests silently depend on immutable internals and could not be reused for other layers.
- **Exhaustive property tests across all pairs of representations** would multiply test time; the package checks representative operations, and the property tests stay with the individual laws.

## Boundaries

- The tests are finite samples, not proofs.
- No public API; nothing here is meant to be imported.
