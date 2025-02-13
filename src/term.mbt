///|
type Term[A] (ExpVec, A)

///|
pub fn Term::degree[A : Semiring](self : Term[A]) -> Int {
  self._.0.degree
}

///|
pub fn Term::zero[A : Semiring + Eq]() -> Term[A] {
  (ExpVec::one(), A::zero())
}

///|
pub fn Term::is_zero[A : Semiring + Eq](self : Term[A]) -> Bool {
  self._.1 == A::zero()
}

///|
pub fn Term::one[A : Semiring + Eq]() -> Term[A] {
  (ExpVec::one(), A::one())
}

///|
pub fn Term::is_one[A : Semiring + Eq](self : Term[A]) -> Bool {
  self._.0 == ExpVec::one() && self._.1 == A::one()
}

///|
pub fn Term::pair[A : Semiring](exp_vec : ExpVec, coefficient : A) -> Term[A] {
  (exp_vec, coefficient)
}

///|
/// Compares two terms for equality in a polynomial. Returns true if either term
/// has a zero coefficient or if the exponent vectors of both terms are equal.
///
/// Parameters:
///
/// * `self` : The first term to compare.
/// * `other` : The second term to compare.
///
/// Returns `true` if the terms are considered equal, `false` otherwise.
pub fn Term::op_equal[A : Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Bool {
  self._.0 == other._.0 && self._.1 == other._.1
}

///|
pub fn Term::op_mul[A : Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Term[A] {
  if self._.1 == A::zero() || other._.1 == A::zero() {
    Term::zero()
  } else {
    (self._.0 * other._.0, self._.1 * other._.1)
  }
}

///|
pub fn Term::like[A : Semiring + Eq](self : Term[A], other : Term[A]) -> Bool {
  self._.0 == other._.0 || self._.1 == A::zero() || other._.1 == A::zero()
}

///|
pub fn Term::cancelation[A : Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Term[A] {
  guard self.like(other)
  let coefficient = self._.1 + other._.1
  guard coefficient != A::zero() else { Term::zero() }
  let exp_vec = if self._.1 == A::zero() {
    other._.0.copy()
  } else {
    self._.0.copy()
  }
  (exp_vec, coefficient)
}
