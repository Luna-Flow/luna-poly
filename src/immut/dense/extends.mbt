///|
pub extend DensePolynomial with Eq::{equal}

///|
pub extend DensePolynomial with Compare::{compare}

///|
pub extend DensePolynomial with Show::{to_string}

///|
pub extend DensePolynomial with Add::{add}

///|
pub extend DensePolynomial with Sub::{sub}

///|
pub extend DensePolynomial with Mul::{mul}

///|
pub extend DensePolynomial with Neg::{neg}

///|
pub extend DensePolynomial with @lg.Zero::{zero}

///|
pub extend DensePolynomial with @lg.One::{one}

///|
pub extend DensePolynomial with @poly_core.HasShape::{shape}

///|
pub extend DensePolynomial with @poly_core.IsZero::{is_zero}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend DensePolynomial with Eq::{not_equal}

///|
#deprecated("Use `<`, `<=`, `>`, `>=` instead", skip_current_package=true)
#doc(hidden)
pub extend DensePolynomial with Compare::{op_lt, op_le, op_gt, op_ge}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend DensePolynomial with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend DensePolynomial with @debug.Debug::{to_repr}

///|
#deprecated("Use `@arithmetic.PowNatChecked::pow_nat_checked` instead", skip_current_package=true)
#doc(hidden)
pub extend DensePolynomial with @arithmetic.PowNatChecked::{pow_nat_checked}
