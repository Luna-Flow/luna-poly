///|
pub(all) enum SparsePolynomial {
  RealCoefficientPoly(@hashmap.T[ExpTerm, Real])
  ComplexCoefficientPoly(@hashmap.T[ExpTerm, Complex])
  BoolCoefficientPoly(@hashmap.T[ExpTerm, Bool])
}

///|
pub trait Sparse {
  add_real_coe_term(Self, ExpTerm, Real) -> Unit
  add_complex_coe_term(Self, ExpTerm, Complex) -> Unit
  add_bool_coe_term(Self, ExpTerm, Bool) -> Unit
}

///|
impl Sparse for SparsePolynomial with add_real_coe_term(
  self : SparsePolynomial,
  exp_term : ExpTerm,
  coefficient : Real
) -> Unit {
  match self {
    RealCoefficientPoly(poly) => {
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient)
      }
    }
    ComplexCoefficientPoly(poly) => {
      let coefficient_ = coefficient.to_complex()
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient_
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient_)
      }
    }
    BoolCoefficientPoly(poly) => {
      let coefficient_ = coefficient.to_bool()
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient_
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient_)
      }
    }
  }
}

///|
impl Sparse for SparsePolynomial with add_complex_coe_term(
  self : SparsePolynomial,
  exp_term : ExpTerm,
  coefficient : Complex
) -> Unit {
  match self {
    RealCoefficientPoly(poly) => {
      let coefficient_ = coefficient.to_real()
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient_
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient_)
      }
    }
    ComplexCoefficientPoly(poly) => {
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient)
      }
    }
    BoolCoefficientPoly(poly) => {
      let coefficient_ = coefficient.to_bool()
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient_
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient_)
      }
    }
  }
}

///|
impl Sparse for SparsePolynomial with add_bool_coe_term(
  self : SparsePolynomial,
  exp_term : ExpTerm,
  coefficient : Bool
) -> Unit {
  match self {
    RealCoefficientPoly(_) =>
      abort(
        "Unable to add a Bool coefficient term to Real coefficient polynomial.",
      )
    ComplexCoefficientPoly(_) =>
      abort(
        "Unable to add a Bool coefficient term to Complex coefficient polynomial.",
      )
    BoolCoefficientPoly(poly) => {
      let v = poly.get(exp_term)
      match v {
        Some(val) => {
          let val_ = val + coefficient
          poly.set(exp_term, val_)
        }
        None => poly.set(exp_term, coefficient)
      }
    }
  }
}
