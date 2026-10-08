///|
using @lg {trait Zero, trait AddMonoid}

///|
test "canonicalization is idempotent" {
  fn property(coefficients : Array[Int]) -> Bool {
    let once = DensePolynomial::from_coefficients(coefficients)
    let twice = DensePolynomial::from_coefficients(once.to_coefficients())
    once == twice
  }
  @qc.quick_check_fn(property)
}

///|
test "dense addition has a zero identity" {
  fn property(coefficients : Array[Int]) -> Bool {
    let polynomial = DensePolynomial::from_coefficients(coefficients)
    let zero : DensePolynomial[Int] = DensePolynomial::zero()
    polynomial + zero == polynomial && zero + polynomial == polynomial
  }
  @qc.quick_check_fn(property)
}

///|
test "karatsuba agrees with canonical multiplication above threshold" {
  let left = DensePolynomial::from_coefficients(
    Array::makei(40, fn(i) { i % 7 - 3 }),
  )
  let right = DensePolynomial::from_coefficients(
    Array::makei(45, fn(i) { i % 5 - 2 }),
  )
  assert_true(left.karatsuba(right) == left * right)
}

///|
priv struct AddOnly {
  value : Int
} derive(Eq)

///|
fn add_only(value : Int) -> AddOnly {
  { value, }
}

///|
impl Zero for AddOnly with fn zero() {
  add_only(0)
}

///|
impl Add for AddOnly with fn add(self, other) {
  add_only(self.value + other.value)
}

///|
impl AddMonoid for AddOnly

///|
priv struct MulNoOne {
  value : Int
} derive(Eq)

///|
fn mul_no_one(value : Int) -> MulNoOne {
  { value, }
}

///|
impl Zero for MulNoOne with fn zero() {
  mul_no_one(0)
}

///|
impl Add for MulNoOne with fn add(self, other) {
  mul_no_one(self.value + other.value)
}

///|
impl AddMonoid for MulNoOne

///|
impl Mul for MulNoOne with fn mul(self, other) {
  mul_no_one(self.value * other.value)
}

///|
priv struct GroupNoMul {
  value : Int
} derive(Eq)

///|
fn group_no_mul(value : Int) -> GroupNoMul {
  { value, }
}

///|
impl Zero for GroupNoMul with fn zero() {
  group_no_mul(0)
}

///|
impl Add for GroupNoMul with fn add(self, other) {
  group_no_mul(self.value + other.value)
}

///|
impl AddMonoid for GroupNoMul

///|
impl Neg for GroupNoMul with fn neg(self) {
  group_no_mul(-self.value)
}

///|
test "dense constraints accept additive-only coefficients" {
  let p = DensePolynomial::from_coefficients([
    add_only(1),
    add_only(2),
    add_only(0),
  ])
  let q = DensePolynomial::constant(add_only(3))
  assert_true((p + q).to_coefficients() == [add_only(4), add_only(2)])
}

///|
test "multiplication constraints do not require coefficient one" {
  let p = DensePolynomial::from_coefficients([mul_no_one(2), mul_no_one(3)])
  assert_true(
    (p * p).to_coefficients() == [mul_no_one(4), mul_no_one(12), mul_no_one(9)],
  )
  assert_eq(p.eval(mul_no_one(2)).value, 8)
  assert_true(
    p.scale(1, mul_no_one(3)).to_coefficients() ==
    [mul_no_one(0), mul_no_one(6), mul_no_one(9)],
  )
}

///|
test "negative constraints do not require coefficient multiplication" {
  let p = DensePolynomial::from_coefficients([group_no_mul(1), group_no_mul(-2)])
  let q = DensePolynomial::from_coefficients([group_no_mul(3)])
  assert_true((-p).to_coefficients() == [group_no_mul(-1), group_no_mul(2)])
  assert_true((p - q).to_coefficients() == [group_no_mul(-2), group_no_mul(-2)])
}
