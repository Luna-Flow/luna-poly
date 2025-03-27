///|
let threshold : Int = 32

///| Multiply two polynomials using the Karatsuba algorithm.
pub fn karatsuba[A : Eq + Ring](
  self : Polynomial[A],
  other : Polynomial[A]
) -> Polynomial[A] {
  fn go(xs : Polynomial[A], ys : Polynomial[A]) {
    if xs.length() <= threshold || ys.length() <= threshold {
      return xs * ys
    } else {
      let xs_len = xs.length()
      let ys_len = ys.length()
      let zs_len = xs_len + ys_len - 1
      let m = (@math.minimum(xs_len, ys_len) + 1) >> 1
      let zs = Polynomial::empty(cap=zs_len)
      let (xs0, xs1) = xs.terms.split_at(m)
      let (xs0, xs1) = (
        Polynomial::from_array(xs0),
        Polynomial::from_array(xs1.split_at(xs_len - m).1),
      )
      let (ys0, ys1) = ys.terms.split_at(m)
      let (ys0, ys1) = (
        Polynomial::from_array(ys0),
        Polynomial::from_array(ys1.split_at(ys_len - m).1),
      )
      let xs01 = xs0 + xs1
      let ys01 = ys0 + ys1
      let zs0 = go(xs0, ys0)
      let zs2 = go(xs1, ys1)
      let zs11 = go(xs01, ys01)
      for k in 0..<zs_len {
        let z0 = if k < zs0.length() { zs0.terms[k] } else { A::zero() }
        let z11 = if k - m >= 0 && k - m < zs11.length() {
          zs11.terms[k - m]
        } else {
          A::zero()
        }
        let z10 = if k - m >= 0 && k - m < zs0.length() {
          zs0.terms[k - m]
        } else {
          A::zero()
        }
        let z12 = if k - m >= 0 && k - m < zs2.length() {
          zs2.terms[k - m]
        } else {
          A::zero()
        }
        let z2 = if k - 2 * m >= 0 && k - 2 * m < zs2.length() {
          zs2.terms[k - 2 * m]
        } else {
          A::zero()
        }
        zs.terms[k] = z0 + (z11 + -(z10 + z12)) + z2
      }
      zs
    }
  }

  go(self, other)
}

///|
test {
  let xs = to_poly([1, 2, 3, 4, 1, 9, 1, 9, 8, 1, 0])
  let ys = to_poly([4, 5, 6, 7, 1, 1, 4, 5, 1, 4])
  let zs = karatsuba(xs, ys)
  let zs1 = xs * ys
  inspect!(
    zs,
    content="4 + 13x^1 + 28x^2 + 50x^3 + 57x^4 + 89x^5 + 92x^6 + 122x^7 + 174x^8 + 152x^9 + 161x^10 + 129x^11 + 90x^12 + 63x^13 + 115x^14 + 57x^15 + 49x^16 + 33x^17 + 4x^18",
  )
  inspect!(
    zs1,
    content="4 + 13x^1 + 28x^2 + 50x^3 + 57x^4 + 89x^5 + 92x^6 + 122x^7 + 174x^8 + 152x^9 + 161x^10 + 129x^11 + 90x^12 + 63x^13 + 115x^14 + 57x^15 + 49x^16 + 33x^17 + 4x^18",
  )
}
