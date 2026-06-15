# Correctness Checklist

Last audited: 2026-06-15

This checklist tracks the `0.2.0` release contract. The release is intentionally
source-incompatible with the former root package and publishes `/core`,
implementation subpackages, and `/immut` plus `/mutable` facades.

## Public Surface

| Area | Status | Contract |
| --- | --- | --- |
| `core` package | Correct | Owns `ExponentVector`, `Variable`, `VariableContext`, capability traits, and functional ops records. |
| Implementation subpackages | Correct | Concrete implementations are split under `immut/dense`, `immut/term`, `immut/sparse`, `immut/context`, and mirrored `mutable/*` packages. |
| `immut` / `mutable` facades | Correct | Re-export shared capability traits and concrete implementation types so downstream code can import one facade when package granularity is not needed. |
| `DensePolynomial` | Correct | Ascending coefficients, trailing-zero canonicalization, zero as empty storage, ordinary algebraic operators, derivative, substitution, Karatsuba, and `PowNatChecked`. |
| `TermPolynomial` | Correct | Sorted canonical term array; duplicate exponents merge and zero coefficients disappear. |
| `SparsePolynomial` | Correct | Ordered-map sparse representation with canonical term export and lookup by `ExponentVector`. |
| `ExponentVector` | Correct | Trailing zero exponents are removed; multiplication adds exponents pointwise. |
| `Variable` / `VariableContext` | Correct | Context-local stable indexes, duplicate variable names rejected, lookup by name available. |
| `ContextPolynomial` | Correct | Binds a context to term or sparse storage, preserves chosen storage for same-kind arithmetic, rejects incompatible contexts through checked APIs or aborting operators. |
| `mutable` package | Correct | Mirrors the immutable surface where practical and delegates context semantics to `immut`; mutating methods canonicalize after updates and implement `MutablePolynomial`. |

## Required Release Checks

- `moon fmt`
- `moon check`
- `moon test`
- `moon info`

Generated `pkg.generated.mbti` files must be reviewed after `moon info` to
confirm the public API contains the `0.2.0` names: `DensePolynomial`,
`TermPolynomial`, `SparsePolynomial`, `VariableContext`, and
`ContextPolynomial`.

Generated APIs must also show `UnivariatePolynomial`,
`MultivariatePolynomial`, `ContextualPolynomial`, `MutablePolynomial`, and
`Type::ops()` records through the appropriate packages. They must not expose
`ContextPolynomialStorage`, nor old direct `TermPolynomial::to_sparse` or
`SparsePolynomial::to_term` methods.

## Follow-Up Queue

1. Add a benchmark subsystem after `0.2.0`, modeled after `linear-algebra`.
2. Migrate downstream packages such as `linear-program` to consume
   `luna-poly` instead of local polynomial helpers.
