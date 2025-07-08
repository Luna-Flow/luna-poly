///|
struct MultiPoly[A] {
  terms : Array[(ExpVec, A)]
}

///|
pub fn[A] coefficients(self : MultiPoly[A]) -> Array[A] {
  self.terms.map(@tuple.snd)
}

///|
pub fn[A : Semiring + Eq] MultiPoly::from_array(
  arr : Array[(Array[UInt], A)]
) -> MultiPoly[A] {
  {
    terms: normalize(arr).map(fn { (term, a) => (ExpVec::from_array(term), a) }),
  }
}

///|
pub fn[A : Semiring + Eq] MultiPoly::from_terms_array(
  terms : Array[(ExpVec, A)]
) -> MultiPoly[A] {
  terms.map(fn { (term, a) => (term.vec, a) }) |> MultiPoly::from_array
}

///|
pub fn[A : Semiring + Eq] normalize(
  arr : Array[(Array[UInt], A)]
) -> ArrayView[(Array[UInt], A)] {
  let l = arr.length()
  arr.sort_by(fn { (a1, _), (a2, _) => a2.compare(a1) })
  arr[0:loop 0, 1, arr[0] {
    i, j, (ap, ac) as acc =>
      if j >= l {
        guard not(is_zero(ac)) else { i }
        arr[i] = acc
        i + 1
      } else {
        let v = arr[j]
        if v.0 == ap {
          continue i, j + 1, (ap, ac + v.1)
        } else if not(is_zero(ac)) {
          arr[i] = acc
          continue i + 1, j + 1, v
        } else {
          continue i, j + 1, v
        }
      }
  }]
}

///|
impl[A : Show] Show for MultiPoly[A] with to_string(self) {
  guard not(self.terms.is_empty()) else { "0" }
  let s_var = fn {
    0 => "X"
    1 => "Y"
    2 => "Z"
    n => "X_" + n.to_string()
  }
  let show_power = fn {
    (1U, n) => s_var(n)
    (i, n) => "\{s_var(n)}^\{i}"
  }
  fn show_ceoff {
    ((ev : ExpVec), (c : A)) =>
      ev.vec
      .mapi(fn { idx, v => (v, idx) })
      .filter(fn { (v, _) => v != 0 })
      .map(show_power)
      .fold(init=c.to_string(), fn { acc, v => acc + " * " + v })
  }

  self.terms.map(show_ceoff).join(" + ")
}

///|
impl[A : Show] Show for MultiPoly[A] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
test "from array" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  inspect(MultiPoly::from_array(a1), content="2 * X^12 + 3 * Y + 3")
  let a2 = [([0U, 0], 0), ([0, 1], 0), ([12, 0], 0)]
  inspect(MultiPoly::from_array(a2), content="0")
  let a3 = [([0U, 0], 1), ([1, 1], 2)]
  inspect(MultiPoly::from_array(a3), content="2 * X * Y + 1")
}

///|
impl[A : Semiring + Eq] Add for MultiPoly[A] with op_add(xs, ys) {
  let len_xs = xs.terms.length()
  let len_ys = ys.terms.length()
  let zs = Array::make(len_xs + len_ys, (ExpVec::from_array([]), A::zero()))
  let s = loop 0, 0, 0 {
    ix, iy, iz =>
      if ix == len_xs && iy == len_ys {
        iz
      } else if ix == len_xs {
        Array::unsafe_blit(zs, iz, ys.terms, iy, len_ys - iy)
        iz + len_ys - iy
      } else if iy == len_ys {
        Array::unsafe_blit(zs, iz, xs.terms, ix, len_xs - ix)
        iz + len_xs - ix
      } else {
        let (xp, xc) = xs.terms[ix]
        let (yp, yc) = ys.terms[iy]
        if xp > yp {
          zs[iz] = (xp, xc)
          continue ix + 1, iy, iz + 1
        } else if xp < yp {
          zs[iz] = (yp, yc)
          continue ix, iy + 1, iz + 1
        } else {
          let c = xc + yc
          if is_zero(c) {
            continue ix + 1, iy + 1, iz
          } else {
            zs[iz] = (xp, c)
            continue ix + 1, iy + 1, iz + 1
          }
        }
      }
  }
  zs.resize(s, (ExpVec::from_array([]), A::zero()))
  { terms: zs }
}

///|
impl[A : Neg] Neg for MultiPoly[A] with op_neg(x) {
  { terms: x.terms.map(fn { (e, a) => (e, -a) }) }
}

///|
test "op neg" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(-p1, content="-2 * X^12 + -3 * Y + -3")
  inspect(-p2, content="-2 * X^12 + -3 * X * Y + -5")
  inspect(p1 + -p2, content="-3 * X * Y + 3 * Y + -2")
}

///|
impl[A : Semiring + Eq + Neg + Sub] Sub for MultiPoly[A] with op_sub(xs, ys) {
  xs + -ys
}

///|
test "op add / sub" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(p2, content="2 * X^12 + 3 * X * Y + 5")
  inspect(p1 + p2, content="4 * X^12 + 3 * X * Y + 3 * Y + 8")
  inspect(p2 + p1, content="4 * X^12 + 3 * X * Y + 3 * Y + 8")
  inspect(p1 - p2, content="-3 * X * Y + 3 * Y + -2")
  inspect(p2 - p1, content="3 * X * Y + -3 * Y + 2")
}

///|
pub fn[A : Semiring + Eq] MultiPoly::scale(
  self : MultiPoly[A],
  term : (ExpVec, A)
) -> MultiPoly[A] {
  let (e, c) = term
  Array::makei(self.terms.length(), fn(i) {
    let (xp, xc) = self.terms[i]
    ((xp * e).vec, xc * c)
  }).filter(fn { (_, c) => not(is_zero(c)) })
  |> MultiPoly::from_array
}

///|
test "scale" {
  let a1 = [([0U, 0], 1), ([0, 0], 2), ([12, 0], 2), ([0, 1], 3)]
  let a2 = [([0U, 0], 3), ([0, 0], 2), ([12, 0], 2), ([1, 1], 3)]
  let p1 = MultiPoly::from_array(a1)
  let p2 = MultiPoly::from_array(a2)
  inspect(p1, content="2 * X^12 + 3 * Y + 3")
  inspect(p2, content="2 * X^12 + 3 * X * Y + 5")
  inspect(
    p1.scale((ExpVec::from_array([1U, 1]), -3)),
    content="-6 * X^13 * Y + -9 * X * Y^2 + -9 * X * Y",
  )
  inspect(
    p2.scale((ExpVec::from_array([1U, 1]), 3)),
    content="6 * X^13 * Y + 9 * X^2 * Y^2 + 15 * X * Y",
  )
}
