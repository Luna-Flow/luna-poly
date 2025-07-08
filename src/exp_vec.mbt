///|
struct ExpVec {
  vec : Array[UInt]
  mut degree : UInt
}

///|
impl @quickcheck.Arbitrary for ExpVec with arbitrary(size, rs) {
  @qc.Gen::spawn().fmap(ExpVec::from_array).run(size, rs)
}

///|
test "arbitrary" {
  let gen : @qc.Gen[ExpVec] = @qc.Gen::spawn()
  inspect(
    gen.samples(size=10),
    content="[ab²c², a², zab³cd, 1, c, 1, za²c³d², za²c⁴d⁴e², z, z]",
  )
}

///|
impl Hash for ExpVec with hash_combine(self : ExpVec, hasher : Hasher) -> Unit {
  let vec = self.vec
  if vec.is_empty() {
    hasher.combine_uint(0)
  } else {
    hasher.combine_uint(self.degree)
    for x in vec {
      hasher.combine_uint(x)
    }
  }
}

///|
test "prop hash non-conflict" {
  let m = Map::new()
  let g : @qc.Gen[ExpVec] = @qc.Gen::spawn()
  for sample in g.samples(size=1999) {
    let hashed = sample.hash()
    match m.get(hashed) {
      Some((x : ExpVec)) => assert_eq(sample.vec, x.vec)
      None => m[hashed] = sample
    }
  }
}

///|
test "hash" {
  let exp = ExpVec::from_array([1, 2, 3])
  let exp_r = ExpVec::from_array([3, 2, 1])
  assert_eq(exp.hash(), -533501922)
  assert_eq(exp_r.hash(), -1291445456)
}

///|
pub fn ExpVec::length(self : ExpVec) -> Int {
  self.vec.length()
}

///|
fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  let degree = self.degree
  let (head, tail) = self.vec.split_at(i)
  let l_d = head.fold(init=0U, UInt::op_add)
  ({ vec: head, degree: l_d }, { vec: tail, degree: degree - l_d })
}

///|
test "split monomial" {
  let m = ExpVec::from_array([1, 2, 3])
  let (head, tail) = m.split_at(2)
  assert_eq(head.vec, [1, 2])
  assert_eq(tail.vec, [3])
  assert_eq(head.degree, 3)
  assert_eq(tail.degree, 3)
}

///|
fn ExpVec::is_one(self : ExpVec) -> Bool {
  self.vec.is_empty()
}

///|
fn ExpVec::pop(self : ExpVec) -> UInt? {
  let res = self.vec.pop()
  if res is Some(x) {
    self.degree = self.degree - x
  }
  res
}

///|
pub fn ExpVec::op_get(self : ExpVec, i : Int) -> UInt {
  self.vec[i]
}

///|
pub fn ExpVec::op_set(self : ExpVec, i : Int, val : UInt) -> Unit {
  let old = self.vec[i]
  self.vec[i] = val
  self.degree = self.degree - old + val
}

///|
impl One for ExpVec with one() -> ExpVec {
  { vec: [], degree: 0 }
}

///|
impl Mul for ExpVec with op_mul(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let l_min = @math.minimum(l_self, l_other)
  let larger = if l_self >= l_other { self } else { other }
  let mut degree : UInt = 0
  let vec : Array[UInt] = Array::makei(larger.length(), fn(i) {
    let d = if i < l_min { self[i] + other[i] } else { larger[i] }
    degree += d
    d
  })
  { vec, degree }
}

///|
impl Div for ExpVec with op_div(self : ExpVec, other : ExpVec) -> ExpVec {
  let l_self = self.length()
  let l_other = other.length()
  let monus = fn(x : UInt, y) { if x <= y { 0U } else { x - y } }
  if l_self > l_other {
    let vec = Array::makei(l_self, fn(i) {
      if i < l_other {
        monus(self[i], other[i])
      } else {
        self[i]
      }
    })
    { vec, degree: self.degree - other.degree }
  } else {
    let mut degree = self.degree
    let vec = Array::makei(l_self, fn(i) {
      degree = monus(degree, other[i])
      monus(self[i], other[i])
    })
    { vec, degree }
  }
}

///|
test "division" {
  let m1 = ExpVec::from_array([4, 5, 3])
  let m2 = ExpVec::from_array([1, 2, 3])
  let m3 = ExpVec::from_array([3, 3, 2, 1])
  inspect(m1 / m2, content="x³y³")
  inspect(m2 / m1, content="1")
  inspect(m1 / m3, content="xy²z")
  inspect(m3 / m2, content="x²ya")
  inspect((m1 / m2).degree, content="6")
  inspect((m2 / m1).degree, content="0")
  inspect((m1 / m3).degree, content="4")
  inspect((m3 / m2).degree, content="3")
}

///|
impl Show for ExpVec with output(self : ExpVec, logger) -> Unit {
  let write_superscript = {
    let num_superscript = [
      '\u2070', '\u00b9', '\u00b2', '\u00b3', '\u2074', '\u2075', '\u2076', '\u2077',
      '\u2078', '\u2079',
    ]
    let minus_superscript = '\u207b'
    fn(num : UInt) -> Unit {
      for c in num.to_string() {
        if c == '-' {
          logger.write_char(minus_superscript)
        } else {
          let index = c.to_int() - '0'.to_int()
          logger.write_char(num_superscript[index])
        }
      }
    }
  }
  let write_subscript = {
    let num_subscript = [
      '\u2080', '\u2081', '\u2082', '\u2083', '\u2084', '\u2085', '\u2086', '\u2087',
      '\u2088', '\u2089',
    ]
    fn(num : Int) -> Unit {
      for c in num.to_string() {
        let index = c.to_int() - '0'.to_int()
        logger.write_char(num_subscript[index])
      }
    }
  }
  let alphabet = [
    'x', 'y', 'z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm',
    'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w',
  ]
  let mut empty = true
  for i, x in self.vec {
    if x != 0 {
      empty = false
      let alphabet_index = i % 26
      logger.write_char(alphabet[alphabet_index])
      let subscript = (i / 26).abs()
      if subscript != 0 {
        write_subscript(subscript)
      }
      if x != 1 {
        write_superscript(x)
      }
    }
  }
  if empty {
    logger.write_char('1')
  }
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
test "ordering exclusive" {
  fn exclusive(ab : (ExpVec, ExpVec)) -> Bool {
    let (a, b) = ab
    match (a > b, a == b, a < b) {
      (true, false, false) | (false, false, true) | (false, true, false) => true
      _ => false
    }
  }

  @qc.quick_check(@qc.Arrow(exclusive) |> @qc.with_max_success(1000))
}

///|
test "1 <= u" {
  fn one_leq_any(a : ExpVec) -> Bool {
    let one = ExpVec::one()
    one <= a
  }

  @qc.quick_check(@qc.Arrow(one_leq_any) |> @qc.with_max_success(1000))
}

///|
fn ExpVec::shrink(self : ExpVec) -> Unit {
  if not(self.is_one()) {
    for i = self.length() - 1; not(self.is_one()) && self[i] == 0; i = i - 1 {
      let _ = self.pop()

    }
    self.vec.shrink_to_fit()
  }
}

///|
impl Eq for ExpVec with op_equal(self : ExpVec, other : ExpVec) -> Bool {
  guard self.length() == other.length() && self.degree == other.degree else {
    false
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
fn ExpVec::from_array(vec : Array[UInt]) -> ExpVec {
  let mut i = vec.length() - 1
  while i >= 0 && vec[i] == 0 {
    i -= 1
  }
  { vec: vec.split_at(i + 1).0, degree: vec.fold(init=0U, UInt::op_add) }
}

///|
test "show" {
  assert_eq(ExpVec::from_array([2025]).to_string(), "x²⁰²⁵")
  assert_eq(ExpVec::from_array([1, 0, 0]).to_string(), "x")
  assert_eq(ExpVec::from_array([0]).to_string(), "1")
}
