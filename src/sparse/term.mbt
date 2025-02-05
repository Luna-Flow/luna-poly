///|
typealias Complex = @luna_complex.Complex

///|
pub(all) enum ExpTerm {
  ExpTerm(mut x~ : Array[Int])
}

///|
impl Hash for ExpTerm with hash(self : ExpTerm) -> Int {
  match self {
    ExpTerm(_) as self_exp_term => {
      let self_str = self_exp_term.x.to_string()
      self_str.hash()
    }
  }
}

///|
impl Hash for ExpTerm with hash_combine(self : ExpTerm, hasher : Hasher) -> Unit {
  match self {
    ExpTerm(_) as self_exp_term => {
      let self_str = self_exp_term.x.to_string()
      self_str.hash_combine(hasher)
    }
  }
}

///|
pub fn ExpTerm::new(
  exp_vec~ : Array[Int] = [],
  arity~ : Int = exp_vec.length()
) -> ExpTerm {
  if arity >= exp_vec.length() {
    ExpTerm(x=exp_vec)
  } else if arity < exp_vec.length() && arity > 0 {
    let (head, _) = exp_vec.split_at(arity)
    ExpTerm(x=head)
  } else {
    panic()
  }
}

///|
pub fn ExpTerm::length(self : ExpTerm) -> Int {
  match self {
    ExpTerm(x=exp_vec) => exp_vec.length()
  }
}

///|
pub fn ExpTerm::split_at(self : ExpTerm, i : Int) -> (ExpTerm, ExpTerm) {
  match self {
    ExpTerm(x=exp_vec) => {
      let (head, tail) = exp_vec.split_at(i)
      (ExpTerm(x=head), ExpTerm(x=tail))
    }
  }
}

///|
pub fn ExpTerm::op_get(self : ExpTerm, i : Int) -> Int {
  match self {
    ExpTerm(x=exp_vec) => exp_vec[i]
  }
}

///|
pub fn ExpTerm::shrink(self : ExpTerm) -> Unit {
  let mut shrink_end = self.length() - 1
  for i = self.length() - 1; self[i] == 0; i = i - 1 {
    shrink_end = i
  }
  match self {
    ExpTerm(x=exp_vec) as exp_term => {
      let (head, _) = exp_vec.split_at(shrink_end)
      exp_term.x = head
    }
  }
}

///|
pub fn ExpTerm::op_equal(self : ExpTerm, other : ExpTerm) -> Bool {
  self.shrink()
  other.shrink()
  match self {
    ExpTerm(_) as self_exp_term =>
      match other {
        ExpTerm(_) as other_exp_term => self_exp_term.x == other_exp_term.x
      }
  }
}

///|
type Real Double

///|
pub fn op_add(self : Real, other : Real) -> Real {
  self._ + other._
}

///|
pub fn op_mul(self : Real, other : Real) -> Real {
  self._ * other._
}

///|
pub fn op_equal(self : Real, other : Real) -> Bool {
  self._ == other._
}

///|
pub trait Coefficient {
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
  to_complex(Self) -> Complex
  to_real(Self) -> Real
  to_bool(Self) -> Bool
}

///|
impl Coefficient for Complex with to_bool(self : Complex) -> Bool {
  self.re != 0 || self.im != 0
}

///|
impl Coefficient for Complex with to_complex(self : Complex) -> Complex { self }

///|
impl Coefficient for Complex with to_real(self : Complex) -> Real { self.re }

///|
impl Coefficient for Real with to_bool(self : Real) -> Bool { self != 0 }

///|
impl Coefficient for Real with to_complex(self : Real) -> Complex {
  Complex::new(self._, 0)
}

///|
impl Coefficient for Real with to_real(self : Real) -> Real { self }

///|
impl Coefficient for Bool with to_bool(self : Bool) -> Bool { self }

///|
impl Coefficient for Bool with to_complex(_) -> Complex {
  abort("Cannot convert Bool to Complex")
}

///|
impl Coefficient for Bool with to_real(_) -> Real {
  abort("Cannot convert Bool to Real")
}

///|
impl Coefficient for Bool with op_add(self : Bool, other : Bool) -> Bool {
  self || other
}

///|
impl Coefficient for Bool with op_mul(self : Bool, other : Bool) -> Bool {
  self && other
}
