///|
/// Immutable multivariate polynomial backed by a canonical sorted term array.
struct TermPolynomial[A] {
  terms : @core_vector.Vector[(ExponentVector, A)]
} derive(Eq)

///|
fn[A : Eq + AddMonoid] normalize_terms(
  input : Array[(ExponentVector, A)],
) -> Array[(ExponentVector, A)] {
  if input.is_empty() {
    return []
  }
  let sorted = input.copy()
  sorted.sort_by(fn(left, right) { right.0.compare(left.0) })
  let result : Array[(ExponentVector, A)] = []
  let mut exponent = sorted[0].0
  let mut coefficient = sorted[0].1
  for i in 1..<sorted.length() {
    let term = sorted[i]
    if term.0 == exponent {
      coefficient = coefficient + term.1
    } else {
      if coefficient != A::zero() {
        result.push((exponent, coefficient))
      }
      exponent = term.0
      coefficient = term.1
    }
  }
  if coefficient != A::zero() {
    result.push((exponent, coefficient))
  }
  result
}

///|
pub fn[A : Eq + AddMonoid] TermPolynomial::from_terms(
  terms : Array[(ExponentVector, A)],
) -> TermPolynomial[A] {
  { terms: @core_vector.from_array(normalize_terms(terms)) }
}

///|
pub fn[A : Eq + AddMonoid] TermPolynomial::from_array(
  terms : Array[(Array[UInt], A)],
) -> TermPolynomial[A] {
  TermPolynomial::from_terms(
    terms.map(fn(term) { (ExponentVector::from_array(term.0), term.1) }),
  )
}

///|
pub fn[A] TermPolynomial::to_terms(
  self : TermPolynomial[A],
) -> Array[(ExponentVector, A)] {
  self.terms.iter().to_array()
}

///|
pub fn[A] TermPolynomial::size(self : TermPolynomial[A]) -> Int {
  self.terms.length()
}

///|
fn[A] TermPolynomial::arity(self : TermPolynomial[A]) -> Int {
  let mut result = 0
  for term in self.terms {
    result = @cmp.maximum(result, term.0.length())
  }
  result
}

///|
fn[A] TermPolynomial::total_degree(self : TermPolynomial[A]) -> UInt? {
  let mut result = 0U
  let mut found = false
  for term in self.terms {
    let degree = term.0.degree()
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
pub impl[A] @poly_core.HasTermCount for TermPolynomial[A] with fn term_count(
  self,
) {
  self.size()
}

///|
pub impl[A] @poly_core.HasArity for TermPolynomial[A] with fn arity(self) {
  self.arity()
}

///|
pub impl[A] @poly_core.HasTotalDegree for TermPolynomial[A] with fn total_degree(
  self,
) {
  self.total_degree()
}

///|
pub impl[A] @poly_core.HasShape for TermPolynomial[A] with fn shape(self) {
  @poly_core.PolynomialShape::multivariate(self.arity(), self.size())
}

///|
pub impl[A] @poly_core.IsZero for TermPolynomial[A] with fn is_zero(self) {
  self.size() == 0
}

///|
pub impl[A] @poly_core.MultivariatePolynomial for TermPolynomial[A]

///|
pub fn[A] TermPolynomial::coefficients(self : TermPolynomial[A]) -> Array[A] {
  self.terms.iter().map(fn(term) { term.1 }).to_array()
}

///|
pub impl[A] Zero for TermPolynomial[A] with fn zero() {
  { terms: @core_vector.from_array([]) }
}

///|
pub impl[A : Eq + Zero + One] One for TermPolynomial[A] with fn one() {
  if A::one() == A::zero() {
    TermPolynomial::zero()
  } else {
    { terms: @core_vector.from_array([(ExponentVector::one(), A::one())]) }
  }
}

///|
pub impl[A : Eq + AddMonoid] Add for TermPolynomial[A] with fn add(self, other) {
  let terms = self.to_terms()
  for term in other.terms {
    terms.push(term)
  }
  TermPolynomial::from_terms(terms)
}

///|
pub impl[A : Eq + Zero + Neg] Neg for TermPolynomial[A] with fn neg(self) {
  let terms : Array[(ExponentVector, A)] = []
  for term in self.terms {
    let coefficient = -term.1
    if coefficient != A::zero() {
      terms.push((term.0, coefficient))
    }
  }
  { terms: @core_vector.from_array(terms) }
}

///|
pub impl[A : Eq + AddMonoid + Neg] Sub for TermPolynomial[A] with fn sub(
  self,
  other,
) {
  self + -other
}

///|
pub impl[A : Eq + AddMonoid + Mul] Mul for TermPolynomial[A] with fn mul(
  self,
  other,
) {
  let terms : Array[(ExponentVector, A)] = []
  for left in self.terms {
    for right in other.terms {
      terms.push((left.0 * right.0, left.1 * right.1))
    }
  }
  TermPolynomial::from_terms(terms)
}

///|
pub fn[A : Eq + Zero + Mul] TermPolynomial::scale(
  self : TermPolynomial[A],
  exponent : ExponentVector,
  coefficient : A,
) -> TermPolynomial[A] {
  if coefficient == A::zero() {
    return TermPolynomial::zero()
  }
  let terms : Array[(ExponentVector, A)] = []
  for term in self.terms {
    let scaled = term.1 * coefficient
    if scaled != A::zero() {
      terms.push((term.0 * exponent, scaled))
    }
  }
  { terms: @core_vector.from_array(terms) }
}

///|
pub fn[A : AddMonoid + Mul + One] TermPolynomial::eval(
  self : TermPolynomial[A],
  values : Array[A],
) -> A {
  match self.eval_checked(values) {
    None => abort("Missing value for multivariate polynomial variable")
    Some(value) => value
  }
}

///|
pub fn[A : AddMonoid + Mul + One] TermPolynomial::eval_checked(
  self : TermPolynomial[A],
  values : Array[A],
) -> A? {
  if self.arity() > values.length() {
    return None
  }
  let mut result = A::zero()
  for entry in self.terms {
    let (exponent, coefficient) = entry
    let mut term = coefficient
    for i in 0..<exponent.length() {
      term = term * @internal.pow_nat(values[i], exponent[i], one=A::one())
    }
    result = result + term
  }
  Some(result)
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] TermPolynomial::pow(
  self : TermPolynomial[A],
  exponent : UInt,
) -> TermPolynomial[A] {
  @internal.pow_nat(self, exponent, one=TermPolynomial::one())
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] TermPolynomial::ops() -> @poly_core.MultivariateOps[
  TermPolynomial[A],
  A,
] {
  @poly_core.MultivariateOps::new(
    fn() { TermPolynomial::zero() },
    fn() { TermPolynomial::one() },
    fn(terms) { TermPolynomial::from_terms(terms) },
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
pub impl[A : Eq + AddMonoid + Mul + One] @arithmetic.PowNatChecked for TermPolynomial[
  A,
] with fn pow_nat_checked(self, exponent, _context) {
  Ok(self.pow(exponent))
}

///|
pub impl[A : Show + Zero] Show for TermPolynomial[A] with fn output(
  self,
  logger,
) {
  if self.terms.length() == 0 {
    logger.write_object(A::zero())
    return
  }
  for i in 0..<self.terms.length() {
    let term = self.terms[i]
    if i > 0 {
      logger.write_string(" + ")
    }
    logger.write_object(term.1)
    if !term.0.is_one() {
      logger..write_string(" * ").write_object(term.0)
    }
  }
}

///|
test "term-array multivariate polynomial normalizes input" {
  let p = TermPolynomial::from_array([
    ([1U, 0], 2),
    ([1U], -2),
    ([0U, 1], 3),
    ([0U, 0], 0),
  ])
  assert_eq(p.size(), 1)
  assert_eq(p.eval([5, 2]), 6)
}

///|
test "term-array multivariate polynomial constructor copies input array" {
  let x = ExponentVector::from_array([1U])
  let source = [(x, 2)]
  let p = TermPolynomial::from_terms(source)
  source[0] = (ExponentVector::from_array([2U]), 9)
  assert_true(p.to_terms() == [(x, 2)])
}
