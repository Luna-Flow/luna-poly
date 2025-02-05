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
pub fn ExpVec::op_equal(self : ExpVec, other : ExpVec) -> Bool {
  self.shrink()
  other.shrink()
  self == other
}

///|
struct SparsePolynomial[T] {
  terms : Map[ExpVec, T]
} derive(Eq)
