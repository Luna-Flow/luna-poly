///|
pub extend TermPolynomial with Eq::{equal}

///|
pub extend TermPolynomial with Show::{to_string}

///|
pub extend TermPolynomial with Add::{add}

///|
pub extend TermPolynomial with Sub::{sub}

///|
pub extend TermPolynomial with Mul::{mul}

///|
pub extend TermPolynomial with Neg::{neg}

///|
pub extend TermPolynomial with @lg.Zero::{zero}

///|
pub extend TermPolynomial with @lg.One::{one}

///|
pub extend TermPolynomial with @poly_core.HasShape::{shape}

///|
pub extend TermPolynomial with @poly_core.HasTermCount::{term_count}

///|
pub extend TermPolynomial with @poly_core.IsZero::{is_zero}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend TermPolynomial with Eq::{not_equal}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend TermPolynomial with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend TermPolynomial with @debug.Debug::{to_repr}

///|
#deprecated("Use `@arithmetic.PowNatChecked::pow_nat_checked` instead", skip_current_package=true)
#doc(hidden)
pub extend TermPolynomial with @arithmetic.PowNatChecked::{pow_nat_checked}
