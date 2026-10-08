///|
pub extend ContextPolynomial with Show::{to_string}

///|
pub extend ContextPolynomial with Add::{add}

///|
pub extend ContextPolynomial with Sub::{sub}

///|
pub extend ContextPolynomial with Mul::{mul}

///|
pub extend ContextPolynomial with Neg::{neg}

///|
pub extend ContextPolynomial with @poly_core.HasShape::{shape}

///|
pub extend ContextPolynomial with @poly_core.IsZero::{is_zero}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend ContextPolynomial with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend ContextPolynomial with @debug.Debug::{to_repr}
