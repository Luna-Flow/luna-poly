///|
/// Defines the threshold value used to determine when to switch from Karatsuba
/// multiplication to standard polynomial multiplication.
///
/// When multiplying polynomials using the Karatsuba algorithm, if either
/// polynomial has a length less than or equal to this threshold, the algorithm
/// falls back to standard multiplication instead of continuing with the
/// divide-and-conquer approach. This optimization helps avoid the overhead of
/// recursive calls for small polynomials where the simpler multiplication
/// method is more efficient.
///
/// The value of 32 is chosen as a balance between the computational overhead of
/// the Karatsuba algorithm and the performance benefits it provides for larger
/// polynomials.
///
let threshold : Int = 32

///|
/// Multiplies two polynomials using the Karatsuba algorithm for improved
/// asymptotic complexity.
///
/// Parameters:
///
/// * `self` : The first polynomial to multiply.
/// * `other` : The second polynomial to multiply.
///
/// Returns the product of the two polynomials.
///
/// Example:
///
/// ```moonbit
/// let p1 = to_poly([1, 2, 3])  // 1 + 2x + 3x^2
/// let p2 = to_poly([4, 5])     // 4 + 5x
/// let result = p1.karatsuba(p2)
/// inspect(result, content="4 + 13x^1 + 22x^2 + 15x^3")
/// ```
///
pub fn[A : Eq + Ring] karatsuba(
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
      let m = (@cmp.minimum(xs_len, ys_len) + 1) >> 1
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
/// Tests the correctness of the Karatsuba multiplication algorithm by comparing
/// its result with standard polynomial multiplication.
///
/// This test verifies that the Karatsuba algorithm produces the same result as
/// the standard multiplication operator for polynomials. It creates two test
/// polynomials from coefficient arrays, multiplies them using both the
/// Karatsuba method and the standard multiplication operator, then checks that
/// both results are identical.
///
/// The test polynomials used are:
///
/// * `xs`: A polynomial with coefficients \[1, 2, 3, 4, 1, 9, 1, 9, 8, 1, 0],
///   representing 1 + 2x + 3x² + 4x³ + x⁴ + 9x⁵ + x⁶ + 9x⁷ + 8x⁸ + x⁹
/// * `ys`: A polynomial with coefficients \[4, 5, 6, 7, 1, 1, 4, 5, 1, 4],
///   representing 4 + 5x + 6x² + 7x³ + x⁴ + x⁵ + 4x⁶ + 5x⁷ + x⁸ + 4x⁹
///
/// Both multiplication methods should produce the polynomial: 4 + 13x + 28x² +
/// 50x³ + 57x⁴ + 89x⁵ + 92x⁶ + 122x⁷ + 174x⁸ + 152x⁹ + 161x¹⁰ + 129x¹¹ + 90x¹²
/// + 63x¹³ + 115x¹⁴ + 57x¹⁵ + 49x¹⁶ + 33x¹⁷ + 4x¹⁸
///
/// This test ensures that the Karatsuba algorithm, which is an optimization for
/// polynomial multiplication with better asymptotic complexity, maintains
/// mathematical correctness compared to the straightforward multiplication
/// approach.
///
test {
  let xs = to_poly([1, 2, 3, 4, 1, 9, 1, 9, 8, 1, 0])
  let ys = to_poly([4, 5, 6, 7, 1, 1, 4, 5, 1, 4])
  let zs = xs.karatsuba(ys)
  let zs1 = xs * ys
  inspect(
    zs,
    content="4 + 13x^1 + 28x^2 + 50x^3 + 57x^4 + 89x^5 + 92x^6 + 122x^7 + 174x^8 + 152x^9 + 161x^10 + 129x^11 + 90x^12 + 63x^13 + 115x^14 + 57x^15 + 49x^16 + 33x^17 + 4x^18",
  )
  inspect(
    zs1,
    content="4 + 13x^1 + 28x^2 + 50x^3 + 57x^4 + 89x^5 + 92x^6 + 122x^7 + 174x^8 + 152x^9 + 161x^10 + 129x^11 + 90x^12 + 63x^13 + 115x^14 + 57x^15 + 49x^16 + 33x^17 + 4x^18",
  )
}
