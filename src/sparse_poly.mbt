///|
type SparsePolynomial[V] @sorted_map.T[ExpVec, V] derive(Eq)

///|
pub impl[V : Eq + Show + @lg.Semiring] Show for SparsePolynomial[V] with to_string(
  self
) {
  let mut s = ""
  let mut fst = true
  self.each(fn(exp_vec, coefficient) {
    if not(fst) {
      s += " + "
    }
    if coefficient == V::one() {
      s += exp_vec.to_string()
    } else {
      s += coefficient.to_string() + exp_vec.to_string()
    }
    fst = false
  })
  if s == "" {
    s = "0"
  }
  s
}

///|
pub impl[V : Eq + Show + @lg.Semiring] Show for SparsePolynomial[V] with output(
  self,
  l
) {
  l.write_string(self.to_string())
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
pub fn SparsePolynomial::from_array[V : Eq + @lg.AddMonoid](
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
pub fn SparsePolynomial::from_iter[V : Eq + @lg.AddMonoid](
  iter : Iter[(ExpVec, V)]
) -> SparsePolynomial[V] {
  let m = SparsePolynomial::new()
  iter.each(fn(e) {
    let (exp_vec, coefficient) = e
    m.add_term_inplace(exp_vec, coefficient)
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
pub fn SparsePolynomial::copy[V : Eq + @lg.AddMonoid](
  self : SparsePolynomial[V]
) -> SparsePolynomial[V] {
  SparsePolynomial::from_iter(self.iter())
}

///|
pub impl[V : @lg.Zero] @lg.Zero for SparsePolynomial[V] with zero() -> SparsePolynomial[
  V,
] {
  SparsePolynomial::new()._..add(ExpVec::one(), V::zero())
}

///|
pub fn SparsePolynomial::add_term_inplace[V : Eq + @lg.AddMonoid](
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
pub fn SparsePolynomial::add_term[V : Eq + @lg.AddMonoid](
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
pub fn SparsePolynomial::add[V : Eq + @lg.AddMonoid](
  self : SparsePolynomial[V],
  other : SparsePolynomial[V]
) -> Unit {
  for x in other {
    let (exp_vec, coefficient) = x
    self.add_term_inplace(exp_vec, coefficient)
  }
}

///|
pub impl[V : Eq + @lg.AddMonoid] @lg.Add for SparsePolynomial[V] with op_add(
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
pub fn SparsePolynomial::mul_term_inplace[V : Eq + @lg.Semiring](
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
pub fn SparsePolynomial::mul_term[V : Eq + @lg.Semiring](
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

// ///|
// pub fn SparsePolynomial::op_mul[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   other : SparsePolynomial[A]
// ) -> SparsePolynomial[A] {
//   let l_self = self.size()
//   let l_other = other.size()
//   let larger = if l_self >= l_other { self } else { other }
//   let smaller = if l_self >= l_other { other } else { self }
//   let mut res = SparsePolynomial::new()
//   let mut fst = true
//   for x in larger.terms {
//     if fst {
//       res = smaller.mul_term(x)
//       fst = false
//     } else {
//       res.add_inplace(smaller.mul_term(x))
//     }
//   }
//   res
// }
