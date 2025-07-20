///|
/// Dense representation of univariate polynomials over a coefficient type `V`.
///
/// The polynomial is stored as an array of coefficients, where the index
/// corresponds to the power of the variable. For example, the polynomial `3 +
/// 2x + x²` would be stored as `[3, 2, 1]`.
///
/// Example:
///
/// ```moonbit
/// // Create a polynomial 1 + 2x + 3x²
/// let p1 = @luna-poly.to_poly([1, 2, 3])
///
/// // Create a polynomial using monomials
/// let p2 = @luna-poly.monomial(2, 5) // 5x²
///
/// // Create the variable x
/// let x = @luna-poly.vari()
///
/// // Polynomial arithmetic
/// let sum = p1 + p2
/// let product = p1 * p2
///
/// // Evaluation
/// let result = p1.eval(2) // Evaluate at x = 2
///
/// // Get leading coefficient
/// let leading = p1.leading_coefficient()
/// ```
///
struct Polynomial[V] {
  terms : Array[V]
} derive(Eq, Compare)

///|
/// Converts a polynomial to its string representation in mathematical notation.
///
/// Parameters:
///
/// * `self` : The polynomial to be displayed.
/// * `logger` : The output buffer to write the string representation to.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3])
/// println(p) // Output: "1 + 2x^1 + 3x^2"
///
/// let zero_poly : @luna-poly.Polynomial[Int] = @luna-poly.Polynomial::zero()
/// println(zero_poly) // Output: "0"
/// ```
///
impl[A : Show + Eq + Semiring] Show for Polynomial[A] with output(self, logger) {
  guard not(is_zero(self)) else { logger.write_object(A::zero()) }
  let mut first = true
  for i, term in self.terms {
    if not(is_zero(term)) {
      if not(first) {
        logger.write_string(" + ")
      }
      first = false
      logger.write_object(term)
      if i > 0 {
        logger..write_string("x^").write_object(i)
      }
    }
  }
}

///|
/// Removes elements from the end of an array while a predicate is satisfied.
///
/// Parameters:
///
/// * `pred` : A predicate function that takes an element and returns `true` if
///   the element should be removed.
/// * `xs` : The input array to process.
///
/// Returns a new array with trailing elements removed while the predicate
/// returns `true`.
///
/// Example:
///
/// ```moonbit
/// let arr = [1, 2, 3, 0, 0, 0]
/// let result = drop_while_end(fn(x) { x == 0 }, arr)
/// inspect(result, content="[1, 2, 3]")
/// ```
///
fn[A] drop_while_end(pred : (A) -> Bool, xs : Array[A]) -> Array[A] {
  let mut i = xs.length() - 1
  while i >= 0 && pred(xs[i]) {
    i -= 1
  }
  xs.split_at(i + 1).0
}

///|
/// Returns the highest degree term of the polynomial along with its degree.
///
/// Parameters:
///
/// * `self` : The polynomial to examine.
///
/// Returns `Some((degree, coefficient))` where `degree` is the highest power
/// and `coefficient` is the corresponding coefficient, or `None` if the
/// polynomial has no terms.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3])  // 1 + 2x + 3x²
/// inspect(p.leading_term(), content="Some((2, 3))")
///
/// let empty : @luna-poly.Polynomial[Int] = @luna-poly.Polynomial::zero()
/// inspect(empty.leading_term(), content="None")
/// ```
///
pub fn[A] leading_term(self : Polynomial[A]) -> (Int, A)? {
  if self.terms.is_empty() {
    None
  } else {
    Some((self.terms.length() - 1, self.terms.last().unwrap()))
  }
}

///|
/// Returns the leading coefficient of the polynomial.
///
/// Parameters:
///
/// * `self` : The polynomial to get the leading coefficient from.
///
/// Returns the leading coefficient wrapped in `Some`, or `None` if the
/// polynomial is empty.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3])
/// inspect(p.leading_coefficient(), content="Some(3)")
///
/// let empty : @luna-poly.Polynomial[Int] = @luna-poly.Polynomial::zero()
/// inspect(empty.leading_coefficient(), content="None")
/// ```
///
pub fn[A] leading_coefficient(self : Polynomial[A]) -> A? {
  self.leading_term().map(x => x.1)
}

///|
/// Converts an array of coefficients into a polynomial, removing trailing zero
/// coefficients.
///
/// Parameters:
///
/// * `arr` : An array of coefficients where the element at index `i` represents
///   the coefficient of the term `x^i`.
///
/// Returns a `Polynomial[A]` representing the polynomial with the given
/// coefficients, with trailing zero terms removed for efficiency.
///
/// Example:
///
/// ```moonbit
/// let coeffs = [1, 2, 3, 0, 0]
/// let poly = @luna-poly.to_poly(coeffs)
/// // Creates polynomial: 1 + 2x^1 + 3x^2
/// inspect(poly, content="1 + 2x^1 + 3x^2")
/// ```
///
pub fn[A : Eq + Semiring] to_poly(arr : Array[A]) -> Polynomial[A] {
  { terms: drop_while_end(is_zero, arr) }
}

///|
/// Implements the zero element for polynomials, creating an empty polynomial
/// with no terms.
///
/// Returns a polynomial representing the zero polynomial, which has no terms
/// and evaluates to zero for any input.
///
/// Example:
///
/// ```moonbit
/// let zero_poly : Polynomial[Int] = Polynomial::zero()
/// inspect(zero_poly, content="0")
/// ```
///
impl[A : Eq + Semiring] Zero for Polynomial[A] with zero() {
  { terms: [] }
}

///|
/// Implements the multiplicative identity element for polynomial types.
///
/// Returns a polynomial representing the constant polynomial 1, which serves as
/// the multiplicative identity in polynomial arithmetic. If the underlying
/// semiring's multiplicative identity is zero, returns the zero polynomial
/// (empty terms array), otherwise returns a polynomial with a single term
/// containing the semiring's multiplicative identity.
///
/// Returns a `Polynomial[A]` representing the multiplicative identity element.
///
/// Example:
///
/// ```moonbit
/// let one_poly : Polynomial[Int] = Polynomial::one()
/// inspect(one_poly, content="1")
///
/// let x = vari()
/// let result = one_poly * (x + coe(5))
/// inspect(result, content="5 + 1x^1")
/// ```
///
impl[A : Eq + Semiring] One for Polynomial[A] with one() {
  if is_zero(A::one()) {
    { terms: [] }
  } else {
    { terms: [A::one()] }
  }
}

///|
/// Multiplies two polynomials using the standard convolution algorithm.
///
/// Parameters:
///
/// * `xs` : The first polynomial to multiply.
/// * `ys` : The second polynomial to multiply.
///
/// Returns a new polynomial that is the product of `xs` and `ys`.
///
/// Example:
///
/// ```moonbit
/// let p1 = @luna-poly.to_poly([1, 2, 3])  // 1 + 2x + 3x²
/// let p2 = @luna-poly.to_poly([4, 5])     // 4 + 5x
/// let product = p1 * p2
/// inspect(product, content="4 + 13x^1 + 22x^2 + 15x^3")
/// ```
///
impl[A : Eq + Semiring] Mul for Polynomial[A] with op_mul(xs, ys) {
  let lx = xs.terms.length()
  let ly = ys.terms.length()
  let poly = Array::make(lx + ly - 1, A::zero())
  for i in 0..<lx {
    for j in 0..<ly {
      poly[i + j] = poly[i + j] + xs.terms[i] * ys.terms[j]
    }
  }
  { terms: poly }
}

///|
/// Implements polynomial addition by adding two polynomials term-wise.
///
/// Parameters:
///
/// * `xs` : The first polynomial to be added.
/// * `ys` : The second polynomial to be added.
///
/// Returns a new polynomial that is the sum of the two input polynomials.
///
/// Example:
///
/// ```moonbit
/// let p1 = @luna-poly.to_poly([1, 2, 3])     // 1 + 2x + 3x²
/// let p2 = @luna-poly.to_poly([4, 5])        // 4 + 5x
/// let sum = p1 + p2                          // 5 + 7x + 3x²
/// ```
///
impl[A : Eq + Semiring] Add for Polynomial[A] with op_add(xs, ys) {
  let lx = xs.terms.length()
  let ly = ys.terms.length()
  let l_max = @cmp.maximum(lx, ly)
  let l_min = @cmp.minimum(lx, ly)
  let larger = if ly >= lx { ys } else { xs }
  {
    terms: Array::makei(l_max, fn(i) {
      if i < l_min {
        xs.terms[i] + ys.terms[i]
      } else {
        larger.terms[i]
      }
    }),
  }
}

///|
/// Subtracts one polynomial from another.
///
/// Parameters:
///
/// * `self` : The polynomial from which to subtract.
/// * `other` : The polynomial to subtract from `self`.
///
/// Returns a new polynomial representing the difference `self - other`.
///
/// Example:
///
/// ```moonbit
/// let p1 = @luna_poly.to_poly([1, 2, 3])  // 1 + 2x + 3x²
/// let p2 = @luna_poly.to_poly([4, 5, 6, 7])  // 4 + 5x + 6x² + 7x³
/// let result = p1 - p2
/// inspect(result, content="-3 + -3x^1 + -3x^2 + -7x^3")
/// ```
///
impl[A : Eq + Ring] Sub for Polynomial[A] with op_sub(
  self : Polynomial[A],
  other : Polynomial[A]
) -> Polynomial[A] {
  self + -other
}

///|
/// Negates a polynomial by negating all its coefficients.
///
/// Parameters:
///
/// * `polynomial` : The polynomial to negate.
///
/// Returns a new polynomial where each coefficient is the negation of the
/// corresponding coefficient in the input polynomial.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, -2, 3])
/// let neg_p = -p
/// inspect(neg_p, content="-1 + 2x^1 + -3x^2")
/// ```
///
impl[A : Ring] Neg for Polynomial[A] with op_neg(x) {
  { terms: Array::makei(x.terms.length(), fn(i) { -x.terms[i] }) }
}

///|
/// Creates a zero polynomial with a specified initial capacity.
///
/// Parameters:
///
/// * `capacity` : The initial capacity for the polynomial's internal array
///   storage.
///
/// Returns a polynomial where all coefficients are zero, with the internal
/// array pre-allocated to the specified capacity.
///
/// Example:
///
/// ```moonbit
/// let zero_poly : @luna-poly.Polynomial[Int] = @luna-poly.Polynomial::empty(cap=5)
/// inspect(zero_poly.length(), content="5")
/// inspect(zero_poly.eval(10), content="0")
/// ```
///
pub fn[A : Semiring] Polynomial::empty(cap~ : Int) -> Polynomial[A] {
  { terms: Array::make(cap, A::zero()) }
}

///|
/// Returns the number of terms in the polynomial.
///
/// Parameters:
///
/// * `self` : The polynomial whose length is to be determined.
///
/// Returns the length of the polynomial as an integer.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3])
/// inspect(p.length(), content="3")
/// ```
///
pub fn[A] Polynomial::length(self : Polynomial[A]) -> Int {
  self.terms.length()
}

///|
/// Creates a monomial polynomial with the specified power and coefficient.
///
/// Parameters:
///
/// * `power` : The exponent of the variable in the monomial (must be
///   non-negative).
/// * `coefficient` : The coefficient of the monomial term.
///
/// Returns a polynomial representing the monomial `coefficient * x^power`, or
/// the zero polynomial if the coefficient is zero.
///
/// Example:
///
/// ```moonbit
/// // Create the monomial 5x^3
/// let mono = @luna-poly.monomial(3, 5)
/// inspect(mono, content="5x^3")
///
/// // Create the monomial 2x^0 (constant term)
/// let constant = @luna-poly.monomial(0, 2)
/// inspect(constant, content="2")
///
/// // Zero coefficient results in zero polynomial
/// let zero_poly = @luna-poly.monomial(5, 0)
/// inspect(zero_poly, content="0")
/// ```
///
pub fn[A : Eq + Semiring] monomial(
  power : Int,
  coefficient : A
) -> Polynomial[A] {
  if is_zero(coefficient) {
    Polynomial::zero()
  } else {
    {
      terms: Array::makei(power + 1, fn(k) {
        if k == power {
          coefficient
        } else {
          A::zero()
        }
      }),
    }
  }
}

///|
/// Evaluates the polynomial at a given point using Horner's method.
///
/// Parameters:
///
/// * `self` : The polynomial to evaluate.
/// * `point` : The value at which to evaluate the polynomial.
///
/// Returns the result of evaluating the polynomial at the given point.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3]) // represents 1 + 2x + 3x²
/// inspect(p.eval(2), content="17") // 1 + 2(2) + 3(2²) = 1 + 4 + 12 = 17
/// ```
///
pub fn[A : Semiring] eval(self : Polynomial[A], init : A) -> A {
  self.substitute(A::op_mul, init~)
}

///|
/// Substitutes the polynomial's variable with expressions of type `B` using a
/// custom combination function.
///
/// Parameters:
///
/// * `self` : The polynomial whose variable will be substituted.
/// * `f` : A function that combines a power of the substituted expression with
///   a coefficient from the polynomial.
/// * `init` : The expression to substitute for the polynomial's variable.
///
/// Returns the result of the substitution as type `B`.
///
/// Examples:
///
/// ```moonbit
/// // Evaluate polynomial at a specific value
/// let p = to_poly([1, 2, 3]) // 1 + 2x + 3x²
/// let result = p.substitute(fn(power, coeff) { power * coeff }, init=5)
/// inspect(result, content="86") // 1*1 + 2*5 + 3*25 = 86
///
/// // Substitute with another polynomial
/// let p1 = to_poly([1, 1, 1]) // 1 + x + x²
/// let p2 = to_poly([2, 1])    // 2 + x
/// let result = p1.substitute(fn(poly_power, coeff) { poly_power.scale(0, coeff) }, init=p2)
/// // Result is 1 + (2 + x) + (2 + x)² = 1 + 2 + x + 4 + 4x + x² = 7 + 5x + x²
/// ```
///
pub fn[A, B : Semiring] substitute(
  self : Polynomial[A],
  f : (B, A) -> B,
  init~ : B
) -> B {
  self.fold(
    (a, cn) => {
      let (acc, xn) = a
      (acc + f(xn, cn), init * xn)
    },
    init=(B::zero(), B::one()),
  ).0
}

///|
/// Substitutes the variable in a polynomial with another polynomial.
///
/// Parameters:
///
/// * `self` : The polynomial whose variable will be substituted.
/// * `x` : The polynomial to substitute for the variable.
///
/// Returns a new polynomial where every occurrence of the variable in `self`
/// has been replaced with the polynomial `x`.
///
/// Example:
///
/// ```moonbit
/// let p1 = to_poly([1, 2, 3])  // 1 + 2x + 3x²
/// let p2 = to_poly([2, 3])     // 2 + 3x
/// let result = p1.substitute_poly(p2)
/// inspect(result, content="17 + 42x^1 + 27x^2")
/// ```
///
pub fn[A : Eq + Semiring] substitute_poly(
  self : Polynomial[A],
  x : Polynomial[A]
) -> Polynomial[A] {
  self.substitute(fn(poly, x) { poly.scale(0, x) }, init=x)
}

///|
/// Multiplies a polynomial by a monomial (a single term with a coefficient and
/// power).
///
/// Parameters:
///
/// * `self` : The polynomial to be multiplied.
/// * `power` : The power of the variable in the monomial.
/// * `coefficient` : The coefficient of the monomial.
///
/// Returns a new polynomial where each term of the original polynomial is
/// multiplied by the monomial `coefficient * x^power`.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3]) // 1 + 2x + 3x²
/// let scaled = p.scale(2, 5) // Multiply by 5x²
/// inspect(scaled, content="5x^2 + 10x^3 + 15x^4")
/// ```
///
pub fn[A : Eq + Semiring] scale(
  self : Polynomial[A],
  power : Int,
  coefficient : A
) -> Polynomial[A] {
  let len = self.length()
  let terms = Array::make(power + len, A::zero())
  for k in 0..<len {
    terms[k + power] = coefficient * self.terms[k]
  }
  to_poly(terms)
}

///|
/// Computes the derivative of the polynomial using the power rule of
/// differentiation.
///
/// Parameters:
///
/// * `self` : The polynomial to differentiate.
///
/// Returns a new polynomial that represents the derivative of the input
/// polynomial.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3]) // 1 + 2x + 3x²
/// let dp = p.derivative() // 2 + 6x
/// inspect(dp, content="2 + 6x^1")
/// ```
///
pub fn[A : HomomorphismNat + Eq + Semiring] derivative(
  self : Polynomial[A]
) -> Polynomial[A] {
  let len = self.length()
  if len == 0 {
    Polynomial::zero()
  } else {
    self.terms[1:].mapi(fn(i, x) { HomomorphismNat::from_nat(i + 1) * x })
    |> to_poly
  }
}

///|
/// Reduces the polynomial to a single value by applying a binary function to
/// each coefficient.
///
/// Parameters:
///
/// * `self` : The polynomial to fold over.
/// * `f` : A binary function that takes an accumulator of type `B` and a
///   coefficient of type `A`, returning a new accumulator of type `B`.
/// * `init` : The initial value of the accumulator.
///
/// Returns the final accumulated value after processing all coefficients.
///
/// Example:
///
/// ```moonbit
/// let p = @luna-poly.to_poly([1, 2, 3]) // represents 1 + 2x + 3x²
/// let sum = p.fold((acc, coeff) => acc + coeff, init=0)
/// inspect(sum, content="6") // sum of all coefficients: 1 + 2 + 3
/// ```
///
pub fn[A, B] fold(self : Polynomial[A], f : (B, A) -> B, init~ : B) -> B {
  self.terms.fold(f, init~)
}

///|
/// Creates a constant polynomial representing the coefficient `n`.
///
/// Parameters:
///
/// * `n` : The integer coefficient to convert into a polynomial.
///
/// Returns a polynomial representing the constant value `n`.
///
/// Examples:
///
/// ```moonbit
/// // Create a constant polynomial with coefficient 5
/// let p1 = @luna-poly.coe(5)
/// inspect(p1, content="5")
///
/// // Create a zero polynomial
/// let p2 = @luna-poly.coe(0) 
/// inspect(p2, content="0")
///
/// // Use in polynomial arithmetic
/// let x = @luna-poly.vari()
/// let poly = @luna-poly.coe(3) + x * @luna-poly.coe(2)
/// inspect(poly, content="3 + 2x^1")
/// ```
///
pub fn[A : Eq + Semiring + HomomorphismNat] coe(n : Int) -> Polynomial[A] {
  match n {
    0 => Polynomial::zero()
    n => { terms: [A::from_nat(n)] }
  }
}

///|
/// Creates a polynomial representing the variable `x` (i.e., the polynomial
/// `x^1`).
///
/// Returns a `Polynomial[A]` representing the variable `x`. If the
/// multiplicative identity of type `A` is zero, returns the zero polynomial.
///
/// Example:
///
/// ```moonbit
/// let x : @luna-poly.Polynomial[Int] = @luna-poly.vari()
/// inspect(x, content="1x^1")
/// ```
///
pub fn[A : Eq + Semiring] vari() -> Polynomial[A] {
  if is_zero(A::one()) {
    Polynomial::zero()
  } else {
    Polynomial::from_array([A::zero(), A::one()])
  }
}

///|
/// Creates a polynomial directly from an array of coefficients without
/// normalization.
///
/// Parameters:
///
/// * `terms` : An array of coefficients where the element at index `i`
///   represents the coefficient of `x^i`.
///
/// Returns a new polynomial with the given coefficients, including any trailing
/// zero coefficients.
///
/// Example:
///
/// ```moonbit
/// let poly = Polynomial::from_array([1, 0, 3, 0])  // Creates polynomial 1 + 0x + 3x^2 + 0x^3
/// inspect(poly.length(), content="4")  // Preserves all coefficients including trailing zeros
/// ```
///
fn[A] Polynomial::from_array(terms : Array[A]) -> Polynomial[A] {
  { terms, }
}

///|
/// Tests the basic operations and functionality of dense polynomial
/// implementation.
///
/// This comprehensive test verifies:
///
/// * Polynomial creation from coefficient arrays using `to_poly`
/// * Polynomial string representation and formatting
/// * Polynomial addition operations
/// * Polynomial multiplication operations
/// * Variable and coefficient creation using `vari` and `coe`
/// * Handling of polynomials with zero coefficients
///
/// The test creates several polynomials and validates their string
/// representations, then performs arithmetic operations and verifies the
/// results. It demonstrates polynomial algebra including:
///
/// * `p1 = 1 + 2x + 3x²` and `p2 = 4 + 5x + 6x² + 7x³`
/// * Addition: `p1 + p2 = 5 + 7x + 9x² + 7x³`
/// * Multiplication: `p1 * p2 = 4 + 13x + 28x² + 34x³ + 32x⁴ + 21x⁵`
/// * Symbolic computation: `(x + 1)(x - 1) = x² - 1`
///
/// Example:
///
/// ```moonbit
/// // Creates polynomial 1 + 2x + 3x²
/// let p1 = @luna-poly.to_poly([1, 2, 3])
///
/// // Creates polynomial 4 + 5x + 6x² + 7x³  
/// let p2 = @luna-poly.to_poly([4, 5, 6, 7])
///
/// // Polynomial addition
/// let sum = p1 + p2  // Results in 5 + 7x + 9x² + 7x³
///
/// // Polynomial multiplication
/// let product = p1 * p2  // Results in 4 + 13x + 28x² + 34x³ + 32x⁴ + 21x⁵
/// ```
///
test "dense polynomial" {
  let x = vari
  let p1 = to_poly([1, 2, 3])
  inspect(p1, content="1 + 2x^1 + 3x^2")
  let p2 = to_poly([4, 5, 6, 7])
  inspect(p2, content="4 + 5x^1 + 6x^2 + 7x^3")
  let p5 = to_poly([-1, 0, 2])
  inspect(p5, content="-1 + 2x^2")
  let p3 = p1 + p2
  inspect(p3, content="5 + 7x^1 + 9x^2 + 7x^3")
  let p4 = p1 * p2
  inspect(p4, content="4 + 13x^1 + 28x^2 + 34x^3 + 32x^4 + 21x^5")
  let p5 : Polynomial[Int] = (x() + coe(1)) * (x() + coe(-1))
  inspect(p5, content="-1 + 1x^2")
}

///|
/// Tests polynomial negation and subtraction operations.
///
/// This test verifies the correct implementation of the unary negation operator
/// (`-`) and binary subtraction operator (`-`) for polynomials. It creates two
/// test polynomials, applies negation to one of them, and performs subtraction
/// between them to ensure the operations produce the expected results.
///
/// The test uses the following polynomials:
///
/// * `p1`: represents the polynomial `1 + 2x + 3x²`
/// * `p2`: represents the polynomial `4 + 5x + 6x² + 7x³`
///
/// The test verifies:
///
/// 1. Negating `p1` produces `-1 - 2x - 3x²`
/// 2. Subtracting `p2` from `p1` produces `-3 - 3x - 3x² - 7x³`
///
/// This ensures that the polynomial arithmetic operations follow standard
/// mathematical rules for polynomial negation and subtraction.
///
test "inverse" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([4, 5, 6, 7])
  let p1n = -p1
  inspect(p1n, content="-1 + -2x^1 + -3x^2")
  let p3 = p1 - p2
  inspect(p3, content="-3 + -3x^1 + -3x^2 + -7x^3")
}

///|
/// Tests polynomial evaluation at specific points.
///
/// This test verifies the `eval` method of the `Polynomial` type by:
///
/// 1. Creating a polynomial `p1` representing `1 + 2x + 3x²` from the array
/// `[1, 2, 3]`
/// 2. Evaluating the polynomial at `x = 2`, which should yield `1 + 2(2) +
/// 3(2²) = 1 + 4 + 12 = 17`
/// 3. Evaluating the polynomial at `x = 1`, which should yield `1 + 2(1) +
/// 3(1²) = 1 + 2 + 3 = 6`
///
/// The test ensures that polynomial evaluation correctly substitutes the given
/// value for the variable and computes the result according to the polynomial's
/// coefficients and powers.
///
test "eval" {
  let p1 = to_poly([1, 2, 3])
  inspect(p1.eval(2), content="17")
  inspect(p1.eval(1), content="6")
}

///|
/// Tests the `scale` method functionality for polynomial monomial
/// multiplication.
///
/// This test verifies that the `scale` method correctly multiplies a polynomial
/// by a monomial (a term with a specific power and coefficient). It creates a
/// polynomial `1 + 2x + 3x²`, scales it by multiplying with the monomial `3x²`
/// (coefficient 3 at power 2), and verifies the result is `3x² + 6x³ + 9x⁴`.
///
/// The test demonstrates that:
///
/// * The original polynomial remains unchanged after scaling
/// * Each term in the original polynomial is multiplied by the coefficient (3)
/// * Each term's power is increased by the scaling power (2)
/// * The resulting polynomial has the expected form and coefficients
///
/// Example operations tested:
///
/// * `to_poly([1, 2, 3])` creates polynomial `1 + 2x + 3x²`
/// * `p1.scale(2, 3)` multiplies by monomial `3x²`
/// * Result: `3x² + 6x³ + 9x⁴` (each original term multiplied by `3x²`)
///
test "scale" {
  let p1 = to_poly([1, 2, 3])
  let p2 = p1.scale(2, 3)
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="3x^2 + 6x^3 + 9x^4")
}

///|
/// Tests polynomial substitution functionality by replacing the variable in one
/// polynomial with another polynomial.
///
/// This test verifies the `substitute_poly` method which substitutes the
/// variable `x` in a polynomial `p(x)` with another polynomial `q(x)`,
/// effectively computing `p(q(x))`.
///
/// The test covers two scenarios:
///
/// 1. Substituting a non-constant polynomial: `p1(p2(x))` where `p1(x) = 1 + 2x
/// + 3x²` and `p2(x) = 2 + 3x`
/// 2. Substituting a constant polynomial: `p1(p4(x))` where `p4(x) = 1`
/// (constant)
///
/// For the first case, the substitution `(1 + 2x + 3x²).substitute_poly(2 +
/// 3x)` expands to:
///
/// * `1 + 2(2 + 3x) + 3(2 + 3x)²`
/// * `= 1 + 4 + 6x + 3(4 + 12x + 9x²)`
/// * `= 1 + 4 + 6x + 12 + 36x + 27x²`
/// * `= 17 + 42x + 27x²`
///
/// For the second case, substituting the constant `1` into `1 + 2x + 3x²`
/// yields:
///
/// * `1 + 2(1) + 3(1)² = 1 + 2 + 3 = 6`
///
/// The test validates that the polynomial display format correctly shows
/// coefficients and powers, and that polynomial substitution produces
/// mathematically correct results.
///
test "substitute polynomial" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([2, 3])
  let p3 = p1.substitute_poly(p2)
  let p4 = to_poly([1])
  let p5 = p1.substitute_poly(p4)
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="2 + 3x^1")
  inspect(p3, content="17 + 42x^1 + 27x^2")
  inspect(p4, content="1")
  inspect(p5, content="6")
}

///|
/// Tests the derivative functionality of dense polynomials by computing
/// successive derivatives and verifying the results.
///
/// This test verifies that the `derivative` method correctly computes
/// polynomial derivatives according to the power rule. It creates a quadratic
/// polynomial `1 + 2x + 3x²`, computes its first derivative `2 + 6x`, and then
/// computes the second derivative `6` (which is a constant). The test ensures
/// that:
///
/// 1. The first derivative of `1 + 2x + 3x²` is `2 + 6x` (applying the power
/// rule: d/dx(1) = 0, d/dx(2x) = 2, d/dx(3x²) = 6x)
/// 2. The second derivative of the original polynomial is the constant `6`
/// (d/dx(2 + 6x) = 6)
/// 3. The polynomial representation and coefficient handling work correctly for
/// derivative operations
///
/// The test uses the `to_poly` function to create a polynomial from coefficient
/// arrays and the `derivative` method to compute derivatives, validating the
/// mathematical correctness of the implementation.
///
/// Example:
///
/// ```moonbit
/// // Create polynomial 1 + 2x + 3x²
/// let p = to_poly([1, 2, 3])
/// // First derivative: 2 + 6x
/// let dp = p.derivative()
/// // Second derivative: 6
/// let d2p = dp.derivative()
/// ```
///
test "derivative" {
  let p1 = to_poly([1, 2, 3])
  let p2 = p1.derivative()
  let p3 = p2.derivative()
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="2 + 6x^1")
  inspect(p3, content="6")
}
