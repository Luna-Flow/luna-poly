///|
/// Immutable dense univariate polynomial in ascending coefficient order.
struct DensePolynomial[A] {
  coefficients : @core_vector.Vector[A]
} derive(Eq, Compare)

///|
fn[A : Eq + Zero] DensePolynomial::from_vector(
  values : @core_vector.Vector[A],
) -> DensePolynomial[A] {
  let mut length = values.length()
  while length > 0 && values[length - 1] == A::zero() {
    length = length - 1
  }
  { coefficients: @core_vector.makei(length, fn(i) { values[i] }) }
}

///|
pub fn[A : Eq + Zero] DensePolynomial::from_coefficients(
  values : Array[A],
) -> DensePolynomial[A] {
  DensePolynomial::from_vector(@core_vector.from_array(values))
}

///|
pub fn[A] DensePolynomial::to_coefficients(
  self : DensePolynomial[A],
) -> Array[A] {
  self.coefficients.iter().to_array()
}

///|
pub fn[A] DensePolynomial::length(self : DensePolynomial[A]) -> Int {
  self.coefficients.length()
}

///|
pub fn[A] DensePolynomial::degree(self : DensePolynomial[A]) -> Int? {
  if self.coefficients.is_empty() {
    None
  } else {
    Some(self.length() - 1)
  }
}

///|
pub impl[A] @poly_core.HasLength for DensePolynomial[A] with fn length(self) {
  self.length()
}

///|
pub impl[A] @poly_core.HasDegree for DensePolynomial[A] with fn degree(self) {
  self.degree()
}

///|
pub impl[A] @poly_core.HasShape for DensePolynomial[A] with fn shape(self) {
  @poly_core.PolynomialShape::univariate(self.length())
}

///|
pub impl[A] @poly_core.IsZero for DensePolynomial[A] with fn is_zero(self) {
  self.length() == 0
}

///|
pub impl[A] @poly_core.UnivariatePolynomial for DensePolynomial[A]

///|
pub fn[A : Zero] DensePolynomial::coefficient(
  self : DensePolynomial[A],
  power : Int,
) -> A {
  match self.coefficient_checked(power) {
    None => abort("DensePolynomial power must be non-negative")
    Some(coefficient) => coefficient
  }
}

///|
pub fn[A : Zero] DensePolynomial::coefficient_checked(
  self : DensePolynomial[A],
  power : Int,
) -> A? {
  if power < 0 {
    None
  } else if power < self.length() {
    Some(self.coefficients[power])
  } else {
    Some(A::zero())
  }
}

///|
pub fn[A] DensePolynomial::leading_term(self : DensePolynomial[A]) -> (Int, A)? {
  self.degree().map(fn(power) { (power, self.coefficients[power]) })
}

///|
pub fn[A] DensePolynomial::leading_coefficient(self : DensePolynomial[A]) -> A? {
  self.leading_term().map(fn(term) { term.1 })
}

///|
pub fn[A : Eq + Zero] DensePolynomial::monomial(
  power : Int,
  coefficient : A,
) -> DensePolynomial[A] {
  match DensePolynomial::monomial_checked(power, coefficient) {
    None => abort("DensePolynomial power must be non-negative")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + Zero] DensePolynomial::monomial_checked(
  power : Int,
  coefficient : A,
) -> DensePolynomial[A]? {
  if power < 0 {
    return None
  }
  if coefficient == A::zero() {
    Some(DensePolynomial::zero())
  } else {
    Some(
      DensePolynomial::from_vector(
        @core_vector.makei(power + 1, fn(i) {
          if i == power {
            coefficient
          } else {
            A::zero()
          }
        }),
      ),
    )
  }
}

///|
pub fn[A : Eq + Zero] DensePolynomial::constant(
  value : A,
) -> DensePolynomial[A] {
  DensePolynomial::from_coefficients([value])
}

///|
pub fn[A : Eq + Zero + One] DensePolynomial::variable() -> DensePolynomial[A] {
  DensePolynomial::from_coefficients([A::zero(), A::one()])
}

///|
pub impl[A] Zero for DensePolynomial[A] with fn zero() {
  { coefficients: @core_vector.from_array([]) }
}

///|
pub impl[A : Eq + Zero + One] One for DensePolynomial[A] with fn one() {
  DensePolynomial::constant(A::one())
}

///|
pub impl[A : Eq + AddMonoid] Add for DensePolynomial[A] with fn add(self, other) {
  let length = @cmp.maximum(self.length(), other.length())
  DensePolynomial::from_vector(
    @core_vector.makei(length, fn(i) {
      self.coefficient(i) + other.coefficient(i)
    }),
  )
}

///|
pub impl[A : Eq + Zero + Neg] Neg for DensePolynomial[A] with fn neg(self) {
  DensePolynomial::from_vector(self.coefficients.map(fn(x) { -x }))
}

///|
pub impl[A : Eq + AddMonoid + Neg] Sub for DensePolynomial[A] with fn sub(
  self,
  other,
) {
  self + -other
}

///|
pub impl[A : Eq + AddMonoid + Mul] Mul for DensePolynomial[A] with fn mul(
  self,
  other,
) {
  if self.length() == 0 || other.length() == 0 {
    return DensePolynomial::zero()
  }
  let values = Array::make(self.length() + other.length() - 1, A::zero())
  for i in 0..<self.length() {
    let left = self.coefficients[i]
    for j in 0..<other.length() {
      let right = other.coefficients[j]
      values[i + j] = values[i + j] + left * right
    }
  }
  DensePolynomial::from_coefficients(values)
}

///|
pub fn[A : Eq + Zero + Mul] DensePolynomial::scale(
  self : DensePolynomial[A],
  power : Int,
  coefficient : A,
) -> DensePolynomial[A] {
  match self.scale_checked(power, coefficient) {
    None => abort("DensePolynomial power must be non-negative")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + Zero + Mul] DensePolynomial::scale_checked(
  self : DensePolynomial[A],
  power : Int,
  coefficient : A,
) -> DensePolynomial[A]? {
  if power < 0 {
    return None
  }
  if self.length() == 0 || coefficient == A::zero() {
    return Some(DensePolynomial::zero())
  }
  Some(
    DensePolynomial::from_vector(
      @core_vector.makei(power + self.length(), fn(i) {
        if i < power {
          A::zero()
        } else {
          coefficient * self.coefficients[i - power]
        }
      }),
    ),
  )
}

///|
pub fn[A : AddMonoid + Mul] DensePolynomial::eval(
  self : DensePolynomial[A],
  value : A,
) -> A {
  let mut result = A::zero()
  for i = self.length() - 1; i >= 0; i = i - 1 {
    result = result * value + self.coefficients[i]
  }
  result
}

///|
pub fn[A : Eq + AddMonoid + Mul] DensePolynomial::substitute(
  self : DensePolynomial[A],
  value : DensePolynomial[A],
) -> DensePolynomial[A] {
  let mut result = DensePolynomial::zero()
  for i = self.length() - 1; i >= 0; i = i - 1 {
    result = result * value + DensePolynomial::constant(self.coefficients[i])
  }
  result
}

///|
pub fn[A : NatHomomorphism + Eq + Zero + Mul] DensePolynomial::derivative(
  self : DensePolynomial[A],
) -> DensePolynomial[A] {
  if self.length() <= 1 {
    return DensePolynomial::zero()
  }
  DensePolynomial::from_vector(
    @core_vector.makei(self.length() - 1, fn(i) {
      NatHomomorphism::from_nat((i + 1).reinterpret_as_uint()) *
      self.coefficients[i + 1]
    }),
  )
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] DensePolynomial::pow(
  self : DensePolynomial[A],
  exponent : UInt,
) -> DensePolynomial[A] {
  @internal.pow_nat(self, exponent, one=DensePolynomial::one())
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] DensePolynomial::ops() -> @poly_core.UnivariateOps[
  DensePolynomial[A],
  A,
] {
  @poly_core.UnivariateOps::new(
    fn() { DensePolynomial::zero() },
    fn() { DensePolynomial::one() },
    fn(coefficients) { DensePolynomial::from_coefficients(coefficients) },
    fn(polynomial) { polynomial.to_coefficients() },
    fn(polynomial, power) { polynomial.coefficient(power) },
    fn(polynomial, power) { polynomial.coefficient_checked(power) },
    fn(polynomial, value) { polynomial.eval(value) },
    fn(left, right) { left + right },
    fn(left, right) { left * right },
    fn(polynomial, power, coefficient) { polynomial.scale(power, coefficient) },
    fn(polynomial, power, coefficient) {
      polynomial.scale_checked(power, coefficient)
    },
    fn(polynomial, exponent) { polynomial.pow(exponent) },
  )
}

///|
pub impl[A : Eq + AddMonoid + Mul + One] @arithmetic.PowNatChecked for DensePolynomial[
  A,
] with fn pow_nat_checked(self, exponent, _context) {
  Ok(self.pow(exponent))
}

///|
pub fn[A : Eq + AddMonoid + Mul + Neg + One] DensePolynomial::karatsuba(
  self : DensePolynomial[A],
  other : DensePolynomial[A],
) -> DensePolynomial[A] {
  let min_length = @cmp.minimum(self.length(), other.length())
  if min_length <= 32 {
    return self * other
  }
  let split = @cmp.maximum(self.length(), other.length()) / 2
  let split_poly = fn(
    poly : DensePolynomial[A],
  ) -> (DensePolynomial[A], DensePolynomial[A]) {
    let low_length = @cmp.minimum(poly.length(), split)
    let high_length = @cmp.maximum(poly.length() - split, 0)
    (
      DensePolynomial::from_vector(
        @core_vector.makei(low_length, fn(i) { poly.coefficients[i] }),
      ),
      DensePolynomial::from_vector(
        @core_vector.makei(high_length, fn(i) { poly.coefficients[i + split] }),
      ),
    )
  }
  let (left_low, left_high) = split_poly(self)
  let (right_low, right_high) = split_poly(other)
  let low_product = left_low.karatsuba(right_low)
  let high_product = left_high.karatsuba(right_high)
  let middle_product = (left_low + left_high).karatsuba(right_low + right_high) -
    low_product -
    high_product
  low_product +
  middle_product.scale(split, A::one()) +
  high_product.scale(split * 2, A::one())
}

///|
pub impl[A : Show + Eq + Zero] Show for DensePolynomial[A] with fn output(
  self,
  logger,
) {
  if self.length() == 0 {
    logger.write_object(A::zero())
    return
  }
  let mut first = true
  for power in 0..<self.length() {
    let coefficient = self.coefficients[power]
    if coefficient != A::zero() {
      if !first {
        logger.write_string(" + ")
      }
      logger.write_object(coefficient)
      if power > 0 {
        logger..write_string("x^").write_object(power)
      }
      first = false
    }
  }
}

///|
test "dense polynomial canonical operations" {
  let p = DensePolynomial::from_coefficients([1, 2, 3, 0, 0])
  assert_true(p.to_coefficients() == [1, 2, 3])
  assert_eq(p.eval(2), 17)
  let zero : DensePolynomial[Int] = DensePolynomial::zero()
  assert_true((p * zero).to_coefficients() == [])
}

///|
test "dense polynomial constructor copies input array" {
  let source = [1, 2, 0]
  let p = DensePolynomial::from_coefficients(source)
  source[0] = 9
  assert_true(p.to_coefficients() == [1, 2])
}

///|
test "dense polynomial derivative uses shared numeric capability" {
  let p = DensePolynomial::from_coefficients([1.0, 2.0, 3.0])
  assert_true(p.derivative().to_coefficients() == [2.0, 6.0])
}

///|
test "dense polynomial substitution and powers" {
  let p = DensePolynomial::from_coefficients([1, 2, 3])
  let q = DensePolynomial::from_coefficients([2, 3])
  assert_true(p.substitute(q).to_coefficients() == [17, 42, 27])
  assert_true(q.pow(2).to_coefficients() == [4, 12, 9])
}
