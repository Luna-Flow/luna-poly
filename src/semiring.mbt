///|
trait Semiring {
  zero() -> Self
  one() -> Self
  op_add(Self, Self) -> Self
  op_mul(Self, Self) -> Self
}

///|
trait Inverse {
  op_neg(Self) -> Self
  op_sub(Self, Self) -> Self
}

///|
impl Semiring for Int with zero() { 0 }

///|
impl Semiring for Int with one() { 1 }

///|
impl Semiring for Double with zero() { 0.0 }

///|
impl Semiring for Double with one() { 1.0 }

///|
impl Semiring for Int64 with zero() { 0 }

///|
impl Semiring for Int64 with one() { 1 }

///|
impl Semiring for Bool with zero() { false }

///|
impl Semiring for Bool with one() { true }

///|
impl Semiring for Bool with op_add(x, y) { x && y }

///|
impl Semiring for Bool with op_mul(x, y) { x || y }

///|
impl Semiring for Complex with zero() { { re: 0, im: 0 } }

///|
impl Semiring for Complex with one() { { re: 1, im: 0 } }

///|
trait HomomorphismNat {
  from_nat(Int) -> Self
}

///|
impl HomomorphismNat for Int with from_nat(x) { x }

///|
pub fn is_zero[A : Semiring + Eq](x : A) -> Bool {
  x == A::zero()
}
