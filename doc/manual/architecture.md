# Architecture

This guide describes how the packages of `luna-poly` fit together: the layers, the dependency graph, where each invariant is enforced, and how the immutable and mutable layers share their algorithms.

## Layers

`luna-poly` has three layers:

1. **Vocabulary**: [`core`](design/core.md) defines monomials (`ExponentVector`), named variables (`Variable`, `VariableContext`), shapes, capability traits and operation records. It stores no polynomials.
2. **Representations**: four immutable packages (`immut/dense`, `immut/term`, `immut/sparse`, `immut/context`) and their four mutable counterparts implement polynomial storage and algorithms.
3. **Facades**: `immut` and `mutable` re-export the vocabulary, the `luna-generic` algebra traits and the representations of their layer.

`internal` holds module-private helpers, and `consistency` holds tests only.

## Dependency graph

```text
                 luna-generic   arithmetic   type_theory/core
                       \            |            /
                        \           |           /
                           core  <--+----------+
                         /  |  \
              internal  /   |   \
                 |     /    |    \
        immut/dense  immut/term  immut/sparse
              |           \        /
              |          immut/context
              |               |
     mutable/dense   mutable/term   mutable/sparse
              \           \        /
               \         mutable/context
                \             |
      immut (facade)    mutable (facade)
                \        /
               consistency (tests only)
```

In words: every representation depends on `core`; the immutable representations and the mutable term and sparse packages use `internal` for powers; `immut/context` is built on `immut/term` and `immut/sparse`; each mutable package depends on its immutable counterpart; `mutable/context` additionally uses the mutable term and sparse packages for its conversions; each facade depends on the packages of its layer; `consistency` depends on both facades in tests only. `arithmetic` is needed for `PowNatChecked`, and `type_theory/core` for `Name`.

## Where invariants live

| Invariant | Enforced in |
| --- | --- |
| exponent vectors have no trailing zeros; degree cached | `core` (`ExponentVector::from_array`, `with_exponent`, `*`) |
| monomial order is a graded monomial order | `core` (`ExponentVector::compare`) |
| context names are distinct; index = position | `core` (`VariableContext::extend_checked`) |
| dense coefficients have no trailing zeros | `immut/dense`, `mutable/dense` (every constructor and mutation) |
| term arrays are strictly descending, merged, zero-free | `immut/term` (`from_terms` normalization), reused by `mutable/term` |
| sparse maps hold no zero values | `immut/sparse`, `mutable/sparse` (every insertion) |
| context operations validate variables, duplicates and contexts | `immut/context`, reused by `mutable/context` |

## How the layers share code

The mutable layer implements in-place updates directly on its storage and delegates every non-trivial algorithm to the immutable layer through `to_immut` / `from_immut`. `mutable/context` is a mutable cell around an immutable context polynomial. This keeps one implementation of Karatsuba, composition, derivatives, multivariate products and all context logic, and the `consistency` tests check the agreement.

## Data flow of a substitution

`ContextPolynomial::substitute_names` shows all layers at once:

1. each `type_theory` `Name` is resolved to a `Variable` with `VariableContext::variable_by_type_theory_name` (`core`);
2. the substitution list is validated (membership, duplicates, equal contexts) in `immut/context`;
3. every term is rewritten as a product of powers of the replacements, using the term or sparse arithmetic and `internal.pow_nat`;
4. the partial results are added and canonicalized by the sparse representation.

The mutable version converts its payload to the immutable one, runs the same steps, and wraps the result.

## Tests

- Inline `test` blocks next to each implementation check representation-specific behaviour, including the `type_theory` name lookups in `core` and the named substitution tests in both context packages.
- `src/immut/laws_wbtest.mbt` checks algebraic laws with `moonbitlang/quickcheck`.
- `src/consistency/core_wbtest.mbt` checks agreement across layers and representations.

Run everything with `moon test`; see the [contributing guide](contributing.md) for the full pre-PR sequence.
