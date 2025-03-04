///|
type Term[A] (ExpVec, A)

///|
pub impl[A : Show + Eq + @lg.Semiring] Show for Term[A] with to_string(s) {
  if s._.1 == A::zero() {
    "0"
  } else {
    let s = s._.1.to_string() +
      (if s._.0.to_string() == "C" { "" } else { " * " + s._.0.to_string() })
    s
  }
}

///|
pub impl[A : Show + Eq + @lg.Semiring] Show for Term[A] with output(s, l) {
  l.write_string(s.to_string())
}

///|
test "Show" {
  assert_true!(Term::pair(ExpVec::one(), 1).to_string() == "1")
  assert_true!(
    Term::pair(ExpVec::from_array([1, 2, 3]), 1).to_string() == "1 * xy^2z^3",
  )
  assert_true!(Term::pair(ExpVec::from_array([1, 2, 3]), 0).to_string() == "0")
}

///|
pub fn Term::degree[A : @lg.Semiring](self : Term[A]) -> Int {
  self._.0.degree
}

///|
impl[A : @lg.Semiring] @lg.Zero for Term[A] with zero() -> Term[A] {
  (ExpVec::one(), A::zero())
}

///|
pub fn Term::is_zero[A : @lg.Semiring + Eq](self : Term[A]) -> Bool {
  self._.1 == A::zero()
}

///|
pub fn Term::one[A : @lg.Semiring + Eq]() -> Term[A] {
  (ExpVec::one(), A::one())
}

///|
pub fn Term::is_one[A : @lg.Semiring + Eq](self : Term[A]) -> Bool {
  self._.0 == ExpVec::one() && self._.1 == A::one()
}

///|
pub fn Term::pair[A : @lg.Semiring](
  exp_vec : ExpVec,
  coefficient : A
) -> Term[A] {
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
pub fn Term::op_equal[A : @lg.Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Bool {
  self._.0 == other._.0 && self._.1 == other._.1
}

///|
pub fn Term::op_mul[A : @lg.Semiring + Eq](
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
pub fn Term::like[A : @lg.Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Bool {
  self._.0 == other._.0 || self._.1 == A::zero() || other._.1 == A::zero()
}

///|
pub fn Term::cancellation[A : @lg.Semiring + Eq](
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
