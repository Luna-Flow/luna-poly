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
pub fn Term::one[A : Semiring + Eq]() -> Term[A] {
  (ExpVec::one(), A::one())
}

///|
pub fn Term::pair[A : Semiring](exp_vec : ExpVec, coefficient : A) -> Term[A] {
  (exp_vec, coefficient)
}

///|
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
pub fn Term::is_like_term[A : Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Bool {
  self._.1 == A::zero() || other._.1 == A::zero() || self._.0 == other._.0
}

///|
pub fn Term::cancelation[A : Semiring + Eq](
  self : Term[A],
  other : Term[A]
) -> Term[A] {
  guard self.is_like_term(other)
  let coefficient = self._.1 + other._.1
  guard coefficient != A::zero() else { Term::zero() }
  let exp_vec = self._.0.copy()
  (exp_vec, coefficient)
}
