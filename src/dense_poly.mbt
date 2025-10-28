///|
/// A dense polynomial implementation.
struct Polynomial[V] {
  terms : Array[V]
} derive(Eq, Compare)

///|
impl[A : Show + Eq + Semiring] Show for Polynomial[A] with output(self, logger) {
  guard not(is_zero(self)) else { logger.write_object(A::zero()) }
  let mut first = true
  for i, term in self.terms {
    if not(is_zero(term)) {
      if not(first) {
        logger.write_string(" + ")
      }
      first = false
      logger.write_object(term)
      if i > 0 {
        logger..write_string("x^").write_object(i)
      }
    }
  }
}

///|
fn[A] drwhile_end(pred : (A) -> Bool, xs : Array[A]) -> Array[A] {
  let mut i = xs.length() - 1
  while i >= 0 && pred(xs[i]) {
    i -= 1
  }
  xs.split_at(i + 1).0
}

///|
/// Return the leading term of the polynomial.
pub fn[A] leading_term(self : Polynomial[A]) -> (Int, A)? {
  if self.terms.is_empty() {
    None
  } else {
    Some((self.terms.length() - 1, self.terms.last().unwrap()))
  }
}

///|
/// Return the leading coefficient of the polynomial.
pub fn[A] leading_coefficient(self : Polynomial[A]) -> A? {
  self.leading_term().map(x => x.1)
}

///|
/// Convert an array to a polynomial.
pub fn[A : Eq + Semiring] to_poly(arr : Array[A]) -> Polynomial[A] {
  { terms: drwhile_end(is_zero, arr) }
}

///|
impl[A] Zero for Polynomial[A] with zero() {
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
impl[A : Semiring] Mul for Polynomial[A] with mul(xs, ys) {
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
impl[A : Semiring] Add for Polynomial[A] with add(xs, ys) {
  let lx = xs.terms.length()
  let ly = ys.terms.length()
  let l_max = @cmp.maximum(lx, ly)
  let l_min = @cmp.minimum(lx, ly)
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
impl[A : Ring] Sub for Polynomial[A] with sub(
  self : Polynomial[A],
  other : Polynomial[A],
) -> Polynomial[A] {
  self + -other
}

///|
impl[A : Ring] Neg for Polynomial[A] with neg(x) {
  { terms: Array::makei(x.terms.length(), fn(i) { -x.terms[i] }) }
}

///|
/// Return the zero polynomial.
pub fn[A : Semiring] Polynomial::empty(cap~ : Int) -> Polynomial[A] {
  { terms: Array::make(cap, A::zero()) }
}

///|
/// Return the length of the polynomial.
pub fn[A] Polynomial::length(self : Polynomial[A]) -> Int {
  self.terms.length()
}

///|
/// Create a monomial from a power and a coefficient.
pub fn[A : Eq + Semiring] monomial(
  power : Int,
  coefficient : A,
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

///|
/// Evaluate the polynomial at a given point.
pub fn[A : Semiring] eval(self : Polynomial[A], init : A) -> A {
  self.substitute(A::mul, init~)
}

///|
pub fn[A, B : Semiring] substitute(
  self : Polynomial[A],
  f : (B, A) -> B,
  init~ : B,
) -> B {
  self.fold(
    (a, cn) => {
      let (acc, xn) = a
      (acc + f(xn, cn), init * xn)
    },
    init=(B::zero(), B::one()),
  ).0
}

///|
/// Substitute a polynomial's variable with another polynomial.
pub fn[A : Eq + Semiring] substitute_poly(
  self : Polynomial[A],
  x : Polynomial[A],
) -> Polynomial[A] {
  self.substitute(fn(poly, x) { poly.scale(0, x) }, init=x)
}

///|
/// Multiply a polynomial by a monomial
pub fn[A : Eq + Semiring] scale(
  self : Polynomial[A],
  power : Int,
  coefficient : A,
) -> Polynomial[A] {
  let len = self.length()
  let terms = Array::make(power + len, A::zero())
  for k in 0..<len {
    terms[k + power] = coefficient * self.terms[k]
  }
  to_poly(terms)
}

///|
/// Get the derivative of the polynomial.
pub fn[A : HomomorphismNat + Eq + Semiring] derivative(
  self : Polynomial[A],
) -> Polynomial[A] {
  let len = self.length()
  if len == 0 {
    Polynomial::zero()
  } else {
    self.terms[1:].mapi(fn(i, x) { HomomorphismNat::from_nat(i + 1) * x })
    |> to_poly
  }
}

///|
/// Fold over the polynomial.
pub fn[A, B] fold(self : Polynomial[A], f : (B, A) -> B, init~ : B) -> B {
  self.terms.fold(f, init~)
}

///|
/// Coefficient `n`.
pub fn[A : HomomorphismNat] coe(n : Int) -> Polynomial[A] {
  match n {
    0 => Polynomial::zero()
    n => { terms: [A::from_nat(n)] }
  }
}

///|
/// Variable `x`.
pub fn[A : Eq + Semiring] vari() -> Polynomial[A] {
  if is_zero(A::one()) {
    Polynomial::zero()
  } else {
    Polynomial::from_array([A::zero(), A::one()])
  }
}

///|
/// Internal function to create a polynomial from an array, without dropping zeros.
fn[A] Polynomial::from_array(terms : Array[A]) -> Polynomial[A] {
  { terms, }
}

///|
test "dense polynomial" {
  let x = vari
  let p1 = to_poly([1, 2, 3])
  inspect(p1, content="1 + 2x^1 + 3x^2")
  let p2 = to_poly([4, 5, 6, 7])
  inspect(p2, content="4 + 5x^1 + 6x^2 + 7x^3")
  let p5 = to_poly([-1, 0, 2])
  inspect(p5, content="-1 + 2x^2")
  let p3 = p1 + p2
  inspect(p3, content="5 + 7x^1 + 9x^2 + 7x^3")
  let p4 = p1 * p2
  inspect(p4, content="4 + 13x^1 + 28x^2 + 34x^3 + 32x^4 + 21x^5")
  let p5 : Polynomial[Int] = (x() + coe(1)) * (x() + coe(-1))
  inspect(p5, content="-1 + 1x^2")
}

///|
test "inverse" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([4, 5, 6, 7])
  let p1n = -p1
  inspect(p1n, content="-1 + -2x^1 + -3x^2")
  let p3 = p1 - p2
  inspect(p3, content="-3 + -3x^1 + -3x^2 + -7x^3")
}

///|
test "eval" {
  let p1 = to_poly([1, 2, 3])
  inspect(p1.eval(2), content="17")
  inspect(p1.eval(1), content="6")
}

///|
test "scale" {
  let p1 = to_poly([1, 2, 3])
  let p2 = p1.scale(2, 3)
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="3x^2 + 6x^3 + 9x^4")
}

///|
test "substitute polynomial" {
  let p1 = to_poly([1, 2, 3])
  let p2 = to_poly([2, 3])
  let p3 = p1.substitute_poly(p2)
  let p4 = to_poly([1])
  let p5 = p1.substitute_poly(p4)
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="2 + 3x^1")
  inspect(p3, content="17 + 42x^1 + 27x^2")
  inspect(p4, content="1")
  inspect(p5, content="6")
}

///|
test "derivative" {
  let p1 = to_poly([1, 2, 3])
  let p2 = p1.derivative()
  let p3 = p2.derivative()
  inspect(p1, content="1 + 2x^1 + 3x^2")
  inspect(p2, content="2 + 6x^1")
  inspect(p3, content="6")
}
