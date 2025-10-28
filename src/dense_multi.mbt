///|
/// Multivariate polynomial with coefficients of type `A`.
///
/// A multivariate polynomial is represented as a collection of terms, where
/// each term consists of an exponent vector (specifying the powers of each
/// variable) and a coefficient. The polynomial supports operations like
/// addition, subtraction, multiplication by terms, and evaluation.
///
/// Fields:
///
/// * `terms` : Array of terms, each containing an exponent vector and
///   coefficient pair.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial 2*X^12 + 3*Y + 3 from array representation
/// let terms = [([0U, 0], 3), ([12, 0], 2), ([0, 1], 3)]
/// let poly = MultiPoly::from_array(terms)
///
/// // Create polynomial from ExpVec terms
/// let exp_vec = ExpVec::from_array([1U, 1])
/// let terms_array = [(exp_vec, 5)]
/// let poly2 = MultiPoly::from_terms_array(terms_array)
///
/// // Scale polynomial by a term
/// let scaled = poly.scale((ExpVec::from_array([1U, 1]), 2))
/// ```
///
struct MultiPoly[A] {
  terms : Array[(ExpVec, A)]
}

///|
/// Extracts all coefficients from the multivariate polynomial.
///
/// Parameters:
///
/// * `self` : The multivariate polynomial from which to extract coefficients.
///
/// Returns an array containing all the coefficients of the polynomial terms.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.MultiPoly::from_array([([0U, 0], 1), ([1, 1], 2), ([2, 0], 3)])
/// let coeffs = poly.coefficients()
/// inspect(coeffs, content="[1, 2, 3]")
/// ```
///
pub fn[A] coefficients(self : MultiPoly[A]) -> Array[A] {
  self.terms.map(x => x.1)
}

///|
/// Creates a multivariate polynomial from an array of term-coefficient pairs.
///
/// Parameters:
///
/// * `arr` : `Array[(Array[UInt], A)]` - An array of pairs where each pair
///   contains an exponent vector (as an array of unsigned integers) and its
///   corresponding coefficient. The exponent vector represents the powers of
///   variables in a monomial term.
///
/// Returns a `MultiPoly[A]` representing the multivariate polynomial with
/// normalized terms.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial 2*X^12 + 3*Y + 3
/// let terms = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
/// let poly = @luna-poly.MultiPoly::from_array(terms)
/// inspect(poly, content="2 * X^12 + 3 * Y + 3")
/// ```
///
pub fn[A : Semiring + Eq] MultiPoly::from_array(
  arr : Array[(Array[UInt], A)]
) -> MultiPoly[A] {
  {
    terms: normalize(arr).map(x => {
      let (term, a) = x
      (ExpVec::from_array(term), a)
    }),
  }
}

///|
/// Creates a multivariate polynomial from an array of terms where each term
/// consists of an exponent vector and coefficient.
///
/// Parameters:
///
/// * `terms` : An array of tuples where each tuple contains an `ExpVec`
///   (exponent vector) and a coefficient of type `A`.
///
/// Returns a `MultiPoly[A]` representing the multivariate polynomial
/// constructed from the given terms.
///
/// Example:
///
/// ```moonbit
/// let exp1 = ExpVec::from_array([1U, 2])  // x^1 * y^2
/// let exp2 = ExpVec::from_array([0U, 1])  // y^1
/// let terms = [(exp1, 3), (exp2, 5)]      // 3*x*y^2 + 5*y
/// let poly = MultiPoly::from_terms_array(terms)
/// ```
///
pub fn[A : Semiring + Eq] MultiPoly::from_terms_array(
  terms : Array[(ExpVec, A)]
) -> MultiPoly[A] {
  terms.map(x => {
    let (term, a) = x
    (term.vec, a)
  })
  |> MultiPoly::from_array
}

///|
/// Normalizes a sparse polynomial representation by sorting terms in descending
/// order and combining like terms.
///
/// Parameters:
///
/// * `arr` : An array of polynomial terms, where each term is represented as a
///   tuple containing an exponent vector (as `Array[UInt]`) and a coefficient
///   of type `A`.
///
/// Returns an `ArrayView` containing the normalized polynomial terms with like
/// terms combined and zero coefficients removed, sorted in descending
/// lexicographic order by exponent vectors.
///
/// Example:
///
/// ```moonbit
/// let terms = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
/// let normalized = @luna-poly.normalize(terms)
/// // Result: [([12, 0], 2), ([0, 1], 3), ([0, 0], 3)]
/// ```
///
pub fn[A : Semiring + Eq] normalize(
  arr : Array[(Array[UInt], A)]
) -> ArrayView[(Array[UInt], A)] {
  let l = arr.length()
  arr.sort_by((a, b) => {
    let (a1, _) = a
    let (a2, _) = b
    a2.compare(a1)
  })
  arr[0:loop (0, 1, arr[0]) {
    (i, j, (ap, ac)) =>
      if j >= l {
        guard not(is_zero(ac)) else { i }
        arr[i] = (ap, ac)
        i + 1
      } else {
        let v = arr[j]
        if v.0 == ap {
          continue (i, j + 1, (ap, ac + v.1))
        } else if not(is_zero(ac)) {
          arr[i] = (ap, ac)
          continue (i + 1, j + 1, v)
        } else {
          continue (i, j + 1, v)
        }
      }
  }]
}

///|
/// Converts a multivariate polynomial to its string representation in a
/// human-readable mathematical format.
///
/// Returns a string representation of the polynomial where terms are displayed
/// in standard mathematical notation with variable names (X, Y, Z, X\_0, X\_1,
/// etc.) and exponents. Terms are separated by " + " and variables with
/// exponent 1 omit the exponent notation. If the polynomial has no terms,
/// returns "0".
///
/// Returns a `String` containing the mathematical representation of the
/// polynomial.
///
/// Example:
///
/// ```moonbit
/// let terms = [([0U, 0], 3), ([1, 1], 2), ([2, 0], 1)]
/// let poly = @luna_poly.MultiPoly::from_array(terms)
/// inspect(poly.to_string(), content="1 * X^2 + 2 * X * Y + 3")
/// ```
///
impl[A : Show] Show for MultiPoly[A] with to_string(self) {
  guard not(self.terms.is_empty()) else { "0" }
  let s_var = x => match x {
    0 => "X"
    1 => "Y"
    2 => "Z"
    n => "X_" + n.to_string()
  }
  let show_power = x => match x {
    (1U, n) => s_var(n)
    (i, n) => "\{s_var(n)}^\{i}"
  }
  let show_ceoff : ((ExpVec, A)) -> String = x => {
    let (ev, c) = x
    ev.vec
    .mapi((idx, v) => (v, idx))
    .filter(a => {
      let (v, _) = a
      v != 0
    })
    .map(show_power)
    .fold(init=c.to_string(), (acc, v) => acc + " * " + v)
  }
  self.terms.map(show_ceoff).join(" + ")
}

///|
/// Provides string formatting support for `MultiPoly` values by delegating to
/// the logger's string writing functionality.
///
/// This implementation allows `MultiPoly` values to be used with MoonBit's
/// standard formatting and output mechanisms, such as `println`, `print`, and
/// other functions that accept types implementing the `Show` trait.
///
/// Parameters:
///
/// * `self` : The `MultiPoly` instance to be formatted.
/// * `logger` : The logger instance that handles the actual string output.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.MultiPoly::from_array([([0U, 0], 1), ([12, 0], 2), ([0, 1], 3)])
/// println(poly) // Outputs: 2 * X^12 + 3 * Y + 1
/// ```
///
impl[A : Show] Show for MultiPoly[A] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Tests the construction of multivariate polynomials from arrays of
/// exponent-coefficient pairs.
///
/// This test verifies that `MultiPoly::from_array` correctly:
///
/// 1. Combines terms with identical exponent vectors by summing their
/// coefficients
/// 2. Removes terms with zero coefficients
/// 3. Sorts terms in the canonical order for polynomial representation
///
/// The test cases cover:
///
/// * **Basic term combination**: Multiple terms with the same exponent vector
///   `[0, 0]` (coefficients 1 and 2) are combined into a single term with
///   coefficient 3
/// * **Mixed exponent handling**: Terms with different exponent vectors like
///   `[12, 0]` (representing X^12) and `[0, 1]` (representing Y) are properly
///   included
/// * **Zero coefficient elimination**: All terms with zero coefficients are
///   filtered out, resulting in the zero polynomial "0"
/// * **Simple polynomial construction**: Basic terms like `[0, 0]` (constant)
///   and `[1, 1]` (X\*Y) are correctly represented
///
/// Each `inspect` call verifies the string representation matches the expected
/// mathematical form, where:
///
/// * `X^12` represents the first variable raised to the 12th power
/// * `Y` represents the second variable
/// * `X * Y` represents the product of both variables
/// * Coefficients are displayed as multipliers
///
test "from array" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  inspect(MultiPoly::from_array(a1), content="2 * X^12 + 3 * Y + 3")
  let a2 = [([0U, 0], 0), ([0, 1], 0), ([12, 0], 0)]
  inspect(MultiPoly::from_array(a2), content="0")
  let a3 = [([0U, 0], 1), ([1, 1], 2)]
  inspect(MultiPoly::from_array(a3), content="2 * X * Y + 1")
}

///|
/// Implements the addition operator for multivariate polynomials, combining
/// like terms and maintaining sorted order.
///
/// Parameters:
///
/// * `xs` : The first multivariate polynomial to add.
/// * `ys` : The second multivariate polynomial to add.
///
/// Returns a new multivariate polynomial representing the sum of `xs` and `ys`.
///
/// Example:
///
/// ```moonbit
/// let p1 = @luna-poly.MultiPoly::from_array([([0U, 0], 1), ([1, 1], 2)])
/// let p2 = @luna-poly.MultiPoly::from_array([([0U, 0], 3), ([2, 0], 4)])
/// inspect(p1 + p2, content="4 * X^2 + 2 * X * Y + 4")
/// ```
///
impl[A : Semiring + Eq] Add for MultiPoly[A] with op_add(xs, ys) {
  let len_xs = xs.terms.length()
  let len_ys = ys.terms.length()
  let zs = Array::make(len_xs + len_ys, (ExpVec::from_array([]), A::zero()))
  let s = loop (0, 0, 0) {
    (ix, iy, iz) =>
      if ix == len_xs && iy == len_ys {
        iz
      } else if ix == len_xs {
        Array::unsafe_blit(zs, iz, ys.terms, iy, len_ys - iy)
        iz + len_ys - iy
      } else if iy == len_ys {
        Array::unsafe_blit(zs, iz, xs.terms, ix, len_xs - ix)
        iz + len_xs - ix
      } else {
        let (xp, xc) = xs.terms[ix]
        let (yp, yc) = ys.terms[iy]
        if xp > yp {
          zs[iz] = (xp, xc)
          continue (ix + 1, iy, iz + 1)
        } else if xp < yp {
          zs[iz] = (yp, yc)
          continue (ix, iy + 1, iz + 1)
        } else {
          let c = xc + yc
          if is_zero(c) {
            continue (ix + 1, iy + 1, iz)
          } else {
            zs[iz] = (xp, c)
            continue (ix + 1, iy + 1, iz + 1)
          }
        }
      }
  }
  zs.resize(s, (ExpVec::from_array([]), A::zero()))
  { terms: zs }
}

///|
/// Negates a multivariate polynomial by applying the negation operation to all
/// coefficients.
///
/// Parameters:
///
/// * `x` : The multivariate polynomial to negate.
///
/// Returns a new multivariate polynomial where each coefficient is the negation
/// of the corresponding coefficient in the input polynomial.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.MultiPoly::from_array([([0U, 0], 1), ([1, 1], 2)])
/// let negated = -poly
/// inspect(negated, content="-2 * X * Y + -1")
/// ```
///
impl[A : Neg] Neg for MultiPoly[A] with op_neg(x) {
  {
    terms: x.terms.map(x => {
      let (e, a) = x
      (e, -a)
    }),
  }
}

///|
/// Tests the negation operator (`-`) for multivariate polynomials.
///
/// This test verifies that the negation operation correctly applies the unary
/// minus operator to all coefficients in a multivariate polynomial, and that
/// negated polynomials can be used in addition operations.
///
/// The test creates two multivariate polynomials from arrays of exponent
/// vectors and coefficients:
///
/// * `p1`: represents the polynomial `2 * X^12 + 3 * Y + 3`
/// * `p2`: represents the polynomial `2 * X^12 + 3 * X * Y + 5`
///
/// It then validates:
///
/// 1. The original polynomials are correctly constructed and displayed
/// 2. The negation of `p1` produces `-2 * X^12 + -3 * Y + -3`
/// 3. The negation of `p2` produces `-2 * X^12 + -3 * X * Y + -5`
/// 4. Addition with a negated polynomial (`p1 + -p2`) works correctly,
/// resulting in `-3 * X * Y + 3 * Y + -2`
///
/// This test ensures the `Neg` trait implementation for `MultiPoly[A]` works
/// correctly and maintains polynomial structure integrity during negation
/// operations.
///
test "op neg" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(-p1, content="-2 * X^12 + -3 * Y + -3")
  inspect(-p2, content="-2 * X^12 + -3 * X * Y + -5")
  inspect(p1 + -p2, content="-3 * X * Y + 3 * Y + -2")
}

///|
/// Subtracts one multivariate polynomial from another.
///
/// Parameters:
///
/// * `xs` : The multivariate polynomial from which to subtract (minuend).
/// * `ys` : The multivariate polynomial to subtract (subtrahend).
///
/// Returns a new multivariate polynomial representing the difference `xs - ys`.
///
/// Example:
///
/// ```moonbit
/// let p1 = @luna-poly.MultiPoly::from_array([([0U, 0], 5), ([1, 1], 3)])
/// let p2 = @luna-poly.MultiPoly::from_array([([0U, 0], 2), ([1, 1], 1)])
/// let diff = p1 - p2  // Results in polynomial with terms ([0, 0], 3) and ([1, 1], 2)
/// ```
///
impl[A : Semiring + Eq + Neg + Sub] Sub for MultiPoly[A] with op_sub(xs, ys) {
  xs + -ys
}

///|
/// Tests the addition and subtraction operations for multivariate polynomials.
///
/// This test verifies that the `Add` and `Sub` trait implementations for
/// `MultiPoly[A]` work correctly by:
///
/// 1. Creating two multivariate polynomials from arrays of (exponent vector,
/// coefficient) pairs
/// 2. Verifying their string representations match expected polynomial forms
/// 3. Testing addition operations (both `p1 + p2` and `p2 + p1`) to ensure
/// commutativity
/// 4. Testing subtraction operations (both `p1 - p2` and `p2 - p1`) to verify
/// proper handling of sign changes
/// 5. Confirming that like terms are properly combined and the results are in
/// canonical form
///
/// The test uses polynomials with multiple variables (X and Y) and various
/// exponent combinations to thoroughly exercise the arithmetic operations. The
/// expected outputs demonstrate proper term ordering, coefficient combination,
/// and variable representation in the polynomial's string format.
///
/// Example polynomials tested:
///
/// * `p1`: `2 * X^12 + 3 * Y + 3` (terms with X^12, Y, and constant)
/// * `p2`: `2 * X^12 + 3 * X * Y + 5` (terms with X^12, XY, and constant)
///
/// The test ensures that operations handle:
///
/// * Combining like terms (e.g., X^12 terms)
/// * Preserving distinct terms (e.g., Y vs XY terms)
/// * Proper coefficient arithmetic (addition/subtraction)
/// * Correct ordering and formatting of result terms
///
test "op add / sub" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(p2, content="2 * X^12 + 3 * X * Y + 5")
  inspect(p1 + p2, content="4 * X^12 + 3 * X * Y + 3 * Y + 8")
  inspect(p2 + p1, content="4 * X^12 + 3 * X * Y + 3 * Y + 8")
  inspect(p1 - p2, content="-3 * X * Y + 3 * Y + -2")
  inspect(p2 - p1, content="3 * X * Y + -3 * Y + 2")
}

///|
/// Multiplies the multivariate polynomial by a monomial term, scaling both the
/// exponents and coefficient.
///
/// Parameters:
///
/// * `self` : The multivariate polynomial to be scaled.
/// * `term` : A tuple containing an exponent vector and a coefficient. The
///   exponent vector specifies the powers for each variable, and the
///   coefficient is the scalar multiplier.
///
/// Returns a new multivariate polynomial where each term has been multiplied by
/// the given monomial term.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.MultiPoly::from_array([([0U, 0], 1), ([12, 0], 2), ([0, 1], 3)])
/// let scaled = p.scale((@luna-poly.ExpVec::from_array([1U, 1]), 2))
/// inspect(scaled, content="4 * X^13 * Y + 6 * X * Y^2 + 2 * X * Y")
/// ```
///
pub fn[A : Semiring + Eq] MultiPoly::scale(
  self : MultiPoly[A],
  term : (ExpVec, A)
) -> MultiPoly[A] {
  let (e, c) = term
  Array::makei(self.terms.length(), fn(i) {
    let (xp, xc) = self.terms[i]
    ((xp * e).vec, xc * c)
  }).filter(x => {
    let (_, c) = x
    not(is_zero(c))
  })
  |> MultiPoly::from_array
}

///|
/// Tests the `scale` method of `MultiPoly` by verifying polynomial scaling with
/// different terms and coefficients.
///
/// This test demonstrates the behavior of the `scale` method which multiplies a
/// multivariate polynomial by a monomial term. The test creates two sample
/// polynomials and scales them with specific terms to verify the mathematical
/// correctness of the operation.
///
/// The test verifies:
///
/// * Creation of multivariate polynomials from coefficient arrays
/// * String representation of polynomials
/// * Scaling with positive and negative coefficients
/// * Proper handling of variable exponent addition during scaling
///
/// Example polynomials tested:
///
/// * `p1`: `2 * X^12 + 3 * Y + 3` scaled by `(X * Y, -3)`
/// * `p2`: `2 * X^12 + 3 * X * Y + 5` scaled by `(X * Y, 3)`
///
/// The scaling operation multiplies each term in the polynomial by the given
/// monomial, adding exponents for matching variables and multiplying
/// coefficients.
///
test "scale" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(p2, content="2 * X^12 + 3 * X * Y + 5")
  inspect(
    p1.scale((ExpVec::from_array([1U, 1]), -3)),
    content="-6 * X^13 * Y + -9 * X * Y^2 + -9 * X * Y",
  )
  inspect(
    p2.scale((ExpVec::from_array([1U, 1]), 3)),
    content="6 * X^13 * Y + 9 * X^2 * Y^2 + 15 * X * Y",
  )
}
