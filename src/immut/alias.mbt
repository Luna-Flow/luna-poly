///|

///|
pub using @poly_core {
  trait Clearable,
  trait ContextualPolynomial,
  trait Copyable,
  trait HasArity,
  trait HasContext,
  trait HasDegree,
  trait HasLength,
  trait HasShape,
  trait HasTermCount,
  trait HasTotalDegree,
  trait IsZero,
  trait MultivariatePolynomial,
  trait MutablePolynomial,
  trait UnivariatePolynomial,
  type ContextOps,
  type ExponentVector,
  type MultivariateOps,
  type PolynomialShape,
  type UnivariateOps,
  type Variable,
  type VariableContext,
}

///|
pub using @lg {
  trait AddGroup,
  trait AddMonoid,
  trait Field,
  trait MulGroup,
  trait MulMonoid,
  trait Num,
  trait One,
  trait Ring,
  trait Semiring,
  trait Zero,
}

///|
pub using @dense {type DensePolynomial}

///|
pub using @term {type TermPolynomial}

///|
pub using @sparse {type SparsePolynomial}

///|
pub using @context {type ContextPolynomial}

///|
pub using @context {type ContextSubstitutionValue}
