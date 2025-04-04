///|
type SparsePolynomial[V] @sorted_map.T[ExpVec, V] derive(Eq)

///|
pub impl[V : Eq + Show + Semiring] Show for SparsePolynomial[V] with output(
  self,
  logger
) {
  let mut first = true
  for exp_vec, coefficient in self {
    if not(first) {
      logger.write_string(" + ")
    }
    if exp_vec.is_one() {
      logger.write_object(coefficient)
    } else {
      if coefficient != V::one() {
        logger.write_object(coefficient)
      }
      logger.write_object(exp_vec)
    }
    first = false
  }
  if first {
    logger.write_object(V::zero())
  }
}

///|
test "show" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  assert_eq!(poly.to_string(), "xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵")
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 0),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  assert_eq!(poly_2.to_string(), "2x²y³z⁴ + 3x³y⁴z⁵")
  let poly_3 = SparsePolynomial::from_array([(ExpVec::from_array([]), 0)])
  assert_eq!(poly_3.to_string(), "0")
}

///|
pub fn op_set[V](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  self._[exp_vec] = coefficient
}

///|
pub fn op_get[V](self : SparsePolynomial[V], exp_vec : ExpVec) -> V? {
  self.get(exp_vec)
}

///|
pub fn SparsePolynomial::new[V]() -> SparsePolynomial[V] {
  @sorted_map.new()
}

///|
pub fn SparsePolynomial::from_array[V : Eq + AddMonoid](
  arr : Array[(ExpVec, V)]
) -> SparsePolynomial[V] {
  let poly = SparsePolynomial::new()
  for x in arr {
    let (exp_vec, coefficient) = x
    poly.add_term_inplace(exp_vec, coefficient)
  }
  poly
}

///|
pub fn SparsePolynomial::remove[V](
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> Unit {
  self._.remove(exp_vec)
}

///|
pub fn SparsePolynomial::get[V](
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> V? {
  self._.get(exp_vec)
}

///|
pub fn SparsePolynomial::contains[V](
  self : SparsePolynomial[V],
  exp_vec : ExpVec
) -> Bool {
  self._.contains(exp_vec)
}

///|
pub fn SparsePolynomial::is_empty[V](self : SparsePolynomial[V]) -> Bool {
  self._.is_empty()
}

///|
pub fn SparsePolynomial::size[V](self : SparsePolynomial[V]) -> Int {
  self._.size()
}

///|
pub fn SparsePolynomial::clear[V](self : SparsePolynomial[V]) -> Unit {
  self._.clear()
}

///|
pub fn SparsePolynomial::each[V](
  self : SparsePolynomial[V],
  f : (ExpVec, V) -> Unit
) -> Unit {
  self._.each(f)
}

///|
pub fn SparsePolynomial::eachi[V](
  self : SparsePolynomial[V],
  f : (Int, ExpVec, V) -> Unit
) -> Unit {
  self._.eachi(f)
}

///|
pub fn SparsePolynomial::keys[V](self : SparsePolynomial[V]) -> Array[ExpVec] {
  self._.keys()
}

///|
pub fn SparsePolynomial::values[V](self : SparsePolynomial[V]) -> Array[V] {
  self._.values()
}

///|
pub fn SparsePolynomial::to_array[V](
  self : SparsePolynomial[V]
) -> Array[(ExpVec, V)] {
  self._.to_array()
}

///|
pub fn SparsePolynomial::iter[V](
  self : SparsePolynomial[V]
) -> Iter[(ExpVec, V)] {
  self._.iter()
}

///|
pub fn SparsePolynomial::iter2[V](
  self : SparsePolynomial[V]
) -> Iter2[ExpVec, V] {
  self._.iter2()
}

///|
pub fn SparsePolynomial::from_iter[V : Eq + AddMonoid](
  iter : Iter[(ExpVec, V)]
) -> SparsePolynomial[V] {
  let m = SparsePolynomial::new()
  iter.each(fn(e) {
    let (exp_vec, coefficient) = e
    m.add_term_inplace(exp_vec.copy(), coefficient)
  })
  m
}

///|
pub fn SparsePolynomial::range[V](
  self : SparsePolynomial[V],
  low : ExpVec,
  hight : ExpVec
) -> Iter2[ExpVec, V] {
  self._.range(low, hight)
}

///|
pub fn SparsePolynomial::copy[V : Eq + AddMonoid](
  self : SparsePolynomial[V]
) -> SparsePolynomial[V] {
  SparsePolynomial::from_iter(self.iter())
}

///|
pub impl[V : Zero] Zero for SparsePolynomial[V] with zero() -> SparsePolynomial[
  V,
] {
  SparsePolynomial::new()._..add(ExpVec::one(), V::zero())
}

///|
pub fn SparsePolynomial::add_term_inplace[V : Eq + AddMonoid](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  guard coefficient != V::zero() else { return }
  if self._[exp_vec] is None {
    self._.add(exp_vec, coefficient)
  } else {
    let new_coe = self._[exp_vec].unwrap() + coefficient
    guard new_coe != V::zero() else { self._.remove(exp_vec) }
    self._[exp_vec] = new_coe
    let size = self.size()
    if size == 0 {
      self._.add(ExpVec::one(), V::zero())
    }
  }
}

///|
pub fn SparsePolynomial::add_term[V : Eq + AddMonoid](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> SparsePolynomial[V] {
  let new_poly = self.copy()
  new_poly.add_term_inplace(exp_vec, coefficient)
  new_poly
}

///|
/// this is inplace version of op_add
pub fn SparsePolynomial::add[V : Eq + AddMonoid](
  self : SparsePolynomial[V],
  other : SparsePolynomial[V]
) -> Unit {
  for x in other {
    let (exp_vec, coefficient) = x
    self.add_term_inplace(exp_vec, coefficient)
  }
}

///|
pub impl[V : Eq + AddMonoid] Add for SparsePolynomial[V] with op_add(
  self,
  other
) {
  let res = SparsePolynomial::new()
  for x in self {
    let (exp_vec, coefficient) = x
    res.add_term_inplace(exp_vec, coefficient)
  }
  for x in other {
    let (exp_vec, coefficient) = x
    res.add_term_inplace(exp_vec, coefficient)
  }
  res
}

///|
pub fn SparsePolynomial::mul_term_inplace[V : Eq + Semiring](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> Unit {
  if coefficient == V::zero() || self.size() == 0 {
    self.clear()
    self._.add(ExpVec::one(), V::zero())
  } else if exp_vec.is_one() && coefficient == V::one() {
    return
  } else if exp_vec.is_one() {
    self.each(fn(iter_exp_vec, iter_coefficient) {
      self._[iter_exp_vec] = iter_coefficient * coefficient
    })
  } else if coefficient == V::one() {
    let other = self.copy()
    self.clear()
    for x in other {
      let (old_exp_vec, old_coefficient) = x
      self._.add(old_exp_vec * exp_vec, old_coefficient)
    }
  } else {
    let other = self.copy()
    self.clear()
    for x in other {
      let (old_exp_vec, old_coefficient) = x
      self._.add(old_exp_vec * exp_vec, old_coefficient * coefficient)
    }
  }
}

///|
pub fn SparsePolynomial::mul_term[V : Eq + Semiring](
  self : SparsePolynomial[V],
  exp_vec : ExpVec,
  coefficient : V
) -> SparsePolynomial[V] {
  if coefficient == V::zero() || self.size() == 0 {
    SparsePolynomial::new()._..add(ExpVec::one(), V::zero())
  } else if exp_vec.is_one() && coefficient == V::one() {
    return self.copy()
  } else if exp_vec.is_one() {
    let res = self.copy()
    res..each(fn(iter_exp_vec, iter_coefficient) {
      res._[iter_exp_vec] = iter_coefficient * coefficient
    })
  } else if coefficient == V::one() {
    let res = SparsePolynomial::new()
    for x in self {
      let (old_exp_vec, old_coefficient) = x
      res._.add(old_exp_vec * exp_vec, old_coefficient)
    }
    res
  } else {
    let res = SparsePolynomial::new()
    for x in self {
      let (old_exp_vec, old_coefficient) = x
      res._.add(old_exp_vec * exp_vec, old_coefficient * coefficient)
    }
    res
  }
}

///|
pub impl[A : Semiring + Eq] Mul for SparsePolynomial[A] with op_mul(self, other) {
  let l_self = self.size()
  let l_other = other.size()
  let larger = if l_self >= l_other { self } else { other }
  let smaller = if l_self >= l_other { other } else { self }
  let mut res = SparsePolynomial::new()
  let mut fst = true
  for x in larger {
    if fst {
      res = smaller.mul_term(x.0, x.1)
      fst = false
    } else {
      res.add(smaller.mul_term(x.0, x.1))
    }
  }
  res
}

///|
fn qpow[V : Eq + Semiring](b : V, e : UInt) -> V {
  if b == V::zero() {
    return V::zero()
  } else if e == 0 {
    return V::one()
  } else if e == 1 {
    return b
  } else {
    let half = qpow(b, e / 2)
    if e % 2 == 0 {
      return half * half
    } else {
      return half * half * b
    }
  }
}

///|
pub fn SparsePolynomial::eval_at[V : Show + Eq + Semiring](
  self : SparsePolynomial[V],
  var_index : Int,
  val : V
) -> SparsePolynomial[V] {
  if val == V::zero() {
    return SparsePolynomial::zero()
  }
  let calc_coe = fn(t : (ExpVec, V), vi : Int, v : V) -> (ExpVec, V) {
    let (ev, c) = t
    if ev.is_one() || vi >= ev.length() {
      return (ev, c)
    }
    let exp = ev[vi]
    let mul_c = qpow(v, exp)
    if mul_c == V::one() {
      let ev_copy = ev.copy()
      ev_copy[vi] = 0
      ev_copy.shrink()
      return (ev_copy, c)
    } else if mul_c == V::zero() {
      return (ExpVec::one(), V::zero())
    } else {
      let ev_copy = ev.copy()
      ev_copy[vi] = 0
      ev_copy.shrink()
      return (ev_copy, c * mul_c)
    }
  }
  let res = SparsePolynomial::new()
  for x in self {
    let (ev_x, c_x) = x
    let (ev, c) = calc_coe((ev_x, c_x), var_index, val)
    res.add_term_inplace(ev, c)
  }
  res
}

///|
pub fn SparsePolynomial::eval_at_many[V : Show + Eq + Semiring](
  self : SparsePolynomial[V],
  vars : Array[(Int, V)]
) -> SparsePolynomial[V] {
  if vars.length() == 1 {
    return SparsePolynomial::eval_at(self, vars[0].0, vars[0].1)
  }
  let calc_coe = fn(t : (ExpVec, V), vars : Array[(Int, V)]) -> (ExpVec, V) {
    let (ev, c) = t
    if ev.is_one() {
      return (ev, c)
    }
    let mut mul_c_all = V::one()
    let ev_copy = ev.copy()
    for var in vars {
      let (vi, v) = var
      if vi >= ev.length() {
        continue
      }
      let exp = ev[vi]
      mul_c_all = mul_c_all * qpow(v, exp)
      ev_copy[vi] = 0
    }
    ev_copy.shrink()
    if mul_c_all == V::one() {
      return (ev_copy, c)
    } else if mul_c_all == V::zero() {
      return (ExpVec::one(), V::zero())
    } else {
      return (ev_copy, c * mul_c_all)
    }
  }
  let res = SparsePolynomial::new()
  for x in self {
    let (ev_x, c_x) = x
    let (ev, c) = calc_coe((ev_x, c_x), vars)
    res.add_term_inplace(ev, c)
  }
  res
}

///|
pub fn SparsePolynomial::eval[V : Eq + Semiring](
  self : SparsePolynomial[V],
  vars : Array[V]
) -> V {
  let calc_coe = fn(t : (ExpVec, V), vars : Array[V]) -> V {
    let (ev, c) = t
    let mut mul_c_all = V::one()
    if ev.is_one() {
      return c
    }
    for i in 0..<vars.length() {
      if i >= ev.length() {
        break
      }
      let exp = ev[i]
      mul_c_all = mul_c_all * qpow(vars[i], exp)
    }
    return mul_c_all * c
  }
  let mut sum = V::zero()
  for x in self {
    sum = sum + calc_coe(x, vars)
  }
  sum
}

///|
pub fn SparsePolynomial::replace_const[A : Semiring + Eq](
  self : SparsePolynomial[A],
  index : Int,
  coeff : A
) -> SparsePolynomial[A] {
  let res = self.copy()
  for expvec, coef in res {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    let new_coef = loop expvec[index], coef {
      0, coef => break coef
      expon, coef => continue expon - 1, coef * coeff
    }
    expvec[index] = 0
    res[expvec] = new_coef
  }
  res
}

///|
/// use index2 replace index1
pub fn SparsePolynomial::replace_variable[A : Semiring + Eq](
  self : SparsePolynomial[A],
  index1 : Int,
  index2 : Int
) -> SparsePolynomial[A] {
  let res = self.copy()
  for expvec, _ in res {
    guard index1 >= 0 &&
      index1 < expvec.length() &&
      index2 > 0 &&
      index2 < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    expvec[index2] = expvec[index1] + expvec[index2]
    expvec[index1] = 0
  }
  res
}

///|
pub fn SparsePolynomial::replace_term[A : Semiring + Eq](
  self : SparsePolynomial[A],
  index : Int,
  exp : ExpVec,
  coeff : A
) -> SparsePolynomial[A] {
  let res = SparsePolynomial::new()
  for expvec, coef in self {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    let expon = expvec[index]
    let copy_expvec = expvec.copy()
    copy_expvec[index] = 0
    let new_coeff = loop expon, coef {
      0, coef => break coef
      exp, coef => continue exp - 1, coef * coeff
    }
    let temp_exp = exp.copy()
    /// ExpVec doesn't have iter and iter2
    for i = 0; i < exp.length(); i = i + 1 {
      temp_exp[i] *= expon
    }
    let new_expvec = copy_expvec * temp_exp
    res.add_term_inplace(new_expvec, new_coeff)
  }
  res
}

///|
pub fn SparsePolynomial::replace_poly[A : Semiring + Eq](
  self : SparsePolynomial[A],
  index : Int,
  other : SparsePolynomial[A]
) -> SparsePolynomial[A] {
  let res = SparsePolynomial::new()
  for expvec, coeff in self {
    guard index >= 0 && index < expvec.length() else {
      abort("index out of bound in term:\{expvec.to_string()}")
    }
    if expvec[index] != 0 {
      let temp_sparse = other.pow(expvec[index])
      let copy_expvec = expvec.copy()
      copy_expvec[index] = 0
      for temp_expvec, temp_coeff in temp_sparse {
        res.add_term_inplace(copy_expvec * temp_expvec, coeff * temp_coeff)
      }
    }
  }
  res
}

///|
pub fn SparsePolynomial::pow[A : Semiring + Eq](
  self : SparsePolynomial[A],
  expon : UInt
) -> SparsePolynomial[A] {
  guard expon > 1 else { self }
  let temp = self.pow(expon / 2)
  if expon % 2 == 0 {
    temp * temp
  } else {
    temp * temp * self
  }
}

///|
test "pow" {
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([0, 0, 1]), 1),
    (ExpVec::from_array([0, 1, 0]), 1),
  ])
  assert_eq!(
    poly_2.pow(10).to_string(),
    "y¹⁰ + z¹⁰ + 10yz⁹ + 45y²z⁸ + 120y³z⁷ + 210y⁴z⁶ + 252y⁵z⁵ + 210y⁶z⁴ + 120y⁷z³ + 45y⁸z² + 10y⁹z",
  )
}

///|
test "const_replace" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  //poly = xy²z³ + 2x²y³z⁴ + 3x³y⁴z⁵
  println(poly.to_string())
  //replace_const (z = 2)
  assert_eq!(
    poly.replace_const(2, 2).to_string(),
    "8xy² + 32x²y³ + 96x³y⁴",
  )
  //replace_variable (y = z)
  assert_eq!(
    poly.replace_variable(1, 2).to_string(),
    "xz⁵ + 2x²z⁷ + 3x³z⁹",
  )
  //replace_term (z = x²y²z²)
  let expvec = ExpVec::from_array([2, 2, 2])
  assert_eq!(
    poly.replace_term(2, expvec, 1).to_string(),
    "x⁷y⁸z⁶ + 2x¹⁰y¹¹z⁸ + 3x¹³y¹⁴z¹⁰",
  )
  //replace_poly (x = z + y)
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([0, 0, 1]), 1),
    (ExpVec::from_array([0, 1, 0]), 1),
  ])
  let temp_poly = poly.replace_poly(0, poly_2)
  assert_eq!(
    temp_poly.to_string(),
    "y²z⁴ + y³z³ + 2y³z⁶ + 4y⁴z⁵ + 2y⁵z⁴ + 3y⁴z⁸ + 9y⁵z⁷ + 9y⁶z⁶ + 3y⁷z⁵",
  )
}

///|
test "mul" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2, 3]), 1),
    (ExpVec::from_array([2, 3, 4]), 2),
    (ExpVec::from_array([3, 4, 5]), 3),
  ])
  let poly_2 = poly * poly
  assert_eq!(
    poly_2.to_string(),
    "x²y⁴z⁶ + 4x³y⁵z⁷ + 10x⁴y⁶z⁸ + 12x⁵y⁷z⁹ + 9x⁶y⁸z¹⁰",
  )
}

///|
test "eval" {
  let poly = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([1]), 2),
    (ExpVec::from_array([]), 1),
  ])
  assert_eq!(poly.eval([2]), 9)
  inspect!(poly.eval_at(0, 2), content="9")
  inspect!(poly.eval_at_many([(0, 2)]), content="9")
  let poly_2 = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([0, 2]), 1),
  ])
  inspect!(poly_2.eval_at(0, 1), content="1 + y²")
  inspect!(poly_2.eval_at(1, 2), content="4 + x²")
  inspect!(poly_2.eval_at_many([(0, 1), (1, 2)]), content="5")
  assert_eq!(poly_2.eval([1, 2]), 5)
  let poly_3 = SparsePolynomial::from_array([
    (ExpVec::from_array([2]), 1),
    (ExpVec::from_array([0, 2]), -1),
  ])
  inspect!(poly_3.eval_at(0, 1), content="1 + -1y²")
  inspect!(poly_3.eval_at(1, 2), content="-4 + x²")
  inspect!(poly_3.eval_at_many([(0, 1), (1, 2)]), content="-3")
  assert_eq!(poly_3.eval([1, 2]), -3)
  let poly_4 = SparsePolynomial::from_array([
    (ExpVec::from_array([1, 2]), 1),
    (ExpVec::from_array([2, 1]), 1),
  ])
  inspect!(poly_4.eval_at(0, 1), content="y + y²")
  inspect!(poly_4.eval_at(1, 1), content="x + x²")
  inspect!(poly_4.eval_at_many([(0, 2), (1, 3)]), content="30")
  assert_eq!(poly_4.eval([2, 3]), 30)
}
