///|
/// Sparse multivariate polynomial represented as a map from exponent vectors to
/// coefficients.
///
/// Example:
///
/// ```moonbit
/// // Create a polynomial: xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (ExpVec::from_array([1, 2, 3]), 1),
///   (ExpVec::from_array([2, 3, 4]), 2), 
///   (ExpVec::from_array([3, 4, 5]), 3)
/// ])
///
/// // Access coefficients
/// match poly[ExpVec::from_array([1, 2, 3])] {
///   Some(coeff) => println("Coefficient: \{coeff}")
///   None => println("Term not found")
/// }
///
/// // Iterate over terms
/// for exp_vec, coeff in poly {
///   println("Term: \{coeff} * \{exp_vec}")
/// }
///
/// // Evaluate at specific values
/// let result = poly.eval([2, 3, 1])  // x=2, y=3, z=1
/// ```
///
type SparsePolynomial[V] @sorted_map.T[ExpVec, V] derive(Eq)

///|
/// Converts a sparse polynomial to its string representation in mathematical
/// notation.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to convert to string.
/// * `logger` : The output logger to write the string representation to.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2, 3]), 1),
///   (@luna-poly.ExpVec::from_array([2, 3, 4]), 2)
/// ])
/// println(poly.to_string()) // Outputs: "xy²z³ + 2x²y³z⁴"
/// ```
///
pub impl[V : Eq + Show + Semiring] Show for SparsePolynomial[V] with output(
  self,
  logger
) {
  let mut first = true
  for exp_vec, coefficient in self {
    if not(first) {
      logger.write_string(" + ")
    }
    if exp_vec.is_one() {
      logger.write_object(coefficient)
    } else {
      if coefficient != V::one() {
        logger.write_object(coefficient)
      }
      logger.write_object(exp_vec)
    }
    first = false
  }
  if first {
    logger.write_object(V::zero())
  }
}

///|
/// Tests the string representation (`Show` implementation) of
/// `SparsePolynomial`.
///
/// This test verifies that `SparsePolynomial` correctly formats multivariate
/// polynomials as human-readable strings, handling various cases including:
///
/// 1. **Normal polynomial with multiple terms**: Creates a polynomial with
/// three terms `xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵` and verifies the string output
/// matches the expected mathematical notation.
///
/// 2. **Polynomial with zero coefficients**: Tests that terms with zero
/// coefficients are automatically filtered out during string conversion. A
/// polynomial created with a zero coefficient term should not include that term
/// in the final string representation.
///
/// 3. **Zero polynomial**: Verifies that a polynomial consisting only of zero
/// terms displays as "0".
///
/// The test ensures that:
///
/// * Variable names follow the standard convention (x, y, z for the first three
///   variables)
/// * Exponents are properly formatted using superscript notation (², ³, ⁴,
///   etc.)
/// * Coefficients of 1 are omitted for readability (showing `xy²` instead of
///   `1xy²`)
/// * Terms are separated by " + "
/// * Zero coefficients are handled correctly by omission
/// * The special case of an entirely zero polynomial displays as "0"
///
/// This comprehensive test validates the polynomial's visual representation
/// which is crucial for debugging, mathematical display, and user interaction.
///
test "show" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  assert_eq(poly.to_string(), "xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵")
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 0),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  assert_eq(poly_2.to_string(), "2x²y³z⁴ + 3x³y⁴z⁵")
  let poly_3 = SparsePolynomial::from_array([(ExpVec::from_array([]), 0)])
  assert_eq(poly_3.to_string(), "0")
}

///|
/// Sets the coefficient for a specific exponent vector in the sparse
/// polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to modify.
/// * `exp_vec` : The exponent vector specifying the monomial.
/// * `coefficient` : The coefficient value to assign to the monomial.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::new()
/// let exp_vec = @luna-poly.ExpVec::from_array([1, 2, 0])
/// poly[exp_vec] = 5  // Sets coefficient of xy² to 5
/// ```
///
pub fn[V] op_set(
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  self.inner()[exp_vec] = coefficient
}

///|
/// Retrieves the coefficient associated with the given exponent vector.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to query.
/// * `exp_vec` : The exponent vector whose coefficient to retrieve.
///
/// Returns `Some(coefficient)` if the exponent vector exists in the polynomial,
/// `None` otherwise.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 5),
///   (@luna-poly.ExpVec::from_array([3, 0]), 3)
/// ])
/// let exp = @luna-poly.ExpVec::from_array([1, 2])
/// inspect(poly[exp], content="Some(5)")
/// let missing_exp = @luna-poly.ExpVec::from_array([0, 1])
/// inspect(poly[missing_exp], content="None")
/// ```
///
pub fn[V] op_get(self : SparsePolynomial[V], exp_vec : ExpVec) -> V? {
  self.get(exp_vec)
}

///|
/// Creates a new empty sparse polynomial.
///
/// Returns a new `SparsePolynomial[V]` with no terms.
///
/// Example:
///
/// ```moonbit
/// let poly : SparsePolynomial[Int] = SparsePolynomial::new()
/// inspect(poly.is_empty(), content="true")
/// inspect(poly.size(), content="0")
/// ```
///
pub fn[V] SparsePolynomial::new() -> SparsePolynomial[V] {
  @sorted_map.new()
}

///|
/// Creates a new sparse polynomial from an array of exponent vector and
/// coefficient pairs.
///
/// Parameters:
///
/// * `terms` : An array of tuples where each tuple contains an exponent vector
///   (`ExpVec`) and its corresponding coefficient of type `V`.
///
/// Returns a new `SparsePolynomial[V]` containing all the terms from the input
/// array, with duplicate exponent vectors automatically combined by adding
/// their coefficients.
///
/// Example:
///
/// ```moonbit
/// let terms = [
///   (ExpVec::from_array([1, 2]), 3),  // 3x¹y²
///   (ExpVec::from_array([0, 1]), 2),  // 2y¹
///   (ExpVec::from_array([1, 2]), 1)   // 1x¹y² (will be combined with first term)
/// ]
/// let poly = SparsePolynomial::from_array(terms)
/// // Results in polynomial: 4x¹y² + 2y¹
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::from_array(
  arr : Array[(ExpVec, V)]
) -> SparsePolynomial[V] {
  let poly = SparsePolynomial::new()
  for x in arr {
    let (exp_vec, coefficient) = x
    poly.add_term_inplace(exp_vec, coefficient)
  }
  poly
}

///|
/// Removes the term with the specified exponent vector from this sparse
/// polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to remove the term from.
/// * `exp_vec` : The exponent vector identifying the term to remove.
///
pub fn[V] SparsePolynomial::remove(
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> Unit {
  self.inner().remove(exp_vec)
}

///|
/// Retrieves the coefficient associated with the given exponent vector.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to query.
/// * `exp_vec` : The exponent vector to look up in the polynomial.
///
/// Returns `Some(coefficient)` if the exponent vector exists in the polynomial,
/// or `None` if it doesn't exist.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 5)
/// ])
/// let exp_vec = @luna-poly.ExpVec::from_array([1, 2])
/// inspect(poly.get(exp_vec), content="Some(3)")
/// let missing_exp = @luna-poly.ExpVec::from_array([2, 0])
/// inspect(poly.get(missing_exp), content="None")
/// ```
///
pub fn[V] SparsePolynomial::get(
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> V? {
  self.inner().get(exp_vec)
}

///|
/// Checks whether the sparse polynomial contains a term with the specified
/// exponent vector.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to check.
/// * `exp_vec` : The exponent vector to search for.
///
/// Returns `true` if the polynomial contains a term with the given exponent
/// vector, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 5)
/// ])
/// let exp = @luna-poly.ExpVec::from_array([1, 2])
/// inspect(poly.contains(exp), content="true")
/// ```
///
pub fn[V] SparsePolynomial::contains(
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> Bool {
  self.inner().contains(exp_vec)
}

///|
/// Checks if the sparse polynomial contains no terms.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to check.
///
/// Returns `true` if the polynomial has no terms, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let empty_poly : @luna-poly.SparsePolynomial[Int] = @luna-poly.SparsePolynomial::new()
/// inspect(empty_poly.is_empty(), content="true")
///
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3)
/// ])
/// inspect(poly.is_empty(), content="false")
/// ```
///
pub fn[V] SparsePolynomial::is_empty(self : SparsePolynomial[V]) -> Bool {
  self.inner().is_empty()
}

///|
/// Returns the number of terms (non-zero coefficients) in the sparse
/// polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to query.
///
/// Returns the count of terms as an integer.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 2)
/// ])
/// inspect(poly.size(), content="2")
/// ```
///
pub fn[V] SparsePolynomial::size(self : SparsePolynomial[V]) -> Int {
  self.inner().size()
}

///|
/// Removes all key-value pairs from the sparse polynomial, making it empty.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to be cleared.
///
pub fn[V] SparsePolynomial::clear(self : SparsePolynomial[V]) -> Unit {
  self.inner().clear()
}

///|
/// Iterates over all term-coefficient pairs in the sparse polynomial, applying
/// the given function to each pair.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to iterate over.
/// * `f` : A function that takes an exponent vector and its corresponding
///   coefficient as arguments.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 2)
/// ])
/// poly.each(fn(exp_vec, coeff) {
///   println("Term: \{exp_vec} with coefficient \{coeff}")
/// })
/// ```
///
pub fn[V] SparsePolynomial::each(
  self : SparsePolynomial[V],
  f : (ExpVec, V) -> Unit
) -> Unit {
  self.inner().each(f)
}

///|
/// Iterates over each term in the sparse polynomial with indexed access,
/// applying a function to each index, exponent vector, and coefficient.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to iterate over.
/// * `f` : A function that takes three parameters: the index of the term, the
///   exponent vector, and the coefficient value. This function is called for
///   each term in the polynomial.
///
/// Example:
///
/// ```moonbit
/// let poly = SparsePolynomial::from_array([
///   (ExpVec::from_array([1, 2]), 3),
///   (ExpVec::from_array([2, 1]), 5)
/// ])
/// poly.eachi(fn(i, exp_vec, coeff) {
///   println("Term \{i}: \{exp_vec} with coefficient \{coeff}")
/// })
/// // Output:
/// // Term 0: xy² with coefficient 3
/// // Term 1: x²y with coefficient 5
/// ```
///
pub fn[V] SparsePolynomial::eachi(
  self : SparsePolynomial[V],
  f : (Int, ExpVec, V) -> Unit
) -> Unit {
  self.inner().eachi(f)
}

///|
/// Returns an array containing all the exponent vectors (keys) in the sparse
/// polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to extract keys from.
///
/// Returns an `Array[ExpVec]` containing all the exponent vectors present in
/// the polynomial.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 5),
///   (@luna-poly.ExpVec::from_array([2, 0]), 2)
/// ])
/// let keys = poly.keys()
/// // keys contains the exponent vectors [1, 2], [0, 1], and [2, 0]
/// ```
///
pub fn[V] SparsePolynomial::keys(self : SparsePolynomial[V]) -> Array[ExpVec] {
  self.inner().keys()
}

///|
/// Returns an array containing all the coefficients stored in the sparse
/// polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial from which to extract coefficients.
///
/// Returns an array of coefficients of type `V`.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([2, 1]), 5),
///   (@luna-poly.ExpVec::from_array([0, 0]), 7)
/// ])
/// let coeffs = poly.values()
/// // coeffs contains [3, 5, 7] in some order
/// ```
///
pub fn[V] SparsePolynomial::values(self : SparsePolynomial[V]) -> Array[V] {
  self.inner().values()
}

///|
/// Converts the sparse polynomial into an array of (exponent vector,
/// coefficient) pairs.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to convert.
///
/// Returns an array containing all terms of the polynomial as tuples of
/// exponent vectors and their corresponding coefficients.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([0, 1]), 5)
/// ])
/// let terms = poly.to_array()
/// // terms contains [(@luna-poly.ExpVec::from_array([1, 2]), 3), (@luna-poly.ExpVec::from_array([0, 1]), 5)]
/// ```
///
pub fn[V] SparsePolynomial::to_array(
  self : SparsePolynomial[V]
) -> Array[(ExpVec, V)] {
  self.inner().to_array()
}

///|
/// Returns an iterator over the key-value pairs in the sparse polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to iterate over.
///
/// Returns an `Iter[(ExpVec, V)]` that yields tuples of exponent vectors and
/// their corresponding coefficients.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([2, 1]), 5)
/// ])
/// poly.iter().each(fn(exp_vec, coeff) {
///   println("Exponent: \{exp_vec}, Coefficient: \{coeff}")
/// })
/// ```
///
pub fn[V] SparsePolynomial::iter(
  self : SparsePolynomial[V]
) -> Iter[(ExpVec, V)] {
  self.inner().iter()
}

///|
/// Returns an iterator over the exponent vectors and coefficients as separate
/// values.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to iterate over.
///
/// Returns an `Iter2[ExpVec, V]` that yields exponent vectors and their
/// corresponding coefficients separately.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna_poly.SparsePolynomial::from_array([
///   (@luna_poly.ExpVec::from_array([1, 2]), 3),
///   (@luna_poly.ExpVec::from_array([0, 1]), 5)
/// ])
/// poly.iter2().each(fn(exp_vec, coeff) {
///   println("Exponent: \{exp_vec}, Coefficient: \{coeff}")
/// })
/// ```
///
pub fn[V] SparsePolynomial::iter2(
  self : SparsePolynomial[V]
) -> Iter2[ExpVec, V] {
  self.inner().iter2()
}

///|
/// Creates a sparse polynomial from an iterator of exponential vector and
/// coefficient pairs.
///
/// Parameters:
///
/// * `iter` : An iterator yielding tuples of exponential vectors and their
///   corresponding coefficients.
///
/// Returns a new sparse polynomial containing all the terms from the iterator,
/// with like terms automatically combined.
///
/// Example:
///
/// ```moonbit
/// let terms = [(ExpVec::from_array([1, 2]), 3), (ExpVec::from_array([0, 1]), 2)]
/// let poly = SparsePolynomial::from_iter(Iter::from_array(terms))
/// inspect(poly.to_string(), content="2y + 3xy²")
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::from_iter(
  iter : Iter[(ExpVec, V)]
) -> SparsePolynomial[V] {
  let m = SparsePolynomial::new()
  iter.each(fn(e) {
    let (exp_vec, coefficient) = e
    m.add_term_inplace(exp_vec.copy(), coefficient)
  })
  m
}

///|
/// Returns an iterator over the key-value pairs within a specified range of
/// exponent vectors.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to iterate over.
/// * `low` : The lower bound of the range (inclusive).
/// * `high` : The upper bound of the range (exclusive).
///
/// Returns an `Iter2[ExpVec, V]` that yields exponent vector and coefficient
/// pairs where the exponent vectors fall within the specified range `[low,
/// high)`.
///
pub fn[V] SparsePolynomial::range(
  self : SparsePolynomial[V],
  low : ExpVec,
  hight : ExpVec
) -> Iter2[ExpVec, V] {
  self.inner().range(low, hight)
}

///|
/// Creates a deep copy of the sparse polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to copy.
///
/// Returns a new `SparsePolynomial[V]` that is an independent copy of the
/// original polynomial.
///
/// Example:
///
/// ```moonbit
/// let original = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([2, 1]), 5)
/// ])
/// let copied = original.copy()
/// // Modifications to `copied` will not affect `original`
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::copy(
  self : SparsePolynomial[V]
) -> SparsePolynomial[V] {
  SparsePolynomial::from_iter(self.iter())
}

///|
/// Creates a zero polynomial for the `SparsePolynomial[V]` type.
///
/// Returns a `SparsePolynomial[V]` representing the zero polynomial, which
/// contains a single term with the unit exponent vector and coefficient of
/// zero.
///
/// Example:
///
/// ```moonbit
/// let zero_poly = SparsePolynomial::zero() // Assuming V is Int
/// inspect(zero_poly.to_string(), content="0")
/// ```
///
pub impl[V : Zero] Zero for SparsePolynomial[V] with zero() -> SparsePolynomial[
  V,
] {
  let sp = SparsePolynomial::new().inner()
  sp..add(ExpVec::one(), V::zero())
  sp
}

///|
/// Adds a term with the given exponent vector and coefficient to this sparse
/// polynomial, modifying the polynomial in place.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to modify.
/// * `exp_vec` : The exponent vector representing the variables and their
///   powers for the term.
/// * `coefficient` : The coefficient of the term to add.
///
/// Panics:
///
/// * If the polynomial becomes empty after the operation and fails to add the
///   zero term.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::new()
/// let exp_vec = @luna-poly.ExpVec::from_array([1, 2])  // represents x^1 * y^2
/// poly.add_term_inplace(exp_vec, 5)  // adds 5xy²
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::add_term_inplace(
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  guard coefficient != V::zero() else { return }
  if self.inner().get(exp_vec) is None {
    self.inner().add(exp_vec, coefficient)
  } else {
    let new_coe = self.inner().get(exp_vec).unwrap() + coefficient
    guard new_coe != V::zero() else { self.inner().remove(exp_vec) }
    self.inner()[exp_vec] = new_coe
    let size = self.size()
    if size == 0 {
      self.inner().add(ExpVec::one(), V::zero())
    }
  }
}

///|
/// Adds a term with the given exponent vector and coefficient to the sparse
/// polynomial, returning a new polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to add the term to.
/// * `exp_vec` : The exponent vector representing the powers of each variable
///   in the term.
/// * `coefficient` : The coefficient of the term to be added.
///
/// Returns a new `SparsePolynomial[V]` with the term added.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::new()
/// let exp_vec = @luna-poly.ExpVec::from_array([1, 2])  // x¹y²
/// let new_poly = poly.add_term(exp_vec, 5)
/// // new_poly now contains the term 5x¹y²
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::add_term(
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> SparsePolynomial[V] {
  let new_poly = self.copy()
  new_poly.add_term_inplace(exp_vec, coefficient)
  new_poly
}

///|
/// Adds another sparse polynomial to this polynomial by modifying this
/// polynomial in place.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to be modified.
/// * `other` : The sparse polynomial to add to `self`.
///
/// Example:
///
/// ```moonbit
/// let poly1 = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 0]), 2),  // 2x
///   (@luna-poly.ExpVec::from_array([0, 1]), 3)   // 3y
/// ])
/// let poly2 = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 0]), 1),  // x
///   (@luna-poly.ExpVec::from_array([0, 2]), 4)   // 4y²
/// ])
/// poly1.add(poly2)
/// // poly1 is now 3x + 3y + 4y²
/// ```
///
pub fn[V : Eq + AddMonoid] SparsePolynomial::add(
  self : SparsePolynomial[V],
  other : SparsePolynomial[V]
) -> Unit {
  for x in other {
    let (exp_vec, coefficient) = x
    self.add_term_inplace(exp_vec, coefficient)
  }
}

///|
/// Adds two sparse polynomials together, returning a new sparse polynomial
/// containing the sum of all terms.
///
/// Parameters:
///
/// * `self` : The first sparse polynomial to be added.
/// * `other` : The second sparse polynomial to be added.
///
/// Returns a new `SparsePolynomial[V]` representing the sum of the two input
/// polynomials.
///
/// Example:
///
/// ```moonbit
/// let poly1 = SparsePolynomial::from_array([
///   (ExpVec::from_array([1, 2]), 3), // 3xy²
///   (ExpVec::from_array([2, 1]), 2), // 2x²y
/// ])
/// let poly2 = SparsePolynomial::from_array([
///   (ExpVec::from_array([1, 2]), 1), // xy²
///   (ExpVec::from_array([0, 3]), 4), // 4y³
/// ])
/// let result = poly1 + poly2
/// // result represents: 4xy² + 2x²y + 4y³
/// ```
///
pub impl[V : Eq + AddMonoid] Add for SparsePolynomial[V] with op_add(
  self,
  other
) {
  let res = SparsePolynomial::new()
  for x in self {
    let (exp_vec, coefficient) = x
    res.add_term_inplace(exp_vec, coefficient)
  }
  for x in other {
    let (exp_vec, coefficient) = x
    res.add_term_inplace(exp_vec, coefficient)
  }
  res
}

///|
/// Multiplies this sparse polynomial by a monomial term in-place, modifying the
/// polynomial directly.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to be multiplied.
/// * `exp_vec` : The exponent vector of the monomial term.
/// * `coefficient` : The coefficient of the monomial term.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 3),
///   (@luna-poly.ExpVec::from_array([2, 1]), 4)
/// ])
/// // poly represents 3xy² + 4x²y
/// poly.mul_term_inplace(@luna-poly.ExpVec::from_array([1, 1]), 2)
/// // poly now represents 6x²y³ + 8x³y²
/// ```
///
pub fn[V : Eq + Semiring] SparsePolynomial::mul_term_inplace(
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  if coefficient == V::zero() || self.size() == 0 {
    self.clear()
    self.inner().add(ExpVec::one(), V::zero())
  } else if exp_vec.is_one() && coefficient == V::one() {
    return
  } else if exp_vec.is_one() {
    self.each(fn(iter_exp_vec, iter_coefficient) {
      self.inner()[iter_exp_vec] = iter_coefficient * coefficient
    })
  } else if coefficient == V::one() {
    let other = self.copy()
    self.clear()
    for x in other {
      let (old_exp_vec, old_coefficient) = x
      self.inner().add(old_exp_vec * exp_vec, old_coefficient)
    }
  } else {
    let other = self.copy()
    self.clear()
    for x in other {
      let (old_exp_vec, old_coefficient) = x
      self.inner().add(old_exp_vec * exp_vec, old_coefficient * coefficient)
    }
  }
}

///|
/// Multiplies all terms in the polynomial by a single term defined by an
/// exponent vector and coefficient.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to multiply.
/// * `exp_vec` : The exponent vector of the term to multiply by.
/// * `coefficient` : The coefficient of the term to multiply by.
///
/// Returns a new sparse polynomial that is the product of the original
/// polynomial and the given term.
///
/// Example:
///
/// ```moonbit
/// // Create a polynomial: xy² + 2x²y
/// let poly = @luna_poly.SparsePolynomial::from_array([
///   (@luna_poly.ExpVec::from_array([1, 2]), 1),
///   (@luna_poly.ExpVec::from_array([2, 1]), 2)
/// ])
///
/// // Multiply by the term 3x²y (coefficient=3, exp_vec=[2,1])
/// let exp_vec = @luna_poly.ExpVec::from_array([2, 1])
/// let result = poly.mul_term(exp_vec, 3)
/// // Result: 3x³y³ + 6x⁴y²
/// ```
///
pub fn[V : Eq + Semiring] SparsePolynomial::mul_term(
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> SparsePolynomial[V] {
  if coefficient == V::zero() || self.size() == 0 {
    let sp = SparsePolynomial::new().inner()
    sp..add(ExpVec::one(), V::zero())
    sp
  } else if exp_vec.is_one() && coefficient == V::one() {
    return self.copy()
  } else if exp_vec.is_one() {
    let res = self.copy()
    res..each(fn(iter_exp_vec, iter_coefficient) {
      res.inner()[iter_exp_vec] = iter_coefficient * coefficient
    })
    res
  } else if coefficient == V::one() {
    let res = SparsePolynomial::new()
    for x in self {
      let (old_exp_vec, old_coefficient) = x
      res.inner().add(old_exp_vec * exp_vec, old_coefficient)
    }
    res
  } else {
    let res = SparsePolynomial::new()
    for x in self {
      let (old_exp_vec, old_coefficient) = x
      res.inner().add(old_exp_vec * exp_vec, old_coefficient * coefficient)
    }
    res
  }
}

///|
/// Multiplies two sparse polynomials using an optimized algorithm that iterates
/// through the larger polynomial and accumulates results from multiplying the
/// smaller polynomial by each term.
///
/// Parameters:
///
/// * `self` : The first sparse polynomial to multiply.
/// * `other` : The second sparse polynomial to multiply.
///
/// Returns a new sparse polynomial representing the product of the two input
/// polynomials.
///
/// Example:
///
/// ```moonbit
/// let poly1 = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 0]), 2),  // 2x
///   (@luna-poly.ExpVec::from_array([0, 1]), 3)   // 3y
/// ])
/// let poly2 = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 0]), 1),  // x
///   (@luna-poly.ExpVec::from_array([0, 1]), 1)   // y
/// ])
/// let result = poly1 * poly2
/// inspect(result.to_string(), content="2x² + 5xy + 3y²")
/// ```
///
pub impl[A : Semiring + Eq] Mul for SparsePolynomial[A] with op_mul(self, other) {
  let l_self = self.size()
  let l_other = other.size()
  let larger = if l_self >= l_other { self } else { other }
  let smaller = if l_self >= l_other { other } else { self }
  let mut res = SparsePolynomial::new()
  let mut fst = true
  for x in larger {
    if fst {
      res = smaller.mul_term(x.0, x.1)
      fst = false
    } else {
      res.add(smaller.mul_term(x.0, x.1))
    }
  }
  res
}

///|
/// Computes the power of a base raised to an exponent using fast
/// exponentiation.
///
/// Parameters:
///
/// * `base` : The base value to be raised to the power.
/// * `exponent` : The non-negative integer exponent.
///
/// Returns the result of `base` raised to the power of `exponent`.
///
/// Example:
///
/// ```moonbit
/// // For integers
/// inspect(qpow(2, 3U), content="8")
/// inspect(qpow(5, 0U), content="1")
/// inspect(qpow(0, 5U), content="0")
///
/// // For floating-point numbers
/// inspect(qpow(2.0, 4U), content="16.0")
/// ```
///
fn[V : Eq + Semiring] qpow(b : V, e : UInt) -> V {
  if b == V::zero() {
    return V::zero()
  } else if e == 0 {
    return V::one()
  } else if e == 1 {
    return b
  } else {
    let half = qpow(b, e / 2)
    if e % 2 == 0 {
      return half * half
    } else {
      return half * half * b
    }
  }
}

///|
/// Evaluates a sparse polynomial at a specific variable by substituting the
/// variable with a given value.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to evaluate.
/// * `var_index` : The index of the variable to substitute (0-based indexing).
/// * `val` : The value to substitute for the variable at the specified index.
///
/// Returns a new sparse polynomial with the specified variable evaluated at the
/// given value.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial x² + y² (where x is variable 0, y is variable 1)
/// let poly = SparsePolynomial::from_array([
///   (ExpVec::from_array([2, 0]), 1),  // x²
///   (ExpVec::from_array([0, 2]), 1),  // y²
/// ])
///
/// // Evaluate at x = 2 (variable index 0)
/// let result = poly.eval_at(0, 2)
/// // Result: 4 + y² (x² becomes 4 when x = 2)
/// ```
///
pub fn[V : Show + Eq + Semiring] SparsePolynomial::eval_at(
  self : SparsePolynomial[V],
  var_index : Int,
  val : V
) -> SparsePolynomial[V] {
  if val == V::zero() {
    return SparsePolynomial::zero()
  }
  let calc_coe = fn(t : (ExpVec, V), vi : Int, v : V) -> (ExpVec, V) {
    let (ev, c) = t
    if ev.is_one() || vi >= ev.length() {
      return (ev, c)
    }
    let exp = ev[vi]
    let mul_c = qpow(v, exp)
    if mul_c == V::one() {
      let ev_copy = ev.copy()
      ev_copy[vi] = 0
      ev_copy.shrink()
      return (ev_copy, c)
    } else if mul_c == V::zero() {
      return (ExpVec::one(), V::zero())
    } else {
      let ev_copy = ev.copy()
      ev_copy[vi] = 0
      ev_copy.shrink()
      return (ev_copy, c * mul_c)
    }
  }
  let res = SparsePolynomial::new()
  for x in self {
    let (ev_x, c_x) = x
    let (ev, c) = calc_coe((ev_x, c_x), var_index, val)
    res.add_term_inplace(ev, c)
  }
  res
}

///|
/// Evaluates the polynomial by substituting multiple variables with specific
/// values simultaneously.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to evaluate.
/// * `vars` : An array of variable-value pairs, where each pair contains the
///   variable index and the value to substitute for that variable.
///
/// Returns a new sparse polynomial with the specified variables substituted
/// with their corresponding values.
///
/// Example:
///
/// ```moonbit
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2]), 1),
///   (@luna-poly.ExpVec::from_array([2, 1]), 1)
/// ])
/// // poly represents xy² + x²y
/// let result = poly.eval_at_many([(0, 2), (1, 3)])
/// // Substitutes x=2 and y=3, resulting in polynomial with value 30
/// inspect(result, content="30")
/// ```
///
pub fn[V : Show + Eq + Semiring] SparsePolynomial::eval_at_many(
  self : SparsePolynomial[V],
  vars : Array[(Int, V)]
) -> SparsePolynomial[V] {
  if vars.length() == 1 {
    return SparsePolynomial::eval_at(self, vars[0].0, vars[0].1)
  }
  let calc_coe = fn(t : (ExpVec, V), vars : Array[(Int, V)]) -> (ExpVec, V) {
    let (ev, c) = t
    if ev.is_one() {
      return (ev, c)
    }
    let mut mul_c_all = V::one()
    let ev_copy = ev.copy()
    for va in vars {
      let (vi, v) = va
      if vi >= ev.length() {
        continue
      }
      let exp = ev[vi]
      mul_c_all = mul_c_all * qpow(v, exp)
      ev_copy[vi] = 0
    }
    ev_copy.shrink()
    if mul_c_all == V::one() {
      return (ev_copy, c)
    } else if mul_c_all == V::zero() {
      return (ExpVec::one(), V::zero())
    } else {
      return (ev_copy, c * mul_c_all)
    }
  }
  let res = SparsePolynomial::new()
  for x in self {
    let (ev_x, c_x) = x
    let (ev, c) = calc_coe((ev_x, c_x), vars)
    res.add_term_inplace(ev, c)
  }
  res
}

///|
/// Evaluates the sparse polynomial by substituting the given variable values.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to evaluate.
/// * `vars` : An array of values to substitute for the variables, where
///   `vars[i]` is the value for the i-th variable.
///
/// Returns the result of evaluating the polynomial with the given variable
/// substitutions.
///
/// Example:
///
/// ```moonbit
/// // Polynomial: x² + y² (represented as sparse polynomial)
/// let poly = SparsePolynomial::from_array([
///   (ExpVec::from_array([2, 0]), 1), // x²
///   (ExpVec::from_array([0, 2]), 1)  // y²
/// ])
/// // Evaluate at x=3, y=4: 3² + 4² = 9 + 16 = 25
/// inspect(poly.eval([3, 4]), content="25")
/// ```
///
pub fn[V : Eq + Semiring] SparsePolynomial::eval(
  self : SparsePolynomial[V],
  vars : Array[V]
) -> V {
  let calc_coe = fn(t : (ExpVec, V), vars : Array[V]) -> V {
    let (ev, c) = t
    let mut mul_c_all = V::one()
    if ev.is_one() {
      return c
    }
    for i in 0..<vars.length() {
      if i >= ev.length() {
        break
      }
      let exp = ev[i]
      mul_c_all = mul_c_all * qpow(vars[i], exp)
    }
    return mul_c_all * c
  }
  let mut sum = V::zero()
  for x in self {
    sum = sum + calc_coe(x, vars)
  }
  sum
}

///|
/// Replaces a variable at the specified index with a constant coefficient
/// throughout the polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to perform the replacement on.
/// * `index` : The index of the variable to replace (must be within bounds of
///   the exponent vectors).
/// * `coeff` : The constant coefficient to substitute for the variable.
///
/// Returns a new sparse polynomial with the specified variable replaced by the
/// constant.
///
/// Panics if `index` is negative or greater than or equal to the length of any
/// exponent vector in the polynomial.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial: xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2, 3]), 1),
///   (@luna-poly.ExpVec::from_array([2, 3, 4]), 2),
///   (@luna-poly.ExpVec::from_array([3, 4, 5]), 3),
/// ])
///
/// // Replace z (index 2) with constant 2
/// // Result: 8xy² + 32x²y³ + 96x³y⁴
/// let result = poly.replace_const(2, 2)
/// ```
///
pub fn[A : Semiring + Eq] SparsePolynomial::replace_const(
  self : SparsePolynomial[A],
  index : Int,
  coeff : A
) -> SparsePolynomial[A] {
  let res = self.copy()
  for expvec, coef in res {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    let new_coef = loop (expvec[index], coef) {
      (0, coef) => break coef
      (expon, coef) => continue (expon - 1, coef * coeff)
    }
    expvec[index] = 0
    res[expvec] = new_coef
  }
  res
}

///|
/// Replaces all occurrences of variable at `source_index` with the variable at
/// `target_index` by adding their exponents.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to modify.
/// * `source_index` : The index of the variable to be replaced.
/// * `target_index` : The index of the variable that will receive the combined
///   exponents.
///
/// Returns a new sparse polynomial with the variable replacement applied.
///
/// Panics if `source_index` is negative, `source_index` is greater than or
/// equal to the length of any exponent vector, `target_index` is less than or
/// equal to zero, or `target_index` is greater than or equal to the length of
/// any exponent vector.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial xy²z³ + 2x²y³z⁴
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 2, 3]), 1),
///   (@luna-poly.ExpVec::from_array([2, 3, 4]), 2)
/// ])
/// // Replace y (index 1) with z (index 2): y becomes part of z
/// let result = poly.replace_variable(1, 2)
/// // Result: xz⁵ + 2x²z⁷
/// ```
///
pub fn[A : Semiring + Eq] SparsePolynomial::replace_variable(
  self : SparsePolynomial[A],
  index1 : Int,
  index2 : Int
) -> SparsePolynomial[A] {
  let res = self.copy()
  for expvec, _ in res {
    guard index1 >= 0 &&
      index1 < expvec.length() &&
      index2 > 0 &&
      index2 < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    expvec[index2] = expvec[index1] + expvec[index2]
    expvec[index1] = 0
  }
  res
}

///|
/// Replaces a variable at the specified index with a term (monomial) in the
/// sparse polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to perform the replacement on.
/// * `index` : The index of the variable to replace (0-based indexing).
/// * `exp` : The exponent vector representing the term to substitute.
/// * `coeff` : The coefficient of the substituting term.
///
/// Returns a new sparse polynomial with the variable replaced by the specified
/// term.
///
/// Panics if `index` is negative or greater than or equal to the length of any
/// exponent vector in the polynomial.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial: x²y³z⁴ + 2xy²z³
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([2, 3, 4]), 1),
///   (@luna-poly.ExpVec::from_array([1, 2, 3]), 2)
/// ])
///
/// // Replace z (index 2) with x²y²z²
/// let new_exp = @luna-poly.ExpVec::from_array([2, 2, 2])
/// let result = poly.replace_term(2, new_exp, 1)
/// // Result: x¹⁰y¹¹z⁸ + 2x⁷y⁸z⁶
/// ```
///
pub fn[A : Semiring + Eq] SparsePolynomial::replace_term(
  self : SparsePolynomial[A],
  index : Int,
  exp : ExpVec,
  coeff : A
) -> SparsePolynomial[A] {
  let res = SparsePolynomial::new()
  for expvec, coef in self {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    let expon = expvec[index]
    let copy_expvec = expvec.copy()
    copy_expvec[index] = 0
    let new_coeff = loop (expon, coef) {
      (0, coef) => break coef
      (exp, coef) => continue (exp - 1, coef * coeff)
    }
    let temp_exp = exp.copy()
    /// ExpVec doesn't have iter and iter2
    for i = 0; i < exp.length(); i = i + 1 {
      temp_exp[i] *= expon
    }
    let new_expvec = copy_expvec * temp_exp
    res.add_term_inplace(new_expvec, new_coeff)
  }
  res
}

///|
/// Replaces a variable at the specified index with another polynomial
/// throughout the sparse polynomial.
///
/// Parameters:
///
/// * `self` : The sparse polynomial in which to perform the replacement.
/// * `index` : The index of the variable to replace (0-based indexing into the
///   exponent vector).
/// * `other` : The polynomial to substitute for the variable at the given
///   index.
///
/// Returns a new sparse polynomial with the variable replacement applied.
///
/// Panics if `index` is negative or greater than or equal to the length of any
/// exponent vector in the polynomial.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial: x + y
/// let poly = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([1, 0]), 1),  // x
///   (@luna-poly.ExpVec::from_array([0, 1]), 1)   // y
/// ])
///
/// // Create replacement polynomial: z + w
/// let replacement = @luna-poly.SparsePolynomial::from_array([
///   (@luna-poly.ExpVec::from_array([0, 0, 1]), 1),  // z
///   (@luna-poly.ExpVec::from_array([0, 0, 0, 1]), 1) // w
/// ])
///
/// // Replace variable at index 0 (x) with (z + w)
/// let result = poly.replace_poly(0, replacement)
/// // Result: (z + w) + y = z + w + y
/// ```
///
pub fn[A : Semiring + Eq] SparsePolynomial::replace_poly(
  self : SparsePolynomial[A],
  index : Int,
  other : SparsePolynomial[A]
) -> SparsePolynomial[A] {
  let res = SparsePolynomial::new()
  for expvec, coeff in self {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    if expvec[index] != 0 {
      let temp_sparse = other.pow(expvec[index])
      let copy_expvec = expvec.copy()
      copy_expvec[index] = 0
      for temp_expvec, temp_coeff in temp_sparse {
        res.add_term_inplace(copy_expvec * temp_expvec, coeff * temp_coeff)
      }
    }
  }
  res
}

///|
/// Raises the sparse polynomial to the given power using fast exponentiation.
///
/// Parameters:
///
/// * `self` : The sparse polynomial to be raised to a power.
/// * `expon` : The non-negative integer exponent.
///
/// Returns a new sparse polynomial that is the result of raising `self` to the
/// power of `expon`.
///
/// Example:
///
/// ```moonbit
/// let poly = SparsePolynomial::from_array([
///   (ExpVec::from_array([0, 0, 1]), 1),
///   (ExpVec::from_array([0, 1, 0]), 1),
/// ])
/// inspect(poly.pow(2), content="y² + z² + 2yz")
/// ```
///
pub fn[A : Semiring + Eq] SparsePolynomial::pow(
  self : SparsePolynomial[A],
  expon : UInt
) -> SparsePolynomial[A] {
  guard expon > 1 else { self }
  let temp = self.pow(expon / 2)
  if expon % 2 == 0 {
    temp * temp
  } else {
    temp * temp * self
  }
}

///|
/// Tests the power operation for sparse polynomials by raising a binomial to
/// the 10th power and verifying the expanded form.
///
/// This test creates a sparse polynomial representing `y + z` and raises it to
/// the 10th power using the `pow` method. The test verifies that the result
/// matches the expected binomial expansion `(y + z)^10`, which should produce
/// terms with coefficients following the binomial theorem. The expected result
/// contains 11 terms with coefficients corresponding to the binomial
/// coefficients C(10,k) for k from 0 to 10, arranged in descending order of the
/// `y` exponent.
///
/// The test demonstrates that:
///
/// * The `pow` method correctly handles polynomial exponentiation
/// * Binomial expansions are computed accurately
/// * The resulting polynomial string representation maintains proper variable
///   ordering and formatting
/// * All 11 expected terms are present with correct coefficients: 1, 10, 45,
///   120, 210, 252, 210, 120, 45, 10, 1
///
/// This validates the mathematical correctness of the polynomial power
/// operation implementation.
///
test "pow" {
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([0, 0, 1]), 1),
    (ExpVec::from_array([0, 1, 0]), 1),
  ])
  assert_eq(
    poly_2.pow(10).to_string(),
    "y¹⁰ + z¹⁰ + 10yz⁹ + 45y²z⁸ + 120y³z⁷ + 210y⁴z⁶ + 252y⁵z⁵ + 210y⁶z⁴ + 120y⁷z³ + 45y⁸z² + 10y⁹z",
  )
}

///|
/// Tests the polynomial substitution and replacement operations on a sparse
/// polynomial.
///
/// This test verifies the behavior of various replacement methods available for
/// `SparsePolynomial`:
///
/// * `replace_const`: Substitutes a variable with a constant value
/// * `replace_variable`: Replaces one variable with another variable
/// * `replace_term`: Substitutes a variable with a polynomial term
/// * `replace_poly`: Replaces a variable with another polynomial
///
/// The test creates a base polynomial `xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵` and applies
/// different replacement operations:
///
/// 1. **Constant replacement**: Replaces variable `z` (index 2) with constant
/// value `2`, resulting in `8xy² + 32x²y³ + 96x³y⁴`
/// 2. **Variable replacement**: Replaces variable `y` (index 1) with variable
/// `z` (index 2), resulting in `xz⁵ + 2x²z⁷ + 3x³z⁹`
/// 3. **Term replacement**: Replaces variable `z` (index 2) with term `x²y²z²`,
/// resulting in `x⁷y⁸z⁶ + 2x¹⁰y¹¹z⁸ + 3x¹³y¹⁴z¹⁰`
/// 4. **Polynomial replacement**: Replaces variable `x` (index 0) with
/// polynomial `z + y`, resulting in a more complex expanded form
///
/// Each operation is tested by comparing the string representation of the
/// resulting polynomial with the expected mathematical result.
///
test "const_replace" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  //poly = xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵
  println(poly.to_string())
  //replace_const (z = 2)
  assert_eq(
    poly.replace_const(2, 2).to_string(),
    "8xy² + 32x²y³ + 96x³y⁴",
  )
  //replace_variable (y = z)
  assert_eq(
    poly.replace_variable(1, 2).to_string(),
    "xz⁵ + 2x²z⁷ + 3x³z⁹",
  )
  //replace_term (z = x²y²z²)
  let expvec = ExpVec::from_array([2, 2, 2])
  assert_eq(
    poly.replace_term(2, expvec, 1).to_string(),
    "x⁷y⁸z⁶ + 2x¹⁰y¹¹z⁸ + 3x¹³y¹⁴z¹⁰",
  )
  //replace_poly (x = z + y)
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([0, 0, 1]), 1),
    (ExpVec::from_array([0, 1, 0]), 1),
  ])
  let temp_poly = poly.replace_poly(0, poly_2)
  assert_eq(
    temp_poly.to_string(),
    "y²z⁴ + y³z³ + 2y³z⁶ + 4y⁴z⁵ + 2y⁵z⁴ + 3y⁴z⁸ + 9y⁵z⁷ + 9y⁶z⁶ + 3y⁷z⁵",
  )
}

///|
/// Tests the multiplication operation for sparse polynomials by multiplying a
/// polynomial with itself and verifying the result.
///
/// This test creates a sparse polynomial with three terms: `xy²z³ + 2x²y³z⁴ +
/// 3x³y⁴z⁵`, then multiplies it by itself using the `*` operator. The expected
/// result of squaring this polynomial is `x²y⁴z⁶ + 4x³y⁵z⁷ + 10x⁴y⁶z⁸ +
/// 12x⁵y⁷z⁹ + 9x⁶y⁸z¹⁰`.
///
/// The test demonstrates:
///
/// * Creation of a `SparsePolynomial` from an array of exponent vector and
///   coefficient pairs
/// * Multiplication of sparse polynomials using the `*` operator
/// * String representation of the resulting polynomial
///
/// This verifies that the `Mul` trait implementation for `SparsePolynomial`
/// correctly handles polynomial multiplication by expanding all term
/// combinations and combining like terms.
///
test "mul" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  let poly_2 = poly * poly
  assert_eq(
    poly_2.to_string(),
    "x²y⁴z⁶ + 4x³y⁵z⁷ + 10x⁴y⁶z⁸ + 12x⁵y⁷z⁹ + 9x⁶y⁸z¹⁰",
  )
}

///|
/// Tests the polynomial evaluation functionality including full evaluation,
/// partial evaluation at specific variables, and multiple variable evaluation.
///
/// This comprehensive test verifies three different evaluation methods:
///
/// 1. **Full evaluation** (`eval`): Substitutes all variables with concrete
/// values and returns a scalar result
/// 2. **Partial evaluation** (`eval_at`): Substitutes a single variable at a
/// specific index with a value, returning a polynomial in the remaining
/// variables
/// 3. **Multiple partial evaluation** (`eval_at_many`): Substitutes multiple
/// variables simultaneously with their respective values
///
/// **Test Cases:**
///
/// **Case 1: Univariate polynomial** - Tests polynomial `x² + 2x + 1`:
///
/// * Full evaluation at `x = 2` yields `9`
/// * Partial evaluation at variable 0 with value 2 yields constant polynomial
///   `9`
/// * Multiple variable evaluation with `[(0, 2)]` yields constant polynomial
///   `9`
///
/// **Case 2: Bivariate polynomial** - Tests polynomial `x² + y²`:
///
/// * Partial evaluation at `x = 1` yields `1 + y²`
/// * Partial evaluation at `y = 2` yields `4 + x²`
/// * Multiple variable evaluation with `[(0, 1), (1, 2)]` yields constant
///   polynomial `5`
/// * Full evaluation at `[1, 2]` yields `5`
///
/// **Case 3: Bivariate polynomial with negative coefficient** - Tests
/// polynomial `x² - y²`:
///
/// * Partial evaluation at `x = 1` yields `1 + -1y²`
/// * Partial evaluation at `y = 2` yields `-4 + x²`
/// * Multiple variable evaluation with `[(0, 1), (1, 2)]` yields constant
///   polynomial `-3`
/// * Full evaluation at `[1, 2]` yields `-3`
///
/// **Case 4: Mixed degree bivariate polynomial** - Tests polynomial `xy² +
/// x²y`:
///
/// * Partial evaluation at `x = 1` yields `y + y²`
/// * Partial evaluation at `y = 1` yields `x + x²`
/// * Multiple variable evaluation with `[(0, 2), (1, 3)]` yields constant
///   polynomial `30`
/// * Full evaluation at `[2, 3]` yields `30`
///
/// Each test case validates that the different evaluation methods produce
/// mathematically consistent results, ensuring the polynomial evaluation system
/// works correctly across various polynomial structures and variable
/// substitution scenarios.
///
test "eval" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([1]), 2),
    (ExpVec::from_array([]), 1),
  ])
  assert_eq(poly.eval([2]), 9)
  inspect(poly.eval_at(0, 2), content="9")
  inspect(poly.eval_at_many([(0, 2)]), content="9")
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([0, 2]), 1),
  ])
  inspect(poly_2.eval_at(0, 1), content="1 + y²")
  inspect(poly_2.eval_at(1, 2), content="4 + x²")
  inspect(poly_2.eval_at_many([(0, 1), (1, 2)]), content="5")
  assert_eq(poly_2.eval([1, 2]), 5)
  let poly_3 = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([0, 2]), -1),
  ])
  inspect(poly_3.eval_at(0, 1), content="1 + -1y²")
  inspect(poly_3.eval_at(1, 2), content="-4 + x²")
  inspect(poly_3.eval_at_many([(0, 1), (1, 2)]), content="-3")
  assert_eq(poly_3.eval([1, 2]), -3)
  let poly_4 = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2]), 1),
    (ExpVec::from_array([2, 1]), 1),
  ])
  inspect(poly_4.eval_at(0, 1), content="y + y²")
  inspect(poly_4.eval_at(1, 1), content="x + x²")
  inspect(poly_4.eval_at_many([(0, 2), (1, 3)]), content="30")
  assert_eq(poly_4.eval([2, 3]), 30)
}
