# Contributing

This guide collects the conventions for working on `luna-poly`. The Luna Flow organization rules apply on top of it.

## Before a pull request

Run, from the repository (`./ready_to_pr.sh` runs `moon fmt`, `moon check`, `moon test` and `moon info`):

```bash
moon fmt
moon check --target all
moon test
moon info
```

Review the diff of every `pkg.generated.mbti`: it is the authority for the public API, and any change in it is an API change that the documentation and the changelog must reflect.

## Code style

- Format with `moon fmt`; separate top-level items with `///|`.
- Use snake_case for bindings, functions, files and folders, and PascalCase for types and traits. Name files after what they implement (`sparse_polynomial.mbt`), not `utils.mbt`.
- Keep explicit method promotions (`pub extend T with Trait::{...}`) in `extends.mbt`. Promote operators, `equal`, `compare`, `hash` and canonical `to_string`; keep other trait methods available only through the trait, and mark compatibility promotions `#deprecated` and `#doc(hidden)`.
- In blackbox tests, qualify names of the package under test (`@immut.DensePolynomial`); whitebox tests (`*_wbtest.mbt`) may use them unqualified.

## Library conventions

- **Canonical forms.** Every public operation returns canonical values: trimmed dense vectors, strictly descending merged term arrays, zero-free sparse maps. A new operation must restore the invariant before it returns.
- **Minimal bounds.** Each function asks only for the `luna-generic` capabilities it uses.
- **Checked variants.** A partial operation has an aborting form and a `*_checked` form that returns `None` on contract violations. Abort messages name the violated contract.
- **Two layers.** Add an operation to `immut` first; add the mutable counterpart with the same name and parameter order, delegating to `immut` unless in-place storage gives a real benefit, and add a check to `src/consistency`. Document every intended difference in the [mutable design](design/mutable.md#api-symmetry-with-immut).
- **Mutation is named.** Only setters, `clear`, `add_term_inplace` and `*_inplace` methods may mutate their receiver.

## Documentation

The manual follows the Luna Flow documentation standard: English pages in `doc/manual` (one `api/`, `design/` and `tutorial/` page per package, named after the package path), Chinese and Japanese translations as gettext catalogs in `doc/locale`. After editing English pages, run `lunadoc update` and translate the new or fuzzy messages. Every runnable `moonbit` block must compile against the current code; mark intentional fragments `moonbit nocheck`.

## Commits

Use Conventional Commits in English, `<type>(<scope>): <subject>`, with the package as scope (`fix(immut/context): ...`), one logical change per commit. If you are not a maintainer, ask before changing dependencies or the version in `moon.mod`.
