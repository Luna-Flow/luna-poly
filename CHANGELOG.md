# Changelog

All notable changes to `Luna-Flow/luna-poly` are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow semantic versioning.

## Unreleased

## 0.3.0 - 2026-10-10

### Changed

- Migrated to MoonBit 0.10 (`moonc` 0.10 or later is required). `moon.mod` now uses the `source = "src"` field, and the package manifests import `moonbitlang/core/debug` where `Debug` is derived.
- Bumped `Luna-Flow/type_theory` from `0.1.0-alpha.1` to `0.2.0`.
- Bumped `Luna-Flow/luna-generic` from `0.3.3` to `0.4.0` and `Luna-Flow/arithmetic` from `0.2.1` to `0.5.0`.
- **Breaking:** `DensePolynomial::derivative` (`immut/dense` and `mutable/dense`) requires `FromNat` instead of the `NatHomomorphism` trait deprecated in luna-generic 0.4.0. `Float`, `Double` and `BigInt` keep their derivative, and the fixed-width integer types (`Int`, `Int64`, `UInt`, ...) gain one, computed modulo 2^k. A custom coefficient type needs a `FromNat` instance.
- Trait methods are now promoted to methods explicitly with `pub extend` in each package's `extends.mbt`. Operators (`add`, `sub`, `mul`, `neg`), `equal`, `compare`, `hash`, `to_string`, `zero`, `one`, `shape`, `is_zero`, `term_count` and `clear` stay callable as methods and now appear in the interface files.
- `ContextPolynomial::term_count` and `ContextPolynomial::arity` (immutable and mutable) are public methods.
- `ExponentVector`, `Variable`, `VariableContext`, `PolynomialShape` and all polynomial types derive `Debug`, so they work with `assert_eq` and `debug_inspect`.
- `VariableContext::extend` is renamed to `VariableContext::extend_with`, because `extend` is now a MoonBit keyword.

### Deprecated

- `VariableContext::extend`: use `VariableContext::extend_with`.
- The method forms `not_equal`, `op_lt`, `op_le`, `op_gt`, `op_ge`, `output`, `to_repr`, `hash_combine` and `pow_nat_checked` on the library's types: use the operators, `to_string`, `Repr(x)` / `debug_inspect`, and `@arithmetic.PowNatChecked::pow_nat_checked`. They are hidden from the interface files and kept for source compatibility.

### Added

- Tests for `type_theory` name lookup in `VariableContext`, and for named substitution, duplicate-name rejection and incompatible-context rejection in the immutable and mutable context packages.

### Fixed

- `@mutable.SparsePolynomial::add_inplace` iterates over a snapshot of its argument, so `p.add_inplace(p)` is `2p` also when a coefficient doubles to zero (#37).
- `ContextPolynomial::eval_named_checked` returns `None` instead of aborting when the polynomial uses more variables than its context names (part of #34).
- `ExponentVector` prints its factors separated by ` * ` (`x * x_1` instead of `xx_1`), and so do term and sparse polynomials (#35).

### Documentation

- The manual describes version 0.3.0: luna-generic 0.4.0 and arithmetic 0.5.0, the `FromNat` bound of `DensePolynomial::derivative`, and derivatives over fixed-width integer coefficients.
- The manual follows the luna-generic layout: an overview with Install, a Part/Tutorial/API/Design table and reading paths; Purpose and Importing sections on every API page; a task table at the start of every tutorial; a Constraints section on every design page. Every operation-record method has its own API heading.
- Logic review of the design pages: exact evaluation cost of `TermPolynomial`, cost of context lookups, and the normalization shared by the two multivariate types.
- Documentation rewritten: API, tutorial and design pages for every package (`core`, both facades, the eight representation packages, `internal` and `consistency`), an architecture guide, and a new contributing guide, with zh_CN and ja_JP translations.

## 0.2.0

### Changed

- Restructured the library into `core`, the implementation packages `immut/{dense,term,sparse,context}` and `mutable/{dense,term,sparse,context}`, and the `immut` and `mutable` facades. The former root package is gone; this release is source-incompatible with 0.1.
- Replaced the 0.1 types `Polynomial`, `MultiPoly`, `SparsePolynomial` and `ExpVec` by `DensePolynomial`, `TermPolynomial`, `SparsePolynomial` and `ExponentVector`, with every polynomial type in an immutable and a mutable version.

### Added

- Named variables (`Variable`, `VariableContext`) and `ContextPolynomial` with named and partial evaluation and simultaneous substitution, including substitution by `Luna-Flow/type_theory` names.
- Capability traits, `PolynomialShape` and the `UnivariateOps`, `MultivariateOps` and `ContextOps` records for generic code.
- Checked (`*_checked`) variants returning `Option`, and `Luna-Flow/arithmetic.PowNatChecked` for natural powers.
