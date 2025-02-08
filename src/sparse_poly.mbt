///|
struct SparsePolynomial[V] {
  terms : Map[ExpVec, V]
} derive(Eq)

///|
impl[A : Show + Eq + Semiring] Show for SparsePolynomial[A] with to_string(self) {
  let mut s = ""
  let mut first = true
  for x in self.terms {
    let (curr_key, curr_val) = x
    if curr_val != A::zero() {
      if not(first) {
        s = s + " + "
      }
      s = s + curr_val.to_string()
      s = s + "*" + curr_key.to_string()
      first = false
    }
  }
  if first {
    "0"
  } else {
    s
  }
}

///|
impl[A : Show + Eq + Semiring] Show for SparsePolynomial[A] with output(
  self,
  logger
) {
  logger.write_string(self.to_string())
}

///|
impl[A : Eq + Semiring] Semiring for SparsePolynomial[A] with one() -> SparsePolynomial[
  A,
] {
  let terms : Map[ExpVec, A] = Map::new()
  terms.set([], A::one())
  { terms, }
}

///|
impl[A : Eq + Semiring] Semiring for SparsePolynomial[A] with zero() -> SparsePolynomial[
  A,
] {
  let terms : Map[ExpVec, A] = Map::new()
  terms.set([], A::zero())
  { terms, }
}

///|
pub fn SparsePolynomial::new[A : Semiring + Eq]() -> SparsePolynomial[A] {
  SparsePolynomial::{ terms: Map::new() }
}

///|
pub fn SparsePolynomial::size[A : Semiring + Eq](
  self : SparsePolynomial[A]
) -> Int {
  self.terms.size()
}

///|
pub fn SparsePolynomial::op_get[A : Semiring + Eq](
  self : SparsePolynomial[A],
  exp_vec : ExpVec
) -> A? {
  self.terms[exp_vec]
}

///|
fn SparsePolynomial::op_set[A : Semiring + Eq](
  self : SparsePolynomial[A],
  exp_vec : ExpVec,
  coefficient : A
) -> Unit {
  self.terms[exp_vec] = coefficient
}

///|
fn SparsePolynomial::set[A : Semiring + Eq](
  self : SparsePolynomial[A],
  term : (ExpVec, A)
) -> Unit {
  let (key, val) = term
  self.terms.set(key, val)
}

///|
fn SparsePolynomial::copy_terms[A : Semiring + Eq](
  self : SparsePolynomial[A]
) -> Map[ExpVec, A] {
  let terms_copy : Map[ExpVec, A] = Map::new()
  for x in self.terms {
    terms_copy.set(x.0, x.1)
  }
  terms_copy
}

///|
fn SparsePolynomial::copy[A : Semiring + Eq](
  self : SparsePolynomial[A]
) -> SparsePolynomial[A] {
  let terms = self.copy_terms()
  SparsePolynomial::{ terms, }
}

///|
pub fn SparsePolynomial::from_array[A : Semiring + Eq](
  arr : Array[(ExpVec, A)]
) -> SparsePolynomial[A] {
  let poly = SparsePolynomial::new()
  for term in arr {
    poly.add_term_inplace(term)
  }
  poly
}

///|
pub fn SparsePolynomial::add_term[A : Semiring + Eq](
  self : SparsePolynomial[A],
  term : (ExpVec, A)
) -> SparsePolynomial[A] {
  guard term != (ExpVec::one(), A::zero()) else { return self.copy() }
  if self == SparsePolynomial::zero() {
    self.terms.remove(ExpVec::one())
  }
  guard self.terms.size() == 0 else {
    let res = SparsePolynomial::new()
    res.set(term)
    return res
  }
  let new_terms : Map[ExpVec, A] = Map::new()
  for x in self.terms {
    let (curr_key, curr_val) = x
    if curr_key == term.0 {
      if curr_val + term.1 != A::zero() {
        new_terms.set(curr_key, curr_val + term.1)
      }
    } else {
      new_terms.set(curr_key, curr_val)
    }
  }
  if new_terms.size() > 1 {
    match new_terms.get(ExpVec::one()) {
      Some(x) => if x == A::zero() { new_terms.remove(ExpVec::one()) }
      None => ()
    }
  } else if new_terms.size() == 0 {
    new_terms.set(ExpVec::one(), A::zero())
  }
  let res = SparsePolynomial::{ terms: new_terms }
  res
}

///|
pub fn SparsePolynomial::add_term_inplace[A : Semiring + Eq](
  self : SparsePolynomial[A],
  term : (ExpVec, A)
) -> Unit {
  guard term != (ExpVec::one(), A::zero()) else { return }
  if self == SparsePolynomial::zero() {
    self.terms.remove(ExpVec::one())
  }
  guard self.terms.size() != 0 else { return self.set(term) }
  let val = self.terms.get(term.0)
  match val {
    Some(curr_val) => {
      let mut mark = false
      if curr_val + term.1 == A::zero() {
        mark = true
      } else {
        self.terms.set(term.0, curr_val + term.1)
      }
      if mark {
        self.terms.remove(term.0)
        if self.terms.size() == 0 {
          self.set(([], A::zero()))
        }
      }
    }
    None => self.terms.set(term.0, term.1)
  }
}

///|
pub fn SparsePolynomial::mul_term_inplace[A : Semiring + Eq](
  self : SparsePolynomial[A],
  term : (ExpVec, A)
) -> Unit {
  if self.terms.size() == 1 && self.terms.get([]) == Some(A::zero()) {
    return
  }
  if term.1 == A::zero() || self.terms.size() == 0 {
    self.terms.clear()
    self.terms.set([], A::zero())
  } else if term.0.is_empty() {
    for x in self.terms {
      let (curr_key, curr_val) = x
      self.terms.set(curr_key, curr_val * term.1)
    }
  } else {
    let temp : Map[ExpVec, A] = Map::new()
    for x in self.terms {
      let (curr_key, curr_val) = x
      if curr_val != A::zero() {
        temp.set(curr_key * term.0, curr_val * term.1)
      }
    }
    self.terms.clear()
    for x in temp {
      let (key, val) = x
      self.terms.set(key, val)
    }
  }
}

///|
pub fn SparsePolynomial::mul_term[A : Semiring + Eq](
  self : SparsePolynomial[A],
  term : (ExpVec, A)
) -> SparsePolynomial[A] {
  if term.1 == A::zero() ||
    self.terms.size() == 0 ||
    (self.terms.size() == 1 && self.terms.get([]) == Some(A::zero())) {
    SparsePolynomial::zero()
  } else if term.0.is_empty() {
    let new_terms : Map[ExpVec, A] = Map::new()
    for x in self.terms {
      let (curr_key, curr_val) = x
      new_terms.set(curr_key, curr_val * term.1)
    }
    { terms: new_terms }
  } else {
    let new_terms : Map[ExpVec, A] = Map::new()
    for x in self.terms {
      let (curr_key, curr_val) = x
      if curr_val != A::zero() {
        new_terms.set(curr_key * term.0, curr_val * term.1)
      }
    }
    { terms: new_terms }
  }
}

///|
pub fn SparsePolynomial::op_add[A : Semiring + Eq](
  self : SparsePolynomial[A],
  other : SparsePolynomial[A]
) -> SparsePolynomial[A] {
  let res : SparsePolynomial[A] = { terms: self.terms }
  for x in other.terms {
    let (key, val) = x
    res.add_term_inplace((key, val))
  }
  res
}

///|
pub fn SparsePolynomial::add_inplace[A : Semiring + Eq](
  self : SparsePolynomial[A],
  other : SparsePolynomial[A]
) -> Unit {
  for x in other.terms {
    let (key, val) = x
    self.add_term_inplace((key, val))
  }
}

///|
pub fn SparsePolynomial::op_mul[A : Semiring + Eq](
  self : SparsePolynomial[A],
  other : SparsePolynomial[A]
) -> SparsePolynomial[A] {
  let l_self = self.terms.size()
  let l_other = other.terms.size()
  let larger = if l_self >= l_other { self } else { other }
  let smaller = if l_self >= l_other { other } else { self }
  let mut res = SparsePolynomial::new()
  let mut fst = true
  for x in larger.terms {
    if fst {
      res = smaller.mul_term(x)
      fst = false
    } else {
      res.add_inplace(smaller.mul_term(x))
    }
  }
  res
}

test "sparse polynomial" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::one(), 1),
    (ExpVec::from_array([1]), 2),
    (ExpVec::from_array([2]), 1),
  ])
  let x_plus_1 = SparsePolynomial::from_array([
    (ExpVec::from_array([1]), 1),
    (ExpVec::one(), 1),
  ])
  assert_eq!(poly, x_plus_1 * x_plus_1)
}
