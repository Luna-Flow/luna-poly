///|
struct ExpVec {
  vec : Array[Int]
  mut degree : Int
}

///|
impl Hash for ExpVec with hash_combine(self : ExpVec, hasher : Hasher) -> Unit {
  let vec = self.vec
  if vec.is_empty() {
    hasher.combine_int(0)
  } else {
    hasher.combine_int(self.degree)
    for x in vec {
      hasher.combine_int(x)
    }
  }
}

///|
test "hash" {
  let exp = ExpVec::from_array([1, 2, 3])
  let exp_r = ExpVec::from_array([3, 2, 1])
  assert_eq!(exp.hash(), -533501922)
  assert_eq!(exp_r.hash(), -1291445456)
}

///|
pub fn ExpVec::length(self : ExpVec) -> Int {
  self.vec.length()
}

///|
fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  let degree = self.degree
  let (head, tail) = self.vec.split_at(i)
  ({ vec: head, degree }, { vec: tail, degree })
}

///|
fn ExpVec::is_empty(self : ExpVec) -> Bool {
  self.vec.length() == 0
}

///|
fn ExpVec::pop(self : ExpVec) -> Int? {
  let res = self.vec.pop()
  match res {
    Some(x) => self.degree = self.degree - x.abs()
    None => ()
  }
  res
}

///|
pub fn ExpVec::op_get(self : ExpVec, i : Int) -> Int {
  self.vec[i]
}

///|
pub fn ExpVec::op_set(self : ExpVec, i : Int, val : Int) -> Unit {
  self.vec[i] = val
  self.degree = @lu.arr_abs_sum(self.vec)
}

///|
fn ExpVec::inverse(self : ExpVec) -> ExpVec {
  { vec: self.vec.map(fn(x : Int) -> Int { -x }), degree: self.degree }
}

///|
impl @lg.Neg for ExpVec with op_neg(self : ExpVec) -> ExpVec {
  self.inverse()
}

///|
fn op_div(self : ExpVec, other : ExpVec) -> ExpVec {
  self * -other
}

///|
impl @lg.One for ExpVec with one() -> ExpVec {
  { vec: [], degree: 0 }
}

///|
impl @lg.Mul for ExpVec with op_mul(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let l_min = @math.minimum(l_self, l_other)
  let larger = if l_self >= l_other { self } else { other }
  let vec : Array[Int] = Array::makei(larger.length(), fn(i) {
    if i < l_min {
      self[i] + other[i]
    } else {
      larger[i]
    }
  })
  { vec, degree: @lu.arr_abs_sum(vec) }
}

///|
impl Show for ExpVec with to_string(self : ExpVec) -> String {
  let mut s = ""
  let alphabet = [
    "x", "y", "z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w",
  ]
  for i in 0..<self.length() {
    if self[i] != 0 {
      let subscript = (i / 26).abs()
      let alphabet_index = i % 26
      let mut subscript_str = ""
      if subscript != 0 {
        subscript_str = "_" + subscript.to_string()
      }
      let exp = if self[i] == 1 {
        ""
      } else if self[i] < 0 {
        "^(" + self[i].to_string() + ")"
      } else {
        "^" + self[i].to_string()
      }
      s = s + alphabet[alphabet_index] + subscript_str + exp
    }
  }
  if s == "" {
    s = "C"
  }
  s
}

///|
impl Show for ExpVec with output(self : ExpVec, logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
impl Compare for ExpVec with compare(self : ExpVec, other : ExpVec) -> Int {
  if self.length() < other.length() {
    -1
  } else if self.length() > other.length() {
    1
  } else if self.degree > other.degree {
    1
  } else if self.degree < other.degree {
    -1
  } else {
    for i in 0..<self.length() {
      if self[i] > other[i] {
        break 1
      }
      if self[i] < other[i] {
        break -1
      }
    } else {
      0
    }
  }
}

///|
fn ExpVec::shrink(self : ExpVec) -> Unit {
  if self.is_empty() {
    return
  }
  for i = self.length() - 1; self[i] == 0 && not(self.is_empty()); i = i + 1 {
    let _ = self.pop()

  }
  self.vec.shrink_to_fit()
}

///|
impl Eq for ExpVec with op_equal(self : ExpVec, other : ExpVec) -> Bool {
  guard self.length() == other.length() && self.degree == other.degree else {
    return false
  }
  self.shrink()
  other.shrink()
  self.vec == other.vec
}

///|
fn ExpVec::new() -> ExpVec {
  ExpVec::one()
}

///|
fn ExpVec::copy(self : ExpVec) -> ExpVec {
  let vec = self.vec.copy()
  let degree = self.degree
  { vec, degree }
}

///|
fn ExpVec::from_array(vec : Array[Int]) -> ExpVec {
  let mut i = vec.length() - 1
  while i >= 0 && vec[i] == 0 {
    i -= 1
  }
  { vec: vec.split_at(i + 1).0, degree: @lu.arr_abs_sum(vec) }
}

///|
test "print" {
  assert_eq!(ExpVec::new().to_string(), "C")
  assert_eq!(
    ExpVec::from_array([3, 1, 4, -2, 0, 5]).to_string(),
    "x^3yz^4a^(-2)c^5",
  )
}
