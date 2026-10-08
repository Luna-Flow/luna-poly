///|
/// Mutable dense univariate polynomial with canonical trailing-zero handling.
struct DensePolynomial[A] {
  mut coefficients : Array[A]
} derive(Eq, Compare, Debug)

///|
fn[A : Eq + Zero] canonical_coefficients(values : Array[A]) -> Array[A] {
  let copy = values.copy()
  while !copy.is_empty() && copy.last().unwrap() == @lg.Zero::zero() {
    let _ = copy.pop()
  }
  copy
}

///|
pub fn[A : Eq + Zero] DensePolynomial::from_coefficients(
  values : Array[A],
) -> DensePolynomial[A] {
  { coefficients: canonical_coefficients(values), }
}

///|
pub fn[A : Eq + Zero] DensePolynomial::from_immut(
  value : @immut_dense.DensePolynomial[A],
) -> DensePolynomial[A] {
  DensePolynomial::from_coefficients(value.to_coefficients())
}

///|
pub fn[A : Eq + Zero] DensePolynomial::to_immut(
  self : DensePolynomial[A],
) -> @immut_dense.DensePolynomial[A] {
  @immut_dense.DensePolynomial::from_coefficients(self.coefficients)
}

///|
pub fn[A] DensePolynomial::to_coefficients(
  self : DensePolynomial[A],
) -> Array[A] {
  self.coefficients.copy()
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
  match @immut_dense.DensePolynomial::monomial_checked(power, coefficient) {
    None => None
    Some(polynomial) => Some(DensePolynomial::from_immut(polynomial))
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
  DensePolynomial::from_immut(@immut_dense.DensePolynomial::variable())
}

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
pub fn[A : Eq + Zero] DensePolynomial::set_coefficient(
  self : DensePolynomial[A],
  power : Int,
  coefficient : A,
) -> Unit {
  guard power >= 0 else { abort("DensePolynomial power must be non-negative") }
  if power >= self.length() {
    self.coefficients.resize(power + 1, @lg.Zero::zero())
  }
  self.coefficients[power] = coefficient
  self.coefficients = canonical_coefficients(self.coefficients)
}

///|
pub fn[A] DensePolynomial::clear(self : DensePolynomial[A]) -> Unit {
  self.coefficients = []
}

///|
pub fn[A] DensePolynomial::copy(
  self : DensePolynomial[A],
) -> DensePolynomial[A] {
  { coefficients: self.coefficients.copy(), }
}

///|
pub impl[A] @poly_core.Clearable for DensePolynomial[A] with fn clear(self) {
  self.clear()
}

///|
pub impl[A] @poly_core.Copyable for DensePolynomial[A] with fn copy(self) {
  self.copy()
}

///|
pub impl[A] @poly_core.MutablePolynomial for DensePolynomial[A]

///|
pub fn[A : Eq + AddMonoid] DensePolynomial::add_inplace(
  self : DensePolynomial[A],
  other : DensePolynomial[A],
) -> Unit {
  let length = @cmp.maximum(self.length(), other.length())
  self.coefficients.resize(length, @lg.Zero::zero())
  for i in 0..<other.length() {
    self.coefficients[i] = self.coefficients[i] + other.coefficients[i]
  }
  self.coefficients = canonical_coefficients(self.coefficients)
}

///|
pub fn[A : Eq + AddMonoid + Mul] DensePolynomial::mul_inplace(
  self : DensePolynomial[A],
  other : DensePolynomial[A],
) -> Unit {
  self.coefficients = (self * other).coefficients
}

///|
pub fn[A : Eq + Zero + Mul] DensePolynomial::scale_inplace(
  self : DensePolynomial[A],
  power : Int,
  coefficient : A,
) -> Unit {
  self.coefficients = self.scale(power, coefficient).coefficients
}

///|
pub impl[A] Zero for DensePolynomial[A] with fn zero() {
  { coefficients: [], }
}

///|
pub impl[A : Eq + Zero + One] One for DensePolynomial[A] with fn one() {
  DensePolynomial::from_coefficients([@lg.One::one()])
}

///|
pub impl[A : Eq + AddMonoid] Add for DensePolynomial[A] with fn add(self, other) {
  let result = self.copy()
  result.add_inplace(other)
  result
}

///|
pub impl[A : Eq + Zero + Neg] Neg for DensePolynomial[A] with fn neg(self) {
  DensePolynomial::from_coefficients(
    self.coefficients.map(fn(value) { -value }),
  )
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
  let values = Array::make(self.length() + other.length() - 1, @lg.Zero::zero())
  for i, left in self.coefficients {
    for j, right in other.coefficients {
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
  match self.to_immut().scale_checked(power, coefficient) {
    None => None
    Some(polynomial) => Some(DensePolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : AddMonoid + Mul] DensePolynomial::eval(
  self : DensePolynomial[A],
  value : A,
) -> A {
  let mut result = @lg.Zero::zero()
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
  DensePolynomial::from_immut(self.to_immut().substitute(value.to_immut()))
}

///|
pub fn[A : FromNat + Eq + Zero + Mul] DensePolynomial::derivative(
  self : DensePolynomial[A],
) -> DensePolynomial[A] {
  DensePolynomial::from_immut(self.to_immut().derivative())
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] DensePolynomial::pow(
  self : DensePolynomial[A],
  exponent : UInt,
) -> DensePolynomial[A] {
  DensePolynomial::from_immut(self.to_immut().pow(exponent))
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
pub fn[A : Eq + AddMonoid + Mul + Neg + One] DensePolynomial::karatsuba(
  self : DensePolynomial[A],
  other : DensePolynomial[A],
) -> DensePolynomial[A] {
  DensePolynomial::from_immut(self.to_immut().karatsuba(other.to_immut()))
}

///|
pub impl[A : Eq + AddMonoid + Mul + One] @arithmetic.PowNatChecked for DensePolynomial[
  A,
] with fn pow_nat_checked(self, exponent, _context) {
  Ok(self.pow(exponent))
}

///|
pub impl[A : Show + Eq + Zero] Show for DensePolynomial[A] with fn output(
  self,
  logger,
) {
  Show::output(self.to_immut(), logger)
}

///|
test "mutable dense operations are explicit" {
  let p = DensePolynomial::from_coefficients([1, 2, 3])
  let original = p.copy()
  p.set_coefficient(1, 5)
  assert_true(original.to_coefficients() == [1, 2, 3])
  assert_true(p.to_coefficients() == [1, 5, 3])
  p.add_inplace(DensePolynomial::from_coefficients([-1, -5, -3]))
  assert_true(p.to_coefficients() == [])
}
