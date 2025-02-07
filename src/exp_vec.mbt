///|
type ExpVec Array[Int]

///|
impl Monoid for ExpVec with zero() -> ExpVec { [] }

///|
impl Monoid for ExpVec with op_add(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let l_min = @math.minimum(l_self, l_other)
  let larger = if l_self >= l_other { self } else { other }
  let res : ExpVec = Array::makei(larger.length(), fn(i) {
    if i < l_min {
      self[i] + other[i]
    } else {
      larger[i]
    }
  })
  res.shrink()
  res
}

///|
fn ExpVec::new() -> ExpVec {
  ExpVec::zero()
}

///|
fn ExpVec::from_array(exp_vec : Array[Int]) -> ExpVec {
  let mut i = exp_vec.length() - 1
  while i >= 0 && exp_vec[i] == 0 {
    i -= 1
  }
  exp_vec.split_at(i + 1).0
}

///|
fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  let (head, tail) = self._.split_at(i)
  (head, tail)
}

///|
fn ExpVec::shrink(self : ExpVec) -> Unit {
  for i = self.length() - 1; self[i] == 0 && not(self.is_empty()); i = i + 1 {
    let _ = self.pop()

  }
  self._.shrink_to_fit()
}

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
pub fn ExpVec::length(self : ExpVec) -> Int {
  self._.length()
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

///|
pub fn op_set(self : ExpVec, i : Int, v : Int) -> Unit {
  self._[i] = v
}

///|
pub fn ExpVec::op_equal(self : ExpVec, other : ExpVec) -> Bool {
  self.shrink()
  other.shrink()
  self._ == other._
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
fn ExpVec::to_string(self : ExpVec) -> String {
  self._.to_string()
}
