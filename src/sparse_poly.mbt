///|
enum ExpVec {
  ExpVec(mut x~ : Array[Int])
}

///|
impl Hash for ExpVec with hash(self : ExpVec) -> Int {
  match self {
    ExpVec(_) as self_exp_vec => {
      let self_str = self_exp_vec.x.to_string()
      self_str.hash()
    }
  }
}

///|
impl Hash for ExpVec with hash_combine(self : ExpVec, hasher : Hasher) -> Unit {
  match self {
    ExpVec(_) as self_exp_vec => {
      let self_str = self_exp_vec.x.to_string()
      self_str.hash_combine(hasher)
    }
  }
}

///|
pub fn ExpVec::new(
  exp_vec~ : Array[Int] = [],
  arity~ : Int = exp_vec.length()
) -> ExpVec {
  if arity >= exp_vec.length() {
    ExpVec(x=exp_vec)
  } else if arity < exp_vec.length() && arity > 0 {
    let (head, _) = exp_vec.split_at(arity)
    ExpVec(x=head)
  } else {
    panic()
  }
}

///|
pub fn ExpVec::length(self : ExpVec) -> Int {
  match self {
    ExpVec(x=exp_vec) => exp_vec.length()
  }
}

///|
pub fn ExpVec::split_at(self : ExpVec, i : Int) -> (ExpVec, ExpVec) {
  match self {
    ExpVec(x=exp_vec) => {
      let (head, tail) = exp_vec.split_at(i)
      (ExpVec(x=head), ExpVec(x=tail))
    }
  }
}

///|
pub fn ExpVec::op_get(self : ExpVec, i : Int) -> Int {
  match self {
    ExpVec(_) as self_exp_vec => self_exp_vec.x[i]
  }
}

///|
pub fn ExpVec::shrink(self : ExpVec) -> Unit {
  match self {
    ExpVec(_) as self_exp_vec => {
      let mut shrink_end = self_exp_vec.x.length() - 1
      for i = self_exp_vec.x.length() - 1; self[i] == 0; i = i - 1 {
        shrink_end = i
      }
      let (head, _) = self_exp_vec.x.split_at(shrink_end)
      self_exp_vec.x = head
    }
  }
}

///|
pub fn ExpVec::op_equal(self : ExpVec, other : ExpVec) -> Bool {
  self.shrink()
  other.shrink()
  match self {
    ExpVec(_) as self_exp_vec =>
      match other {
        ExpVec(_) as other_exp_vec => self_exp_vec.x == other_exp_vec.x
      }
  }
}

///|
struct SparsePolynomial[T] {
  terms : Map[ExpVec, T]
} derive(Eq)
