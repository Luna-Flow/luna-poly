///|
pub extend ExponentVector with Eq::{equal}

///|
pub extend ExponentVector with Compare::{compare}

///|
pub extend ExponentVector with Hash::{hash}

///|
pub extend ExponentVector with Show::{to_string}

///|
pub extend ExponentVector with Mul::{mul}

///|
pub extend Variable with Eq::{equal}

///|
pub extend Variable with Compare::{compare}

///|
pub extend Variable with Show::{to_string}

///|
pub extend VariableContext with Eq::{equal}

///|
pub extend PolynomialShape with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend ExponentVector with Eq::{not_equal}

///|
#deprecated("Use `<`, `<=`, `>`, `>=` instead", skip_current_package=true)
#doc(hidden)
pub extend ExponentVector with Compare::{op_lt, op_le, op_gt, op_ge}

///|
#deprecated("Use `Hash::hash_combine` through the trait instead", skip_current_package=true)
#doc(hidden)
pub extend ExponentVector with Hash::{hash_combine}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend ExponentVector with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend ExponentVector with @debug.Debug::{to_repr}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Eq::{not_equal}

///|
#deprecated("Use `<`, `<=`, `>`, `>=` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Compare::{op_lt, op_le, op_gt, op_ge}

///|
#deprecated("Use `to_string` or string interpolation instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Show::{output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with @debug.Debug::{to_repr}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend VariableContext with Eq::{not_equal}

///|
#deprecated("Use string interpolation `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend VariableContext with Show::{to_string, output}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend VariableContext with @debug.Debug::{to_repr}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend PolynomialShape with Eq::{not_equal}

///|
#deprecated("Use `Repr(x)` or `@debug.Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend PolynomialShape with @debug.Debug::{to_repr}
