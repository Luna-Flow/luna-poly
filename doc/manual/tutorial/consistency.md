# consistency tutorial

This page is for contributors: it explains how to run the cross-layer agreement tests and how to add one when you add or change an operation. Library users never import this package.

## Quick start

Run the tests of this package from the repository (or from a workspace that contains it):

```bash
moon test -p Luna-Flow/luna-poly/consistency
```

All tests should pass; a failure means the two layers or two representations disagree.

## Everyday tasks

### Add a check for a new operation

When you add an operation to both layers, add a whitebox test to `src/consistency/core_wbtest.mbt` that computes it both ways and compares canonical outputs, for example:

```moonbit nocheck
test "new operation stays aligned" {
  let immutable = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  let mutable = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  assert_true(
    immutable.new_operation().to_coefficients() ==
    mutable.new_operation().to_coefficients(),
  )
}
```

Compare through `to_coefficients()` or `to_terms()` (converting exponent vectors with `to_array()` if needed), because the two layers have different types.

### Check a failure contract

For a checked API, assert that both layers return `None` on the same invalid input.

## Going further

Laws of a single representation belong in that representation's package (see `src/immut/laws_wbtest.mbt`, which uses `moonbitlang/quickcheck`); cross-representation and cross-layer equations belong here.

## Common pitfalls

- **Comparing different types.** `@immut.DensePolynomial` and `@mutable.DensePolynomial` are not comparable with `==`; compare their canonical exports.
- **Order of `to_terms()`.** Term storage is descending and sparse storage ascending; normalize through `TermPolynomial::from_terms` before comparing.

## Next steps

- The [consistency design](../design/consistency.md) lists what is checked.
- The [contributing guide](../contributing.md) describes the pre-PR checks.
