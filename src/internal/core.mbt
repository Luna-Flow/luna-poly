///|
pub fn[A : Mul] pow_nat(base : A, exponent : UInt, one~ : A) -> A {
  for state = one, exp = exponent, factor = base {
    if exp == 0 {
      break state
    }
    if exp == 1 {
      break state * factor
    }
    let next_state = if (exp & 1) == 1 { state * factor } else { state }
    continue next_state, exp >> 1, factor * factor
  }
}
