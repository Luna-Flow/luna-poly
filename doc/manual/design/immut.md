# immut design

## Design goal

The `immut` facade gives the value-oriented half of `luna-poly` a single import. A user who wants polynomials as values should not need to know that dense, term, sparse and context polynomials live in four packages, nor that monomials and traits come from `core` and `luna-generic`.

## Constraints

- MoonBit re-exports names one by one with `pub using`; there is no way to re-export a whole package.
- An alias must be the same type as the original, so the facade cannot add methods or instances.
- The `mutable` facade must export the same names, so that code moves between layers by changing one import.

## Mathematical background

Every immutable type models an element of a polynomial ring: $R[x]$ for `DensePolynomial`, $R[x_0, x_1, \dots]$ for `TermPolynomial` and `SparsePolynomial`, and $R[\Gamma]$ for `ContextPolynomial` (see the [core design](core.md#mathematical-background)). Ring elements are values: $f + g$ is a new element and $f$ does not change. The immutable layer mirrors that: no operation changes an existing polynomial, so a polynomial can be shared, stored in several places and reused after any computation, exactly like an integer.

## Design decisions

### A facade over implementation packages

**Problem.** Splitting the implementation into `immut/dense`, `immut/term`, `immut/sparse` and `immut/context` keeps each representation small and lets the packages depend only on what they use (dense does not depend on the multivariate code). But four imports, plus `core`, plus `luna-generic`, is a poor entry point.

**Choice.** `immut` consists only of `pub using` re-exports. The aliases are the same types, not wrappers, so values move between code that imports the facade and code that imports a subpackage without conversion. Re-exporting the `luna-generic` traits lets bounds such as `A : @immut.Ring` be written with the same import.

### Value semantics everywhere

All four representations keep their contents in persistent vectors or behind private fields that are never mutated after construction, and every constructor copies caller-owned arrays. Therefore:

- no public function mutates its receiver or an argument;
- a polynomial observed twice gives the same answers both times;
- sharing a polynomial between data structures is always safe.

The price is that incremental updates (`SparsePolynomial::add_term`) rebuild their result. Incremental algorithms belong in the [`mutable`](mutable.md) layer.

### Explicit conversions between representations

Representations do not convert implicitly. `TermPolynomial` and `SparsePolynomial` convert through `to_terms()` and `from_terms`, which re-applies canonicalization; `ContextPolynomial` binds either with a context and converts back with `to_term_polynomial` or `to_sparse_polynomial`. Keeping conversions explicit keeps the implementation packages independent of each other and makes every cost visible in the code.

### Symmetry with `mutable`

The facade exports the same trait set and type names as the [`mutable` facade](mutable.md), and each immutable type has a mutable counterpart with the same constructors, queries, operators and checked variants. Code written against the shared traits or operation records runs on both. The differences are listed in the [mutable design](mutable.md#api-symmetry-with-immut).

## Correctness / invariants

- Every exported type is identical to its definition in the implementation package or in `core`.
- Every immutable polynomial is in canonical form after every public operation (trimmed dense vectors, sorted merged term arrays, zero-free sparse maps), so `==` is polynomial equality wherever `Eq` is provided.
- No public operation mutates an existing value.

## Alternatives rejected

- **One root package.** The 0.1 layout put everything in one package. Splitting made dependencies explicit; the facade keeps the single import.
- **Wrapper types in the facade.** Wrappers would need conversion at every package boundary; aliases need none.
- **Implicit representation conversion.** Choosing the storage behind the user's back would hide costs; only `ContextPolynomial` picks storage, and only for mixed operands.

## Boundaries

- The facade adds no functions, types or behaviour of its own.
- The constructors `Scalar` and `Polynomial` are reachable through the re-exported `ContextSubstitutionValue` type, not as standalone facade values.
- Persistence is by copying and encapsulation; there is no structural sharing between a polynomial and the result of an update.
- In-place updates are out of scope; see [`mutable`](mutable.md).
