///|
trait HomomorphismNat {
  from_nat(Int) -> Self
}

///|
impl HomomorphismNat for Int with from_nat(x) {
  x
}

///|
pub fn[A : Semiring + Eq] is_zero(x : A) -> Bool {
  x == A::zero()
}
