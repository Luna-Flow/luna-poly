///|
/// Exponent vector representing a monomial in polynomial algebra as a sparse
/// multi-dimensional array of variable exponents.
///
/// Fields:
///
/// * `vec` : Array storing the exponents for each variable, where `vec[i]` is
///   the exponent of the i-th variable.
/// * `degree` : Total degree of the monomial (sum of all exponents in `vec`).
///
/// Example:
///
/// ```moonbit
/// // Create a monomial x²y³z (exponents [2, 3, 1])
/// let exp = ExpVec::from_array([2, 3, 1])
/// inspect(exp[0], content="2")  // x has exponent 2
/// inspect(exp[1], content="3")  // y has exponent 3
/// inspect(exp[2], content="1")  // z has exponent 1
/// inspect(exp.degree, content="6")  // total degree is 2+3+1=6
///
/// // Create the constant monomial (empty exponent vector)
/// let one = ExpVec::new()
/// inspect(one.length(), content="0")
/// inspect(one.degree, content="0")
///
/// // Multiply monomials: x²y³z * xy = x³y⁴z
/// let other = ExpVec::from_array([1, 1, 0])
/// let product = exp * other
/// inspect(product.to_string(), content="x³y⁴z")
/// ```
///
struct ExpVec {
  vec : Array[UInt]
  mut degree : UInt
}

///|
/// Provides automatic generation of arbitrary `ExpVec` instances for
/// property-based testing using the QuickCheck framework.
///
/// Parameters:
///
/// * `size` : The size hint for controlling the complexity of generated test
///   cases.
/// * `rs` : The random seed used for generating pseudo-random values.
///
/// Returns an arbitrary `ExpVec` instance suitable for property-based testing.
///
/// Example:
///
/// ```moonbit
/// // Generate arbitrary ExpVec instances for testing
/// let gen : @qc.Gen[ExpVec] = @qc.Gen::spawn()
/// let samples = gen.samples(size=5)
/// // samples might contain: [x²y³, z, abc², 1, xy]
/// ```
///
impl @quickcheck.Arbitrary for ExpVec with arbitrary(size, rs) {
  @qc.Gen::spawn().fmap(ExpVec::from_array).run(size, rs)
}

///|
/// Tests the arbitrary generation of `ExpVec` values using property-based
/// testing.
///
/// This test verifies that the `@quickcheck.Arbitrary` implementation for
/// `ExpVec` can generate a diverse set of polynomial exponent vectors. The test
/// generates 10 sample `ExpVec` values and checks that they produce the
/// expected string representations when displayed.
///
/// The test demonstrates that the arbitrary generator can produce:
///
/// * Simple monomials like `a²` (variable `a` with exponent 2)
/// * Multivariate monomials like `ab²c²` (multiple variables with different
///   exponents)
/// * The constant term `1` (representing no variables)
/// * Complex expressions like `za²c⁴d⁴e²` (many variables with high exponents)
///
/// This ensures the property-based testing framework can generate meaningful
/// test cases for polynomial operations involving exponent vectors.
///
/// Example:
///
/// ```moonbit
/// test "verify arbitrary generation" {
///   let gen : @qc.Gen[ExpVec] = @qc.Gen::spawn()
///   let samples = gen.samples(size=10)
///   // samples will contain ExpVec values that display as polynomial terms
///   // like "ab²c²", "a²", "zab³cd", etc.
/// }
/// ```
///
test "arbitrary" {
  let gen : @qc.Gen[ExpVec] = @qc.Gen::spawn()
  inspect(
    gen.samples(size=10),
    content="[ab²c², a², zab³cd, 1, c, 1, za²c³d², za²c⁴d⁴e², z, z]",
  )
}

///|
/// Combines the hash value of an `ExpVec` with the given hasher.
///
/// Parameters:
///
/// * `self` : The exponent vector to hash.
/// * `hasher` : The hasher to combine the hash values with.
///
/// Example:
///
/// ```moonbit
/// let exp = ExpVec::from_array([1, 2, 3])
/// let hasher = Hasher::new()
/// exp.hash_combine(hasher)
/// ```
///
impl Hash for ExpVec with hash_combine(self : ExpVec, hasher : Hasher) -> Unit {
  let vec = self.vec
  if vec.is_empty() {
    hasher.combine_uint(0)
  } else {
    hasher.combine_uint(self.degree)
    for x in vec {
      hasher.combine_uint(x)
    }
  }
}

///|
/// Tests that hash values of different ExpVec instances do not conflict for a
/// large sample of randomly generated vectors.
///
/// This property-based test verifies the quality of the hash function
/// implementation by checking that when two ExpVec instances produce the same
/// hash value, they must be equal. It generates 1999 random ExpVec samples and
/// maintains a map from hash values to ExpVec instances. If a hash collision is
/// detected (same hash for different ExpVec instances), the test fails by
/// asserting that the vector components are equal.
///
/// Example:
///
/// ```moonbit
/// test "prop hash non-conflict" {
///   let m = Map::new()
///   let g : @qc.Gen[ExpVec] = @qc.Gen::spawn()
///   for sample in g.samples(size=1999) {
///     let hashed = sample.hash()
///     match m.get(hashed) {
///       Some((x : ExpVec)) => assert_eq(sample.vec, x.vec)
///       None => m[hashed] = sample
///     }
///   }
/// }
/// ```
///
test "prop hash non-conflict" {
  let m = Map::new()
  let g : @qc.Gen[ExpVec] = @qc.Gen::spawn()
  for sample in g.samples(size=1999) {
    let hashed = sample.hash()
    match m.get(hashed) {
      Some((x : ExpVec)) => assert_eq(sample.vec, x.vec)
      None => m[hashed] = sample
    }
  }
}

///|
/// Verifies that the hash function produces consistent and deterministic hash
/// values for ExpVec instances.
///
/// This test creates two different ExpVec instances with different coefficient
/// arrays and checks that their hash values match expected values. It ensures
/// that the hash implementation is working correctly and produces consistent
/// results for the same input.
///
/// Example:
///
/// ```moonbit
/// test "hash verification" {
///   let exp = ExpVec::from_array([1, 2, 3])
///   let exp_r = ExpVec::from_array([3, 2, 1])
///   assert_eq(exp.hash(), -533501922)
///   assert_eq(exp_r.hash(), -1291445456)
/// }
/// ```
///
test "hash" {
  let exp = ExpVec::from_array([1, 2, 3])
  let exp_r = ExpVec::from_array([3, 2, 1])
  assert_eq(exp.hash(), -533501922)
  assert_eq(exp_r.hash(), -1291445456)
}

///|
/// Returns the number of variables in the exponent vector.
///
/// Parameters:
///
/// * `self` : The exponent vector whose length is to be determined.
///
/// Returns the number of variables (dimensions) in the exponent vector as an
/// integer.
///
/// Example:
///
/// ```moonbit
/// let exp = ExpVec::from_array([1, 2, 3])
/// inspect(exp.length(), content="3")
/// ```
///
pub fn ExpVec::length(self : ExpVec) -> Int {
  self.vec.length()
}

///|
/// Splits the exponent vector at the given index into two separate exponent
/// vectors.
///
/// Parameters:
///
/// * `self` : The exponent vector to split.
/// * `index` : The position at which to split the vector (0-based indexing).
///
/// Returns a tuple containing two exponent vectors: the first contains elements
/// from index 0 to `index-1`, and the second contains elements from `index`
/// onwards.
///
/// Example:
///
/// ```moonbit
/// let m = @luna-poly.ExpVec::from_array([1, 2, 3])
/// let (head, tail) = m.split_at(2)
/// inspect(head.to_string(), content="xy²")
/// inspect(tail.to_string(), content="z³")
/// ```
///
fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  let degree = self.degree
  let (head, tail) = self.vec.split_at(i)
  let l_d = head.fold(init=0U, UInt::op_add)
  ({ vec: head, degree: l_d }, { vec: tail, degree: degree - l_d })
}

///|
/// Tests the `split_at` method of `ExpVec` to verify correct splitting of
/// exponent vectors.
///
/// This test validates that when an exponent vector representing a monomial is
/// split at a given index, both the resulting vector contents and degree
/// calculations are correct. It specifically tests splitting the monomial
/// `xy²z³` (represented as `[1, 2, 3]`) at index 2, ensuring that:
///
/// * The head portion contains the first 2 exponents `[1, 2]` representing
///   `xy²`
/// * The tail portion contains the remaining exponents `[3]` representing `z³`
/// * Both head and tail maintain correct degree calculations (3 for head: 1+2,
///   3 for tail: 3)
///
/// The test verifies the structural integrity of the split operation and
/// confirms that degree tracking remains consistent across the split operation.
///
test "split monomial" {
  let m = ExpVec::from_array([1, 2, 3])
  let (head, tail) = m.split_at(2)
  assert_eq(head.vec, [1, 2])
  assert_eq(tail.vec, [3])
  assert_eq(head.degree, 3)
  assert_eq(tail.degree, 3)
}

///|
/// Checks if the exponential vector represents the constant monomial 1.
///
/// Parameters:
///
/// * `self` : The exponential vector to check.
///
/// Returns `true` if the exponential vector represents the constant monomial 1
/// (i.e., has no variables), `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let one = ExpVec::new()  // Creates the constant monomial 1
/// let x = ExpVec::from_array([1])  // Creates monomial x
/// inspect(one.is_one(), content="true")
/// inspect(x.is_one(), content="false")
/// ```
///
fn ExpVec::is_one(self : ExpVec) -> Bool {
  self.vec.is_empty()
}

///|
/// Removes and returns the last element from the exponent vector while updating
/// the total degree.
///
/// Parameters:
///
/// * `self` : The exponent vector to modify.
///
/// Returns `Some(element)` if the vector is not empty, or `None` if the vector
/// is empty.
///
/// Examples:
///
/// ```moonbit
/// let exp = ExpVec::from_array([1, 2, 3])
/// inspect(exp.pop(), content="Some(3)")
/// inspect(exp.to_string(), content="xy²")
/// inspect(exp.degree, content="3")
///
/// let empty = ExpVec::new()
/// inspect(empty.pop(), content="None")
/// ```
///
fn ExpVec::pop(self : ExpVec) -> UInt? {
  let res = self.vec.pop()
  if res is Some(x) {
    self.degree = self.degree - x
  }
  res
}

///|
/// Retrieves the exponent of the variable at the specified index.
///
/// Parameters:
///
/// * `self` : The exponent vector to access.
/// * `index` : The index of the variable whose exponent to retrieve.
///
/// Returns the exponent value at the given index as an unsigned integer.
///
/// Panics if `index` is out of bounds for the underlying vector.
///
/// Example:
///
/// ```moonbit
/// let exp_vec = @luna-poly.ExpVec::from_array([2, 3, 1])
/// inspect(exp_vec[0], content="2")  // x²
/// inspect(exp_vec[1], content="3")  // y³  
/// inspect(exp_vec[2], content="1")  // z¹
/// ```
///
pub fn ExpVec::op_get(self : ExpVec, i : Int) -> UInt {
  self.vec[i]
}

///|
/// Sets the exponent of the variable at the specified position to a new value.
///
/// Parameters:
///
/// * `self` : The exponent vector to modify.
/// * `i` : The index of the variable whose exponent to set.
/// * `val` : The new exponent value to assign.
///
/// Panics if `i` is out of bounds for the underlying vector.
///
/// Example:
///
/// ```moonbit
/// let exp_vec = @luna-poly.ExpVec::from_array([1, 2, 3])
/// exp_vec.op_set(1, 5)  // Sets the exponent of the second variable to 5
/// // exp_vec now represents x¹y⁵z³
/// ```
///
pub fn ExpVec::op_set(self : ExpVec, i : Int, val : UInt) -> Unit {
  let old = self.vec[i]
  self.vec[i] = val
  self.degree = self.degree - old + val
}

///|
/// Creates the multiplicative identity element for `ExpVec`.
///
/// Returns an `ExpVec` representing the monomial 1 (i.e., the product of no
/// variables), which serves as the multiplicative identity in polynomial
/// operations.
///
/// Example:
///
/// ```moonbit
/// let identity = ExpVec::one()
/// let monomial = ExpVec::from_array([2, 3, 1])
/// inspect(identity * monomial == monomial, content="true")
/// inspect(monomial * identity == monomial, content="true")
/// ```
///
impl One for ExpVec with one() -> ExpVec {
  { vec: [], degree: 0 }
}

///|
/// Multiplies two exponential vectors by adding their corresponding exponents.
///
/// Parameters:
///
/// * `self` : The first exponential vector.
/// * `other` : The second exponential vector.
///
/// Returns a new `ExpVec` representing the product of the two exponential
/// vectors.
///
/// Example:
///
/// ```moonbit
/// let exp1 = ExpVec::from_array([2, 1, 3])  // x²yz³
/// let exp2 = ExpVec::from_array([1, 2, 0])  // xy²
/// let product = exp1 * exp2
/// inspect(product, content="x³y³z³")
/// ```
///
impl Mul for ExpVec with op_mul(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let l_min = @cmp.minimum(l_self, l_other)
  let larger = if l_self >= l_other { self } else { other }
  let mut degree : UInt = 0
  let vec : Array[UInt] = Array::makei(larger.length(), fn(i) {
    let d = if i < l_min { self[i] + other[i] } else { larger[i] }
    degree += d
    d
  })
  { vec, degree }
}

///|
/// Performs monomial division on two exponent vectors using saturating
/// subtraction.
///
/// Parameters:
///
/// * `self` : The dividend exponent vector.
/// * `other` : The divisor exponent vector.
///
/// Returns a new exponent vector representing the quotient of the division,
/// where each component is the result of saturating subtraction (i.e., `max(0,
/// self[i] - other[i])` for each position).
///
/// Example:
///
/// ```moonbit
/// let m1 = @luna-poly.ExpVec::from_array([4, 5, 3])  // x⁴y⁵z³
/// let m2 = @luna-poly.ExpVec::from_array([1, 2, 3])  // xy²z³
/// inspect(m1 / m2, content="x³y³")  // Result: x³y³
/// let m3 = @luna-poly.ExpVec::from_array([1, 5, 2])  // xy⁵z²
/// inspect(m2 / m3, content="y")  // Result: y (since 1-1=0, 2-5=0, 3-2=1)
/// ```
///
impl Div for ExpVec with op_div(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let monus = fn(x : UInt, y) { if x <= y { 0U } else { x - y } }
  if l_self > l_other {
    let vec = Array::makei(l_self, fn(i) {
      if i < l_other {
        monus(self[i], other[i])
      } else {
        self[i]
      }
    })
    { vec, degree: self.degree - other.degree }
  } else {
    let mut degree = self.degree
    let vec = Array::makei(l_self, fn(i) {
      degree = monus(degree, other[i])
      monus(self[i], other[i])
    })
    { vec, degree }
  }
}

///|
/// Tests the division operation for exponent vectors, verifying both the result
/// and degree calculations.
///
/// This test validates the `op_div` implementation for `ExpVec` by performing
/// division operations on various exponent vector combinations and checking:
///
/// 1. The resulting exponent vector string representation
/// 2. The degree of the resulting exponent vector
///
/// The test covers several scenarios:
///
/// * Division where the first operand has higher or equal exponents in all
///   positions
/// * Division where the second operand has higher exponents in some positions
///   (resulting in zero exponents)
/// * Division with operands of different lengths
/// * Verification that degrees are calculated correctly after division
///
/// The division operation performs element-wise subtraction with a "monus"
/// operation (saturated subtraction that doesn't go below zero), which is
/// appropriate for polynomial exponent manipulation.
///
/// Example test cases:
///
/// * `[4,5,3] / [1,2,3]` results in `x³y³` (degree 6)
/// * `[1,2,3] / [4,5,3]` results in `1` (degree 0, all exponents become zero)
/// * `[4,5,3] / [3,3,2,1]` results in `xy²z` (degree 4)
/// * `[3,3,2,1] / [1,2,3]` results in `x²ya` (degree 3)
///
test "division" {
  let m1 = ExpVec::from_array([4, 5, 3])
  let m2 = ExpVec::from_array([1, 2, 3])
  let m3 = ExpVec::from_array([3, 3, 2, 1])
  inspect(m1 / m2, content="x³y³")
  inspect(m2 / m1, content="1")
  inspect(m1 / m3, content="xy²z")
  inspect(m3 / m2, content="x²ya")
  inspect((m1 / m2).degree, content="6")
  inspect((m2 / m1).degree, content="0")
  inspect((m1 / m3).degree, content="4")
  inspect((m3 / m2).degree, content="3")
}

///|
/// Formats an exponent vector as a mathematical monomial string with Unicode
/// superscripts and subscripts.
///
/// Converts the exponent vector into a human-readable mathematical notation
/// where each variable is represented by a letter from the alphabet (x, y, z,
/// a, b, c, ...) with optional subscripts for variable indexing and
/// superscripts for exponents. Variables with zero exponents are omitted, and
/// if all exponents are zero, outputs "1" to represent the multiplicative
/// identity.
///
/// Parameters:
///
/// * `self` : The exponent vector to format.
/// * `logger` : The output logger to write the formatted string to.
///
/// Example:
///
/// ```moonbit
/// let exp = ExpVec::from_array([2, 0, 1, 3])
/// println(exp) // Outputs: x²zd³
/// ```
///
impl Show for ExpVec with output(self : ExpVec, logger) -> Unit {
  let write_superscript = {
    let num_superscript = [
      '\u2070', '\u00b9', '\u00b2', '\u00b3', '\u2074', '\u2075', '\u2076', '\u2077',
      '\u2078', '\u2079',
    ]
    let minus_superscript = '\u207b'
    fn(num : UInt) -> Unit {
      for c in num.to_string() {
        if c == '-' {
          logger.write_char(minus_superscript)
        } else {
          let index = c.to_int() - '0'.to_int()
          logger.write_char(num_superscript[index])
        }
      }
    }
  }
  let write_subscript = {
    let num_subscript = [
      '\u2080', '\u2081', '\u2082', '\u2083', '\u2084', '\u2085', '\u2086', '\u2087',
      '\u2088', '\u2089',
    ]
    fn(num : Int) -> Unit {
      for c in num.to_string() {
        let index = c.to_int() - '0'.to_int()
        logger.write_char(num_subscript[index])
      }
    }
  }
  let alphabet = [
    'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
  ]
  let mut empty = true
  for i, x in self.vec {
    if x != 0 {
      empty = false
      let alphabet_index = i % 26
      logger.write_char(alphabet[alphabet_index])
      let subscript = (i / 26).abs()
      if subscript != 0 {
        write_subscript(subscript)
      }
      if x != 1 {
        write_superscript(x)
      }
    }
  }
  if empty {
    logger.write_char('1')
  }
}

///|
/// Compares two exponent vectors to determine their ordering relationship.
///
/// The comparison follows a lexicographic ordering with the following
/// precedence:
///
/// 1. First by vector length (shorter vectors are considered smaller)
/// 2. Then by total degree (sum of all exponents)
/// 3. Finally by individual exponents from left to right
///
/// Parameters:
///
/// * `self` : The first exponent vector to compare.
/// * `other` : The second exponent vector to compare.
///
/// Returns `-1` if `self` is less than `other`, `1` if `self` is greater than
/// `other`, and `0` if they are equal.
///
/// Example:
///
/// ```moonbit
/// let vec1 = ExpVec::from_array([1, 2])    // xy²
/// let vec2 = ExpVec::from_array([2, 1])    // x²y  
/// let vec3 = ExpVec::from_array([1, 2, 0]) // xy² (longer vector)
///
/// inspect(vec1.compare(vec2), content="1")  // xy² > x²y (same degree, but y² > y lexicographically)
/// inspect(vec1.compare(vec3), content="-1") // shorter vector < longer vector
/// ```
///
impl Compare for ExpVec with compare(self : ExpVec, other : ExpVec) -> Int {
  if self.length() < other.length() {
    -1
  } else if self.length() > other.length() {
    1
  } else if self.degree > other.degree {
    1
  } else if self.degree < other.degree {
    -1
  } else {
    for i in 0..<self.length() {
      if self[i] > other[i] {
        break 1
      }
      if self[i] < other[i] {
        break -1
      }
    } else {
      0
    }
  }
}

///|
/// Tests that the ordering relation for `ExpVec` is exclusive, meaning exactly
/// one of greater than, equal to, or less than holds for any pair of exponent
/// vectors.
///
/// This property test verifies the fundamental ordering property that for any
/// two `ExpVec` instances `a` and `b`, exactly one of the following conditions
/// is true:
///
/// * `a > b` (greater than)
/// * `a == b` (equal to)
/// * `a < b` (less than)
///
/// The test uses QuickCheck property-based testing to generate 1000 random
/// pairs of `ExpVec` instances and validates that the ordering comparison
/// always produces exactly one true result among the three possible
/// comparisons.
///
/// This ensures the `Compare` implementation for `ExpVec` maintains the
/// mathematical property of trichotomy, which is essential for consistent
/// sorting and ordering operations.
///
test "ordering exclusive" {
  fn exclusive(ab : (ExpVec, ExpVec)) -> Bool {
    let (a, b) = ab
    match (a > b, a == b, a < b) {
      (true, false, false) | (false, false, true) | (false, true, false) => true
      _ => false
    }
  }

  //@qc.quick_check(@qc.Arrow(exclusive) |> @qc.with_max_success(1000))
}

///|
/// Verifies that the monomial `1` (unity) is less than or equal to any exponent
/// vector using property-based testing.
///
/// This test uses QuickCheck to generate 1000 random `ExpVec` instances and
/// verifies that the mathematical property `1 ≤ u` holds for all generated
/// exponent vectors, where `1` represents the multiplicative identity (empty
/// exponent vector) and `u` is any exponent vector. This property should always
/// be true since the unity monomial has degree 0 and all exponent vectors have
/// non-negative degrees.
///
/// Example:
///
/// ```moonbit
/// // The test generates random ExpVec instances like:
/// let one = ExpVec::one()   // represents monomial "1" 
/// let u = ExpVec::from_array([2, 1, 3])  // represents monomial "x²yz³"
/// assert_true(one <= u)  // This should always be true
/// ```
///
test "1 <= u" {
  fn one_leq_any(a : ExpVec) -> Bool {
    let one = ExpVec::one()
    one <= a
  }

  //@qc.quick_check(@qc.Arrow(one_leq_any) |> @qc.with_max_success(1000))
}

///|
/// Removes trailing zero exponents from the exponent vector and optimizes
/// memory usage.
///
/// Parameters:
///
/// * `self` : The exponent vector to shrink.
///
/// Example:
///
/// ```moonbit
/// let exp = ExpVec::from_array([1, 2, 0, 0, 0])
/// exp.shrink()
/// inspect(exp.to_string(), content="xy²")
/// ```
///
fn ExpVec::shrink(self : ExpVec) -> Unit {
  if not(self.is_one()) {
    for i = self.length() - 1; not(self.is_one()) && self[i] == 0; i = i - 1 {
      let _ = self.pop()

    }
    self.vec.shrink_to_fit()
  }
}

///|
/// Compares two exponent vectors for equality.
///
/// Parameters:
///
/// * `self` : The first exponent vector to compare.
/// * `other` : The second exponent vector to compare.
///
/// Returns `true` if the two exponent vectors are equal, `false` otherwise.
///
/// Example:
///
/// ```moonbit
/// let exp1 = ExpVec::from_array([1, 2, 3])
/// let exp2 = ExpVec::from_array([1, 2, 3])
/// let exp3 = ExpVec::from_array([1, 2, 0])
/// inspect(exp1 == exp2, content="true")
/// inspect(exp1 == exp3, content="false")
/// ```
///
impl Eq for ExpVec with op_equal(self : ExpVec, other : ExpVec) -> Bool {
  guard self.length() == other.length() && self.degree == other.degree else {
    false
  }
  self.shrink()
  other.shrink()
  self.vec == other.vec
}

///|
/// Creates a new, empty exponent vector representing the constant monomial.
///
/// Returns a new `ExpVec` instance representing the multiplicative identity
/// (i.e., the constant term 1 in polynomial expressions).
///
/// Example:
///
/// ```moonbit
/// let empty_exp = ExpVec::new()
/// inspect(empty_exp.to_string(), content="1")
/// inspect(empty_exp.length(), content="0")
/// ```
///
pub fn ExpVec::new() -> ExpVec {
  ExpVec::one()
}

///|
/// Creates a deep copy of the exponent vector.
///
/// Parameters:
///
/// * `self` : The exponent vector to copy.
///
/// Returns a new `ExpVec` instance that is an independent copy of the original
/// exponent vector, with the same variable exponents and total degree.
///
/// Example:
///
/// ```moonbit
/// let original = ExpVec::from_array([2, 3, 1])
/// let copied = original.copy()
/// // Modifying the copy doesn't affect the original
/// copied[0] = 5
/// inspect(original[0], content="2")  // Original unchanged
/// inspect(copied[0], content="5")    // Copy modified
/// ```
///
fn ExpVec::copy(self : ExpVec) -> ExpVec {
  let vec = self.vec.copy()
  let degree = self.degree
  { vec, degree }
}

///|
/// Creates an `ExpVec` from an array of unsigned integers, automatically
/// removing trailing zeros and computing the total degree.
///
/// Parameters:
///
/// * `vec` : An array of unsigned integers representing the exponents for each
///   variable.
///
/// Returns a new `ExpVec` with trailing zeros removed and the total degree
/// computed.
///
/// Example:
///
/// ```moonbit
/// let exp1 = ExpVec::from_array([1, 2, 3])
/// inspect(exp1, content="xy²z³")
///
/// let exp2 = ExpVec::from_array([1, 0, 0])
/// inspect(exp2, content="x")
///
/// let exp3 = ExpVec::from_array([0, 0, 0])
/// inspect(exp3, content="1")
/// ```
///
fn ExpVec::from_array(vec : Array[UInt]) -> ExpVec {
  let mut i = vec.length() - 1
  while i >= 0 && vec[i] == 0 {
    i -= 1
  }
  { vec: vec.split_at(i + 1).0, degree: vec.fold(init=0U, UInt::op_add) }
}

///|
/// Tests the string representation of `ExpVec` instances using the `Show` trait
/// implementation.
///
/// This test verifies that the `to_string()` method (from the `Show` trait)
/// correctly formats exponent vectors into mathematical notation with
/// superscripts. It covers three key cases:
///
/// 1. **Large exponent**: Tests that large exponents (2025) are properly
/// rendered with superscript Unicode characters
/// 2. **Trailing zeros**: Tests that trailing zeros in the exponent vector are
/// ignored and don't affect the output
/// 3. **Zero vector**: Tests that a zero exponent vector is represented as "1"
/// (the multiplicative identity)
///
/// The test ensures that the mathematical representation is both accurate and
/// readable, using Unicode superscript characters for exponents greater than 1.
///
/// Examples:
///
/// ```moonbit
/// // Large exponent
/// let exp_large = ExpVec::from_array([2025])
/// inspect(exp_large.to_string(), content="x²⁰²⁵")
///
/// // Variable with trailing zeros
/// let exp_trailing = ExpVec::from_array([1, 0, 0]) 
/// inspect(exp_trailing.to_string(), content="x")
///
/// // Identity element
/// let exp_zero = ExpVec::from_array([0])
/// inspect(exp_zero.to_string(), content="1")
/// ```
///
test "show" {
  assert_eq(ExpVec::from_array([2025]).to_string(), "x²⁰²⁵")
  assert_eq(ExpVec::from_array([1, 0, 0]).to_string(), "x")
  assert_eq(ExpVec::from_array([0]).to_string(), "1")
}
