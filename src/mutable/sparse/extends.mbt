///|
pub extend SparsePolynomial with Eq::{equal}

///|
pub extend SparsePolynomial with Show::{to_string}

///|
pub extend SparsePolynomial with Add::{add}

///|
pub extend SparsePolynomial with Sub::{sub}

///|
pub extend SparsePolynomial with Mul::{mul}

///|
pub extend SparsePolynomial with Neg::{neg}

///|
pub extend SparsePolynomial with @lg.Zero::{zero}

///|
pub extend SparsePolynomial with @lg.One::{one}

///|
pub extend SparsePolynomial with @poly_core.HasShape::{shape}

///|
pub extend SparsePolynomial with @poly_core.HasTermCount::{term_count}

///|
pub extend SparsePolynomial with @poly_core.IsZero::{is_zero}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend SparsePolynomial with Eq::{not_equal}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend SparsePolynomial with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend SparsePolynomial with @debug.Debug::{to_repr}

///|
#deprecated("Use `@arithmetic.PowNatChecked::pow_nat_checked` instead", skip_current_package=true)
#doc(hidden)
pub extend SparsePolynomial with @arithmetic.PowNatChecked::{pow_nat_checked}
