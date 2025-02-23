///|
trait HomomorphismNat {
  from_nat(Int) -> Self
}

///|
impl HomomorphismNat for Int with from_nat(x) {
  x
}

///|
pub fn is_zero[A : @luna_generic.Semiring + Eq](x : A) -> Bool {
  x == A::zero()
}
