///|
/// Mutable multivariate polynomial backed by an ordered map.
struct SparsePolynomial[A] {
  terms : @sorted_map.SortedMap[ExponentVector, A]
}

///|
pub fn[A] SparsePolynomial::new() -> SparsePolynomial[A] {
  { terms: @sorted_map.SortedMap([]) }
}

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::from_terms(
  terms : Array[(ExponentVector, A)],
) -> SparsePolynomial[A] {
  let immutable = @immut_sparse.SparsePolynomial::from_terms(terms)
  SparsePolynomial::from_immut(immutable)
}

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::from_array(
  terms : Array[(Array[UInt], A)],
) -> SparsePolynomial[A] {
  SparsePolynomial::from_terms(
    terms.map(fn(term) { (ExponentVector::from_array(term.0), term.1) }),
  )
}

///|
pub fn[A] SparsePolynomial::from_immut(
  value : @immut_sparse.SparsePolynomial[A],
) -> SparsePolynomial[A] {
  let result = SparsePolynomial::new()
  for term in value.to_terms() {
    result.terms.set(term.0, term.1)
  }
  result
}

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::to_immut(
  self : SparsePolynomial[A],
) -> @immut_sparse.SparsePolynomial[A] {
  @immut_sparse.SparsePolynomial::from_terms(self.to_terms())
}

///|
pub fn[A] SparsePolynomial::to_terms(
  self : SparsePolynomial[A],
) -> Array[(ExponentVector, A)] {
  self.terms.to_array()
}

///|
pub fn[A] SparsePolynomial::size(self : SparsePolynomial[A]) -> Int {
  self.terms.length()
}

///|
fn[A] SparsePolynomial::arity(self : SparsePolynomial[A]) -> Int {
  let mut result = 0
  for exponent, _coefficient in self.terms {
    result = @cmp.maximum(result, exponent.length())
  }
  result
}

///|
fn[A] SparsePolynomial::total_degree(self : SparsePolynomial[A]) -> UInt? {
  let mut result = 0U
  let mut found = false
  for exponent, _coefficient in self.terms {
    let degree = exponent.degree()
    if !found || degree > result {
      result = degree
    }
    found = true
  }
  if found {
    Some(result)
  } else {
    None
  }
}

///|
pub impl[A] @poly_core.HasTermCount for SparsePolynomial[A] with fn term_count(
  self,
) {
  self.size()
}

///|
pub impl[A] @poly_core.HasArity for SparsePolynomial[A] with fn arity(self) {
  self.arity()
}

///|
pub impl[A] @poly_core.HasTotalDegree for SparsePolynomial[A] with fn total_degree(
  self,
) {
  self.total_degree()
}

///|
pub impl[A] @poly_core.HasShape for SparsePolynomial[A] with fn shape(self) {
  @poly_core.PolynomialShape::multivariate(self.arity(), self.size())
}

///|
pub impl[A] @poly_core.IsZero for SparsePolynomial[A] with fn is_zero(self) {
  self.size() == 0
}

///|
pub impl[A] @poly_core.MultivariatePolynomial for SparsePolynomial[A]

///|
pub fn[A] SparsePolynomial::is_empty(self : SparsePolynomial[A]) -> Bool {
  self.terms.is_empty()
}

///|
pub fn[A] SparsePolynomial::get(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
) -> A? {
  self.terms.get(exponent)
}

///|
pub fn[A] SparsePolynomial::get_checked(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
) -> A? {
  self.get(exponent)
}

///|
pub fn[A : Eq + Zero] SparsePolynomial::set_coefficient(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
  coefficient : A,
) -> Unit {
  if coefficient == A::zero() {
    self.terms.remove(exponent)
  } else {
    self.terms.set(exponent, coefficient)
  }
}

///|
pub fn[A] SparsePolynomial::clear(self : SparsePolynomial[A]) -> Unit {
  self.terms.clear()
}

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::copy(
  self : SparsePolynomial[A],
) -> SparsePolynomial[A] {
  SparsePolynomial::from_terms(self.to_terms())
}

///|
pub impl[A] @poly_core.Clearable for SparsePolynomial[A] with fn clear(self) {
  self.clear()
}

///|
pub impl[A : Eq + AddMonoid] @poly_core.Copyable for SparsePolynomial[A] with fn copy(
  self,
) {
  self.copy()
}

///|
pub impl[A : Eq + AddMonoid] @poly_core.MutablePolynomial for SparsePolynomial[
  A,
]

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::add_term_inplace(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
  coefficient : A,
) -> Unit {
  if coefficient == A::zero() {
    return
  }
  match self.terms.get(exponent) {
    None => self.terms.set(exponent, coefficient)
    Some(previous) => self.set_coefficient(exponent, previous + coefficient)
  }
}

///|
pub fn[A : Eq + AddMonoid] SparsePolynomial::add_inplace(
  self : SparsePolynomial[A],
  other : SparsePolynomial[A],
) -> Unit {
  for exponent, coefficient in other.terms {
    self.add_term_inplace(exponent, coefficient)
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul] SparsePolynomial::mul_inplace(
  self : SparsePolynomial[A],
  other : SparsePolynomial[A],
) -> Unit {
  let product = self * other
  self.clear()
  for exponent, coefficient in product.terms {
    self.terms.set(exponent, coefficient)
  }
}

///|
pub impl[A] Zero for SparsePolynomial[A] with fn zero() {
  SparsePolynomial::new()
}

///|
pub impl[A : Eq + Zero + One] One for SparsePolynomial[A] with fn one() {
  let result = SparsePolynomial::new()
  if A::one() != A::zero() {
    result.terms.set(ExponentVector::one(), A::one())
  }
  result
}

///|
pub impl[A : Eq + AddMonoid] Add for SparsePolynomial[A] with fn add(
  self,
  other,
) {
  let result = self.copy()
  result.add_inplace(other)
  result
}

///|
pub impl[A : Eq + Zero + Neg] Neg for SparsePolynomial[A] with fn neg(self) {
  let result = SparsePolynomial::new()
  for exponent, coefficient in self.terms {
    let negated = -coefficient
    if negated != A::zero() {
      result.terms.set(exponent, negated)
    }
  }
  result
}

///|
pub impl[A : Eq + AddMonoid + Neg] Sub for SparsePolynomial[A] with fn sub(
  self,
  other,
) {
  self + -other
}

///|
pub impl[A : Eq + AddMonoid + Mul] Mul for SparsePolynomial[A] with fn mul(
  self,
  other,
) {
  SparsePolynomial::from_immut(self.to_immut() * other.to_immut())
}

///|
pub fn[A : Eq + Zero + Mul] SparsePolynomial::scale(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
  coefficient : A,
) -> SparsePolynomial[A] {
  let result = SparsePolynomial::new()
  if coefficient == A::zero() {
    return result
  }
  for term_exponent, term_coefficient in self.terms {
    let scaled = term_coefficient * coefficient
    if scaled != A::zero() {
      result.terms.set(term_exponent * exponent, scaled)
    }
  }
  result
}

///|
pub fn[A : Eq + Zero + Mul] SparsePolynomial::scale_inplace(
  self : SparsePolynomial[A],
  exponent : ExponentVector,
  coefficient : A,
) -> Unit {
  let scaled = self.scale(exponent, coefficient)
  self.clear()
  for scaled_exponent, scaled_coefficient in scaled.terms {
    self.terms.set(scaled_exponent, scaled_coefficient)
  }
}

///|
pub fn[A : AddMonoid + Mul + One] SparsePolynomial::eval(
  self : SparsePolynomial[A],
  values : Array[A],
) -> A {
  match self.eval_checked(values) {
    None => abort("Missing value for multivariate polynomial variable")
    Some(value) => value
  }
}

///|
pub fn[A : AddMonoid + Mul + One] SparsePolynomial::eval_checked(
  self : SparsePolynomial[A],
  values : Array[A],
) -> A? {
  if self.arity() > values.length() {
    return None
  }
  let mut result = A::zero()
  for exponent, coefficient in self.terms {
    let mut term = coefficient
    for i in 0..<exponent.length() {
      term = term * @internal.pow_nat(values[i], exponent[i], one=A::one())
    }
    result = result + term
  }
  Some(result)
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] SparsePolynomial::pow(
  self : SparsePolynomial[A],
  exponent : UInt,
) -> SparsePolynomial[A] {
  SparsePolynomial::from_immut(self.to_immut().pow(exponent))
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] SparsePolynomial::ops() -> @poly_core.MultivariateOps[
  SparsePolynomial[A],
  A,
] {
  @poly_core.MultivariateOps::new(
    fn() { SparsePolynomial::zero() },
    fn() { SparsePolynomial::one() },
    fn(terms) { SparsePolynomial::from_terms(terms) },
    fn(polynomial) { polynomial.to_terms() },
    fn(polynomial, values) { polynomial.eval(values) },
    fn(polynomial, values) { polynomial.eval_checked(values) },
    fn(left, right) { left + right },
    fn(left, right) { left * right },
    fn(polynomial, exponent, coefficient) {
      polynomial.scale(exponent, coefficient)
    },
    fn(polynomial, exponent) { polynomial.pow(exponent) },
  )
}

///|
pub impl[A : Eq + AddMonoid + Mul + One] @arithmetic.PowNatChecked for SparsePolynomial[
  A,
] with fn pow_nat_checked(self, exponent, _context) {
  Ok(self.pow(exponent))
}

///|
pub impl[A : Eq] Eq for SparsePolynomial[A] with fn equal(self, other) {
  self.to_terms() == other.to_terms()
}

///|
pub impl[A : Show + Zero] Show for SparsePolynomial[A] with fn output(
  self,
  logger,
) {
  if self.terms.length() == 0 {
    logger.write_object(A::zero())
    return
  }
  let mut first = true
  for exponent, coefficient in self.terms {
    if !first {
      logger.write_string(" + ")
    }
    logger.write_object(coefficient)
    if !exponent.is_one() {
      logger..write_string(" * ").write_object(exponent)
    }
    first = false
  }
}

///|
test "mutable sparse operations delete zero coefficients" {
  let p = SparsePolynomial::from_array([([1U], 2)])
  p.add_term_inplace(ExponentVector::from_array([1U, 0]), -2)
  assert_true(p.is_empty())
}
