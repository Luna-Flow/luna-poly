///| A dense polynomial implementation.
struct Polynomial[V] {
  terms : Array[V]
} derive(Eq, Compare)

///|
impl[A : Show + Eq + Semiring] Show for Polynomial[A] with to_string(self) {
  let mut s = ""
  let mut first = true
  for i in 0..<self.terms.length() {
    let term = self.terms[i]
    if not(is_zero(term)) {
      if not(first) {
        s = s + " + "
      }
      s = s + term.to_string()
      if i > 0 {
        s = s + "x^" + i.to_string()
      }
      first = false
    }
  }
  if first {
    "0"
  } else {
    s
  }
}

///|
impl[A : Show + Eq + Semiring] Show for Polynomial[A] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
fn drop_while_end[A](pred : (A) -> Bool, xs : Array[A]) -> Array[A] {
  let mut i = xs.length() - 1
  while i >= 0 && pred(xs[i]) {
    i -= 1
  }
  xs.split_at(i + 1).0
}

///| Return the leading power and coefficient of the polynomial.
pub fn leading[A](self : Polynomial[A]) -> (Int, A)? {
  if self.terms.is_empty() {
    None
  } else {
    Some((self.terms.length() - 1, self.terms.last().unwrap()))
  }
}

///| Convert an array to a polynomial.
pub fn to_poly[A : Eq + Semiring](arr : Array[A]) -> Polynomial[A] {
  { terms: drop_while_end(is_zero, arr) }
}

///|
impl[A : Eq + Semiring] Zero for Polynomial[A] with zero() {
  { terms: [] }
}

///|
impl[A : Eq + Semiring] One for Polynomial[A] with one() {
  if is_zero(A::one()) {
    { terms: [] }
  } else {
    { terms: [A::one()] }
  }
}

///|
impl[A : Eq + Semiring] Mul for Polynomial[A] with op_mul(xs, ys) {
  let lx = xs.terms.length()
  let ly = ys.terms.length()
  let poly = Array::make(lx + ly - 1, A::zero())
  for i in 0..<lx {
    for j in 0..<ly {
      poly[i + j] = poly[i + j] + xs.terms[i] * ys.terms[j]
    }
  }
  { terms: poly }
}

///|
impl[A : Eq + Semiring] Add for Polynomial[A] with op_add(xs, ys) {
  let lx = xs.terms.length()
  let ly = ys.terms.length()
  let l_max = @math.maximum(lx, ly)
  let l_min = @math.minimum(lx, ly)
  let larger = if ly >= lx { ys } else { xs }
  {
    terms: Array::makei(l_max, fn(i) {
      if i < l_min {
        xs.terms[i] + ys.terms[i]
      } else {
        larger.terms[i]
      }
    }),
  }
}

///| 
pub fn op_sub[A : Eq + Ring](
  self : Polynomial[A],
  other : Polynomial[A]
) -> Polynomial[A] {
  self + -other
}

///|
impl[A : Ring] Neg for Polynomial[A] with op_neg(x) {
  { terms: Array::makei(x.terms.length(), fn(i) { -x.terms[i] }) }
}

///| Return the zero polynomial.
pub fn Polynomial::empty[A : Semiring](cap~ : Int) -> Polynomial[A] {
  { terms: Array::make(cap, A::zero()) }
}

///| Return the length of the polynomial.
pub fn Polynomial::length[A](self : Polynomial[A]) -> Int {
  self.terms.length()
}

///| Create a monomial from a power and a coefficient.
pub fn monomial[A : Eq + Semiring](
  power : Int,
  coefficient : A
) -> Polynomial[A] {
  if is_zero(coefficient) {
    Polynomial::zero()
  } else {
    {
      terms: Array::makei(power + 1, fn(k) {
        if k == power {
          coefficient
        } else {
          A::zero()
        }
      }),
    }
  }
}

///| Evaluate the polynomial at a given point.
pub fn eval[A : Semiring](self : Polynomial[A], init : A) -> A {
  self.substitute(A::op_mul, init~)
}

///|
pub fn substitute[A, B : Semiring](
  self : Polynomial[A],
  f : (B, A) -> B,
  init~ : B
) -> B {
  self.fold(
    fn { (acc, xn), cn => (acc + f(xn, cn), init * xn) },
    init=(B::zero(), B::one()),
  ).0
}

///| Substitute a polynomial's variable with another polynomial.
pub fn substitute_poly[A : Eq + Semiring](
  self : Polynomial[A],
  x : Polynomial[A]
) -> Polynomial[A] {
  self.substitute(fn(poly, x) { scale(poly, 0, x) }, init=x)
}

///| Multiply a polynomial by a monomial
pub fn scale[A : Eq + Semiring](
  self : Polynomial[A],
  power : Int,
  coefficient : A
) -> Polynomial[A] {
  let len = self.length()
  let terms = Array::make(power + len, A::zero())
  for k in 0..<len {
    terms[k + power] = coefficient * self.terms[k]
  }
  to_poly(terms)
}

///| Get the derivative of the polynomial.
pub fn derivative[A : HomomorphismNat + Eq + Semiring](
  self : Polynomial[A]
) -> Polynomial[A] {
  let len = self.length()
  if len == 0 {
    Polynomial::zero()
  } else {
    self.terms[1:].mapi(fn(i, x) { HomomorphismNat::from_nat(i + 1) * x })
    |> to_poly
  }
}

///| Fold over the polynomial.
pub fn fold[A, B](self : Polynomial[A], f : (B, A) -> B, init~ : B) -> B {
  self.terms.fold(f, init~)
}

///| Coefficient `n`.
pub fn coe[A : Eq + Semiring + HomomorphismNat](n : Int) -> Polynomial[A] {
  match n {
    0 => Polynomial::zero()
    n => { terms: [A::from_nat(n)] }
  }
}

///| Variable `x`.
pub fn var[A : Eq + Semiring]() -> Polynomial[A] {
  if is_zero(A::one()) {
    Polynomial::zero()
  } else {
    Polynomial::from_array([A::zero(), A::one()])
  }
}

///| Internal function to create a polynomial from an array, without dropping zeros.
fn Polynomial::from_array[A](terms : Array[A]) -> Polynomial[A] {
  { terms, }
}

///|
test "dense polynomial" {
  let x = var
  let p1 = to_poly([1, 2, 3])
  inspect!(p1, content="1 + 2x^1 + 3x^2")
  let p2 = to_poly([4, 5, 6, 7])
  inspect!(p2, content="4 + 5x^1 + 6x^2 + 7x^3")
  let p5 = to_poly([-1, 0, 2])
  inspect!(p5, content="-1 + 2x^2")
  let p3 = p1 + p2
  inspect!(p3, content="5 + 7x^1 + 9x^2 + 7x^3")
  let p4 = p1 * p2
  inspect!(p4, content="4 + 13x^1 + 28x^2 + 34x^3 + 32x^4 + 21x^5")
  let p5 : Polynomial[Int] = (x() + coe(1)) * (x() + coe(-1))
  inspect!(p5, content="-1 + 1x^2")
}

///|
test "inverse" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([4, 5, 6, 7])
  let p1n = -p1
  inspect!(p1n, content="-1 + -2x^1 + -3x^2")
  let p3 = p1 - p2
  inspect!(p3, content="-3 + -3x^1 + -3x^2 + -7x^3")
}

///|
test "eval" {
  let p1 = to_poly([1, 2, 3])
  inspect!(eval(p1, 2), content="17")
  inspect!(eval(p1, 1), content="6")
}

///|
test "scale" {
  let p1 = to_poly([1, 2, 3])
  let p2 = scale(p1, 2, 3)
  inspect!(p1, content="1 + 2x^1 + 3x^2")
  inspect!(p2, content="3x^2 + 6x^3 + 9x^4")
}

///|
test "substitute polynomial" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([2, 3])
  let p3 = substitute_poly(p1, p2)
  let p4 = to_poly([1])
  let p5 = substitute_poly(p1, p4)
  inspect!(p1, content="1 + 2x^1 + 3x^2")
  inspect!(p2, content="2 + 3x^1")
  inspect!(p3, content="17 + 42x^1 + 27x^2")
  inspect!(p4, content="1")
  inspect!(p5, content="6")
}

///|
test "derivative" {
  let p1 = to_poly([1, 2, 3])
  let p2 = derivative(p1)
  let p3 = derivative(p2)
  inspect!(p1, content="1 + 2x^1 + 3x^2")
  inspect!(p2, content="2 + 6x^1")
  inspect!(p3, content="6")
}
