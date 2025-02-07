///|
trait Monoid {
  zero() -> Self
  op_add(Self, Self) -> Self
}
