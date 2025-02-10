// ///|
// struct SparsePolynomial[V] {
//   terms : Map[ExpVec, V]
// } derive(Eq)

// ///|
// impl[A : Show + Eq + Semiring] Show for SparsePolynomial[A] with to_string(self) {
//   let mut s = ""
//   let mut first = true
//   for x in self.terms {
//     let (curr_key, curr_val) = x
//     if curr_val != A::zero() {
//       if not(first) {
//         s = s + " + "
//       }
//       s = s + curr_val.to_string()
//       s = s + "*" + curr_key.to_string()
//       first = false
//     }
//   }
//   if first {
//     "0"
//   } else {
//     s
//   }
// }

// ///|
// impl[A : Show + Eq + Semiring] Show for SparsePolynomial[A] with output(
//   self,
//   logger
// ) {
//   logger.write_string(self.to_string())
// }

// ///|
// impl[A : Eq + Semiring] Semiring for SparsePolynomial[A] with one() -> SparsePolynomial[
//   A,
// ] {
//   let terms : Map[ExpVec, A] = Map::new()
//   terms.set([], A::one())
//   { terms, }
// }

// ///|
// impl[A : Eq + Semiring] Semiring for SparsePolynomial[A] with zero() -> SparsePolynomial[
//   A,
// ] {
//   let terms : Map[ExpVec, A] = Map::new()
//   terms.set([], A::zero())
//   { terms, }
// }

// ///|
// pub fn SparsePolynomial::new[A : Semiring + Eq]() -> SparsePolynomial[A] {
//   SparsePolynomial::{ terms: Map::new() }
// }

// ///|
// pub fn SparsePolynomial::size[A : Semiring + Eq](
//   self : SparsePolynomial[A]
// ) -> Int {
//   self.terms.size()
// }

// ///|
// pub fn SparsePolynomial::op_get[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   exp_vec : ExpVec
// ) -> A? {
//   self.terms[exp_vec]
// }

// ///|
// fn SparsePolynomial::op_set[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   exp_vec : ExpVec,
//   coefficient : A
// ) -> Unit {
//   self.terms[exp_vec] = coefficient
// }

// ///|
// fn SparsePolynomial::set[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   term : Term[A]
// ) -> Unit {
//   self.terms.set(term._.0, term._.1)
// }

// ///|
// fn SparsePolynomial::copy_terms[A : Semiring + Eq](
//   self : SparsePolynomial[A]
// ) -> Map[ExpVec, A] {
//   let terms_copy : Map[ExpVec, A] = Map::new()
//   for x in self.terms {
//     terms_copy.set(x.0, x.1)
//   }
//   terms_copy
// }

// ///|
// fn SparsePolynomial::copy[A : Semiring + Eq](
//   self : SparsePolynomial[A]
// ) -> SparsePolynomial[A] {
//   let terms = self.copy_terms()
//   SparsePolynomial::{ terms, }
// }

// ///|
// pub fn SparsePolynomial::from_array[A : Semiring + Eq](
//   arr : Array[Term[A]]
// ) -> SparsePolynomial[A] {
//   let poly = SparsePolynomial::new()
//   for term in arr {
//     poly.add_term_inplace(term)
//   }
//   poly
// }

// ///|
// pub fn SparsePolynomial::add_term[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   term : Term[A]
// ) -> SparsePolynomial[A] {
//   guard term != Term::zero() else { return self.copy() }
//   if is_zero(self) {
//     self.terms.remove(ExpVec::one())
//   }
//   guard self.size() == 0 else {
//     let new_poly = SparsePolynomial::new()
//     new_poly.set(term)
//     new_poly
//   }
//   let new_poly : SparsePolynomial[A] = SparsePolynomial::new()
//   for x in self.terms {
//     if term.is_like_term(x) {
//       if not(is_zero(x.1 + term.1)) {
//         let new_term = term.combine_like_terms(x)
//         new_poly.set(new_term)
//       } else {
//         new_poly.set(term)
//       }
//     }
//   }
//   if new_poly.size() > 1 {
//     match new_poly.terms.get(ExpVec::one()) {
//       Some(x) => if x == A::zero() { new_poly.terms.remove(ExpVec::one()) }
//       None => ()
//     }
//   } else if new_poly.size() == 0 {
//     new_poly.set(Term::zero())
//   }
//   new_poly
// }

// ///|
// pub fn SparsePolynomial::add_term_inplace[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   term : Term[A]
// ) -> Unit {
//   guard term != (ExpVec::one(), A::zero()) else { return }
//   if self == SparsePolynomial::zero() {
//     self.terms.remove(ExpVec::one())
//   }
//   guard self.size() != 0 else { return self.set(term) }
//   let val = self.terms.get(term.0)
//   match val {
//     Some(curr_val) => {
//       let mut mark = false
//       if is_zero(curr_val + term.1) {
//         mark = true
//       } else {
//         self.set(term.combine_like_terms(Term::pair(term.0, curr_val)))
//       }
//       if mark {
//         self.terms.remove(term.0)
//         if self.size() == 0 {
//           self.set(Term::zero())
//         }
//       }
//     }
//     None => self.set(term)
//   }
// }

// ///|
// pub fn SparsePolynomial::mul_term_inplace[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   term : Term[A]
// ) -> Unit {
//   if self.size() == 1 && self.terms.get(ExpVec::one()) == Some(A::zero()) {
//     return
//   }
//   if term.1 == A::zero() || self.size() == 0 {
//     self.terms.clear()
//     self.set(Term::zero())
//   } else if term.0.is_empty() {
//     for x in self.terms {
//       self.set(term * x)
//     }
//   } else {
//     let temp : Array[Term[A]] = []
//     for x in self.terms {
//       if not(is_zero(x.1)) {
//         temp.push(term * x)
//       }
//     }
//     self.terms.clear()
//     for new_term in temp {
//       self.set(new_term)
//     }
//   }
// }

// ///|
// pub fn SparsePolynomial::mul_term[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   term : Term[A]
// ) -> SparsePolynomial[A] {
//   if term.1 == A::zero() ||
//     self.size() == 0 ||
//     (self.size() == 1 && self.terms.get(ExpVec::one()) == Some(A::zero())) {
//     SparsePolynomial::zero()
//   } else if term.0.is_empty() {
//     let new_poly : SparsePolynomial[A] = SparsePolynomial::new()
//     for x in self.terms {
//       new_poly.set(term * x)
//     }
//     new_poly
//   } else {
//     let new_poly : SparsePolynomial[A] = SparsePolynomial::new()
//     for x in self.terms {
//       if not(is_zero(x.1)) {
//         new_poly.set(term * x)
//       }
//     }
//     new_poly
//   }
// }

// ///|
// pub fn SparsePolynomial::op_add[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   other : SparsePolynomial[A]
// ) -> SparsePolynomial[A] {
//   let res : SparsePolynomial[A] = { terms: self.terms }
//   for x in other.terms {
//     let (key, val) = x
//     res.add_term_inplace((key, val))
//   }
//   res
// }

// ///|
// pub fn SparsePolynomial::add_inplace[A : Semiring + Eq](
//   self : SparsePolynomial[A],
//   other : SparsePolynomial[A]
// ) -> Unit {
//   for x in other.terms {
//     let (key, val) = x
//     self.add_term_inplace((key, val))
//   }
// }

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

// test "sparse polynomial" {
//   let x_fn = fn() -> Term[Int] { Term::pair([1], 1) }
//   let constant = fn(coe) -> Term[Int] { Term::pair(ExpVec::one(), coe) }
//   let one = constant(1)
//   let two = constant(2)
//   let x = x_fn()
//   let x_square = x * x
//   let poly = SparsePolynomial::from_array([one, two * x, x_square])
//   let x_plus_1 = SparsePolynomial::from_array([x, one])
//   assert_eq!(poly, x_plus_1 * x_plus_1)
// }
