///|
typealias Complex = @luna_complex.Complex

///|
pub(all) type ExpTerm Array[Int] derive(Show)

///|
pub fn ExpTerm::new(
  exp_vec~ : Array[Int] = [],
  arity~ : Int = exp_vec.length()
) -> ExpTerm {
  if arity >= exp_vec.length() {
    return exp_vec
  } else if arity < exp_vec.length() && arity > 0 {
    let (head, _) = exp_vec.split_at(arity)
    head
  } else {
    panic()
  }
}

///|
pub fn ExpTerm::length(self : ExpTerm) -> Int {
  self._.length()
}

///|
pub fn ExpTerm::split_at(self : ExpTerm, i : Int) -> (ExpTerm, ExpTerm) {
  let (v1, v2) = self._.split_at(i)
  (v1, v2)
}

///|
pub fn ExpTerm::op_get(self : ExpTerm, i : Int) -> Int {
  self._[i]
}

///|
pub fn ExpTerm::shrink(self : ExpTerm) -> ExpTerm {
  let mut shrink_end = self.length() - 1
  for i = self.length() - 1; self[i] == 0; i = i - 1 {
    shrink_end = i
  }
  let (head, _) = self.split_at(shrink_end)
  head
}

///|
type Real Double

///|
pub fn op_add(self : Real, other : Real) -> Real {
  self._ + other._
}

///|
pub trait Coefficient {
  op_add(Self, Self) -> Self
  to_complex(Self) -> Complex
  to_real(Self) -> Real
}

///|
impl Coefficient for Complex with to_complex(self : Complex) -> Complex { self }

///|
impl Coefficient for Complex with to_real(self : Complex) -> Real { self.re }

///|
impl Coefficient for Real with to_complex(self : Real) -> Complex {
  Complex::new(self._, 0)
}

///|
impl Coefficient for Real with to_real(self : Real) -> Real { self }
