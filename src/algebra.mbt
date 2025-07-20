///|
/// A trait for types that can be constructed from natural numbers (non-negative
/// integers).
///
/// This trait represents a homomorphism from the natural numbers to the
/// implementing type, meaning there exists a structure-preserving mapping from
/// integers to values of the type. This is commonly used in algebraic
/// structures where you need to embed natural numbers into more complex
/// mathematical objects like polynomials, matrices, or other algebraic types.
///
/// Methods:
///
/// * `from_nat(Int) -> Self`: Converts a natural number (represented as an
///   `Int`) to a value of the implementing type. The input should be a
///   non-negative integer.
///
trait HomomorphismNat {
  from_nat(Int) -> Self
}

///|
/// Provides a natural number to `Int` conversion by returning the input value
/// unchanged.
///
/// Parameters:
///
/// * `x` : The integer value to convert from a natural number representation.
///
/// Returns the same integer value as provided in the input.
///
/// Example:
///
/// ```moonbit
/// let result = Int::from_nat(42)
/// inspect(result, content="42")
/// ```
///
impl HomomorphismNat for Int with from_nat(x) {
  x
}

///|
/// Checks whether a value is equal to zero in its semiring.
///
/// Parameters:
///
/// * `x` : The value to check against zero.
///
/// Returns `true` if the value equals the zero element of its semiring, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// inspect(@luna-poly.is_zero(0), content="true")
/// inspect(@luna-poly.is_zero(5), content="false")
/// ```
///
pub fn[A : Semiring + Eq] is_zero(x : A) -> Bool {
  x == A::zero()
}
