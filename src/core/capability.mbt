///|
pub(open) trait HasLength {
  fn length(Self) -> Int32
}

///|
pub(open) trait HasDegree {
  fn degree(Self) -> Int32?
}

///|
pub(open) trait IsZero {
  fn is_zero(Self) -> Bool
}

///|
pub(open) trait HasTermCount {
  fn term_count(Self) -> Int32
}

///|
pub(open) trait HasArity {
  fn arity(Self) -> Int32
}

///|
pub(open) trait HasTotalDegree {
  fn total_degree(Self) -> UInt32?
}

///|
pub(open) trait HasContext {
  fn context(Self) -> VariableContext
}

///|
pub enum PolynomialShape {
  Univariate(length~ : Int32)
  Multivariate(arity~ : Int32, term_count~ : Int32)
  Contextual(context~ : VariableContext, arity~ : Int32, term_count~ : Int32)
} derive(Eq, Debug)

///|
pub fn PolynomialShape::univariate(length : Int32) -> PolynomialShape {
  Univariate(length~)
}

///|
pub fn PolynomialShape::multivariate(
  arity : Int32,
  term_count : Int32,
) -> PolynomialShape {
  Multivariate(arity~, term_count~)
}

///|
pub fn PolynomialShape::contextual(
  context : VariableContext,
  arity : Int32,
  term_count : Int32,
) -> PolynomialShape {
  Contextual(context~, arity~, term_count~)
}

///|
pub fn PolynomialShape::arity(self : PolynomialShape) -> Int32 {
  match self {
    Univariate(_) => 1
    Multivariate(arity~, ..) => arity
    Contextual(arity~, ..) => arity
  }
}

///|
pub fn PolynomialShape::term_count(self : PolynomialShape) -> Int32? {
  match self {
    Univariate(_) => None
    Multivariate(term_count~, ..) => Some(term_count)
    Contextual(term_count~, ..) => Some(term_count)
  }
}

///|
pub fn PolynomialShape::is_compatible_with(
  self : PolynomialShape,
  other : PolynomialShape,
) -> Bool {
  match (self, other) {
    (Univariate(_), Univariate(_)) => true
    (Multivariate(_), Multivariate(_)) => true
    (Contextual(context=left, ..), Contextual(context=right, ..)) =>
      left == right
    _ => false
  }
}

///|
pub fn PolynomialShape::compatible_checked(
  self : PolynomialShape,
  other : PolynomialShape,
) -> Unit? {
  if self.is_compatible_with(other) {
    Some(())
  } else {
    None
  }
}

///|
pub(open) trait HasShape {
  fn shape(Self) -> PolynomialShape
}

///|
pub(open) trait Clearable {
  fn clear(Self) -> Unit
}

///|
pub(open) trait Copyable {
  fn copy(Self) -> Self
}

///|
pub(open) trait UnivariatePolynomial: HasShape + HasLength + HasDegree + IsZero {
}

///|
pub(open) trait MultivariatePolynomial: HasShape + HasTermCount + HasArity + HasTotalDegree + IsZero {
}

///|
pub(open) trait ContextualPolynomial: HasShape + HasContext + HasTermCount + HasArity + IsZero {
}

///|
pub(open) trait MutablePolynomial: Clearable + Copyable {}

///|
struct UnivariateOps[P, A] {
  zero_fn : () -> P
  one_fn : () -> P
  from_coefficients_fn : (Array[A]) -> P
  to_coefficients_fn : (P) -> Array[A]
  coefficient_fn : (P, Int32) -> A
  coefficient_checked_fn : (P, Int32) -> A?
  eval_fn : (P, A) -> A
  add_fn : (P, P) -> P
  mul_fn : (P, P) -> P
  scale_fn : (P, Int32, A) -> P
  scale_checked_fn : (P, Int32, A) -> P?
  pow_fn : (P, UInt32) -> P
}

///|
pub fn[P, A] UnivariateOps::new(
  zero : () -> P,
  one : () -> P,
  from_coefficients : (Array[A]) -> P,
  to_coefficients : (P) -> Array[A],
  coefficient : (P, Int32) -> A,
  coefficient_checked : (P, Int32) -> A?,
  eval : (P, A) -> A,
  add : (P, P) -> P,
  mul : (P, P) -> P,
  scale : (P, Int32, A) -> P,
  scale_checked : (P, Int32, A) -> P?,
  pow : (P, UInt32) -> P,
) -> UnivariateOps[P, A] {
  {
    zero_fn: zero,
    one_fn: one,
    from_coefficients_fn: from_coefficients,
    to_coefficients_fn: to_coefficients,
    coefficient_fn: coefficient,
    coefficient_checked_fn: coefficient_checked,
    eval_fn: eval,
    add_fn: add,
    mul_fn: mul,
    scale_fn: scale,
    scale_checked_fn: scale_checked,
    pow_fn: pow,
  }
}

///|
pub fn[P, A] UnivariateOps::zero(self : UnivariateOps[P, A]) -> P {
  (self.zero_fn)()
}

///|
pub fn[P, A] UnivariateOps::one(self : UnivariateOps[P, A]) -> P {
  (self.one_fn)()
}

///|
pub fn[P, A] UnivariateOps::from_coefficients(
  self : UnivariateOps[P, A],
  coefficients : Array[A],
) -> P {
  (self.from_coefficients_fn)(coefficients)
}

///|
pub fn[P, A] UnivariateOps::to_coefficients(
  self : UnivariateOps[P, A],
  polynomial : P,
) -> Array[A] {
  (self.to_coefficients_fn)(polynomial)
}

///|
pub fn[P, A] UnivariateOps::coefficient(
  self : UnivariateOps[P, A],
  polynomial : P,
  power : Int32,
) -> A {
  (self.coefficient_fn)(polynomial, power)
}

///|
pub fn[P, A] UnivariateOps::coefficient_checked(
  self : UnivariateOps[P, A],
  polynomial : P,
  power : Int32,
) -> A? {
  (self.coefficient_checked_fn)(polynomial, power)
}

///|
pub fn[P, A] UnivariateOps::eval(
  self : UnivariateOps[P, A],
  polynomial : P,
  value : A,
) -> A {
  (self.eval_fn)(polynomial, value)
}

///|
pub fn[P, A] UnivariateOps::add(
  self : UnivariateOps[P, A],
  left : P,
  right : P,
) -> P {
  (self.add_fn)(left, right)
}

///|
pub fn[P, A] UnivariateOps::mul(
  self : UnivariateOps[P, A],
  left : P,
  right : P,
) -> P {
  (self.mul_fn)(left, right)
}

///|
pub fn[P, A] UnivariateOps::scale(
  self : UnivariateOps[P, A],
  polynomial : P,
  power : Int32,
  coefficient : A,
) -> P {
  (self.scale_fn)(polynomial, power, coefficient)
}

///|
pub fn[P, A] UnivariateOps::scale_checked(
  self : UnivariateOps[P, A],
  polynomial : P,
  power : Int32,
  coefficient : A,
) -> P? {
  (self.scale_checked_fn)(polynomial, power, coefficient)
}

///|
pub fn[P, A] UnivariateOps::pow(
  self : UnivariateOps[P, A],
  polynomial : P,
  exponent : UInt32,
) -> P {
  (self.pow_fn)(polynomial, exponent)
}

///|
struct MultivariateOps[P, A] {
  zero_fn : () -> P
  one_fn : () -> P
  from_terms_fn : (Array[(ExponentVector, A)]) -> P
  to_terms_fn : (P) -> Array[(ExponentVector, A)]
  eval_indexed_fn : (P, Array[A]) -> A
  eval_indexed_checked_fn : (P, Array[A]) -> A?
  add_fn : (P, P) -> P
  mul_fn : (P, P) -> P
  scale_fn : (P, ExponentVector, A) -> P
  pow_fn : (P, UInt32) -> P
}

///|
pub fn[P, A] MultivariateOps::new(
  zero : () -> P,
  one : () -> P,
  from_terms : (Array[(ExponentVector, A)]) -> P,
  to_terms : (P) -> Array[(ExponentVector, A)],
  eval_indexed : (P, Array[A]) -> A,
  eval_indexed_checked : (P, Array[A]) -> A?,
  add : (P, P) -> P,
  mul : (P, P) -> P,
  scale : (P, ExponentVector, A) -> P,
  pow : (P, UInt32) -> P,
) -> MultivariateOps[P, A] {
  {
    zero_fn: zero,
    one_fn: one,
    from_terms_fn: from_terms,
    to_terms_fn: to_terms,
    eval_indexed_fn: eval_indexed,
    eval_indexed_checked_fn: eval_indexed_checked,
    add_fn: add,
    mul_fn: mul,
    scale_fn: scale,
    pow_fn: pow,
  }
}

///|
pub fn[P, A] MultivariateOps::zero(self : MultivariateOps[P, A]) -> P {
  (self.zero_fn)()
}

///|
pub fn[P, A] MultivariateOps::one(self : MultivariateOps[P, A]) -> P {
  (self.one_fn)()
}

///|
pub fn[P, A] MultivariateOps::from_terms(
  self : MultivariateOps[P, A],
  terms : Array[(ExponentVector, A)],
) -> P {
  (self.from_terms_fn)(terms)
}

///|
pub fn[P, A] MultivariateOps::to_terms(
  self : MultivariateOps[P, A],
  polynomial : P,
) -> Array[(ExponentVector, A)] {
  (self.to_terms_fn)(polynomial)
}

///|
pub fn[P, A] MultivariateOps::eval_indexed(
  self : MultivariateOps[P, A],
  polynomial : P,
  values : Array[A],
) -> A {
  (self.eval_indexed_fn)(polynomial, values)
}

///|
pub fn[P, A] MultivariateOps::eval_indexed_checked(
  self : MultivariateOps[P, A],
  polynomial : P,
  values : Array[A],
) -> A? {
  (self.eval_indexed_checked_fn)(polynomial, values)
}

///|
pub fn[P, A] MultivariateOps::add(
  self : MultivariateOps[P, A],
  left : P,
  right : P,
) -> P {
  (self.add_fn)(left, right)
}

///|
pub fn[P, A] MultivariateOps::mul(
  self : MultivariateOps[P, A],
  left : P,
  right : P,
) -> P {
  (self.mul_fn)(left, right)
}

///|
pub fn[P, A] MultivariateOps::scale(
  self : MultivariateOps[P, A],
  polynomial : P,
  exponent : ExponentVector,
  coefficient : A,
) -> P {
  (self.scale_fn)(polynomial, exponent, coefficient)
}

///|
pub fn[P, A] MultivariateOps::pow(
  self : MultivariateOps[P, A],
  polynomial : P,
  exponent : UInt32,
) -> P {
  (self.pow_fn)(polynomial, exponent)
}

///|
struct ContextOps[P, A] {
  from_terms_fn : (VariableContext, Array[(ExponentVector, A)]) -> P
  to_terms_fn : (P) -> Array[(ExponentVector, A)]
  eval_named_checked_fn : (P, Array[(Variable, A)]) -> A?
  add_checked_fn : (P, P) -> P?
  mul_checked_fn : (P, P) -> P?
}

///|
pub fn[P, A] ContextOps::new(
  from_terms : (VariableContext, Array[(ExponentVector, A)]) -> P,
  to_terms : (P) -> Array[(ExponentVector, A)],
  eval_named_checked : (P, Array[(Variable, A)]) -> A?,
  add_checked : (P, P) -> P?,
  mul_checked : (P, P) -> P?,
) -> ContextOps[P, A] {
  {
    from_terms_fn: from_terms,
    to_terms_fn: to_terms,
    eval_named_checked_fn: eval_named_checked,
    add_checked_fn: add_checked,
    mul_checked_fn: mul_checked,
  }
}

///|
pub fn[P, A] ContextOps::from_terms(
  self : ContextOps[P, A],
  context : VariableContext,
  terms : Array[(ExponentVector, A)],
) -> P {
  (self.from_terms_fn)(context, terms)
}

///|
pub fn[P, A] ContextOps::to_terms(
  self : ContextOps[P, A],
  polynomial : P,
) -> Array[(ExponentVector, A)] {
  (self.to_terms_fn)(polynomial)
}

///|
pub fn[P, A] ContextOps::eval_named_checked(
  self : ContextOps[P, A],
  polynomial : P,
  assignments : Array[(Variable, A)],
) -> A? {
  (self.eval_named_checked_fn)(polynomial, assignments)
}

///|
pub fn[P, A] ContextOps::add_checked(
  self : ContextOps[P, A],
  left : P,
  right : P,
) -> P? {
  (self.add_checked_fn)(left, right)
}

///|
pub fn[P, A] ContextOps::mul_checked(
  self : ContextOps[P, A],
  left : P,
  right : P,
) -> P? {
  (self.mul_checked_fn)(left, right)
}
