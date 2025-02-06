///|
type ExpVec Array[Int]

///|
impl Hash for ExpVec with hash(self : ExpVec) -> Int {
  let self_str = self._.to_string()
  self_str.hash()
}

///|
impl Hash for ExpVec with hash_combine(self : ExpVec, hasher : Hasher) -> Unit {
  let self_str = self._.to_string()
  self_str.hash_combine(hasher)
}

///|
pub fn ExpVec::new(
  exp_vec~ : Array[Int] = [],
  arity~ : Int = exp_vec.length()
) -> ExpVec {
  if arity >= exp_vec.length() {
    exp_vec
  } else if arity < exp_vec.length() && arity > 0 {
    let (head, _) = exp_vec.split_at(arity)
    head
  } else {
    panic()
  }
}

///|
pub fn ExpVec::length(self : ExpVec) -> Int {
  self._.length()
}

///|
fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  let (head, tail) = self._.split_at(i)
  (head, tail)
}

///|
pub fn ExpVec::op_get(self : ExpVec, i : Int) -> Int {
  self._[i]
}

///|
fn ExpVec::pop(self : ExpVec) -> Int? {
  self._.pop()
}

///|
pub fn ExpVec::shrink(self : ExpVec) -> Unit {
  for i = self.length() - 1; self[i] == 0; i = i + 1 {
    let _ = self.pop()

  }
}

///|
pub fn op_set(self : ExpVec, i : Int, v : Int) -> Unit {
  self._[i] = v
}

///|
pub fn ExpVec::op_equal(self : ExpVec, other : ExpVec) -> Bool {
  self.shrink()
  other.shrink()
  self == other
}

///|
pub fn ExpVec::is_empty(self : ExpVec) -> Bool {
  self._.is_empty()
}

///|
fn ExpVec::copy(self : ExpVec) -> ExpVec {
  let exp_vec = self._.copy()
  exp_vec
}

///|
fn ExpVec::op_add(self : ExpVec, other : ExpVec) -> ExpVec {
  if self.length() >= other.length() {
    let res = self.copy()
    for i in 0..<other.length() {
      res[i] = res[i] + other[i]
    }
    res.shrink()
    res
  } else {
    let res = other.copy()
    for i in 0..<self.length() {
      res[i] = res[i] + self[i]
    }
    res.shrink()
    res
  }
}

///|
struct SparsePolynomial[V] {
  terms : Map[ExpVec, V]
}

///|
pub fn SparsePolynomial::new[V : Semiring]() -> SparsePolynomial[V] {
  let terms : Map[ExpVec, V] = Map::new()
  terms.set([], V::zero())
  { terms, }
}

///|
pub fn SparsePolynomial::add_term[V : Semiring](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  let val = self.terms.get(exp_vec)
  match val {
    Some(curr_val) => self.terms.set(exp_vec, curr_val + coefficient)
    None => self.terms.set(exp_vec, coefficient)
  }
}

///|
pub fn SparsePolynomial::mul_term[V : Semiring](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  for x in self.terms {
    let (curr_key, curr_val) = x
    if not(exp_vec.is_empty()) {
      self.terms.remove(curr_key)
    }
    self.terms.set(curr_key + exp_vec, curr_val * coefficient)
  }
}
