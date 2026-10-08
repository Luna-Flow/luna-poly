///|
/// Mutable wrapper around the immutable context-aware polynomial model.
struct ContextPolynomial[A] {
  mut value : @immut_context.ContextPolynomial[A]
} derive(Debug)

///|
pub(all) enum ContextSubstitutionValue[A] {
  Scalar(A)
  Polynomial(ContextPolynomial[A])
}

///|
fn[A] ContextSubstitutionValue::to_immut(
  self : ContextSubstitutionValue[A],
) -> @immut_context.ContextSubstitutionValue[A] {
  match self {
    Scalar(value) => @immut_context.Scalar(value)
    Polynomial(polynomial) => @immut_context.Polynomial(polynomial.value)
  }
}

///|
pub fn[A] ContextPolynomial::from_immut(
  value : @immut_context.ContextPolynomial[A],
) -> ContextPolynomial[A] {
  { value, }
}

///|
pub fn[A] ContextPolynomial::to_immut(
  self : ContextPolynomial[A],
) -> @immut_context.ContextPolynomial[A] {
  self.value
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_term_polynomial(
  context : VariableContext,
  polynomial : TermPolynomial[A],
) -> ContextPolynomial[A] {
  ContextPolynomial::from_immut(
    @immut_context.ContextPolynomial::from_term_polynomial(
      context,
      polynomial.to_immut(),
    ),
  )
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_sparse_polynomial(
  context : VariableContext,
  polynomial : SparsePolynomial[A],
) -> ContextPolynomial[A] {
  ContextPolynomial::from_immut(
    @immut_context.ContextPolynomial::from_sparse_polynomial(
      context,
      polynomial.to_immut(),
    ),
  )
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::constant(
  context : VariableContext,
  value : A,
) -> ContextPolynomial[A] {
  ContextPolynomial::from_immut(
    @immut_context.ContextPolynomial::constant(context, value),
  )
}

///|
pub fn[A : Eq + AddMonoid + One] ContextPolynomial::variable_checked(
  context : VariableContext,
  variable : Variable,
) -> ContextPolynomial[A]? {
  match @immut_context.ContextPolynomial::variable_checked(context, variable) {
    None => None
    Some(polynomial) => Some(ContextPolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : Eq + AddMonoid + One] ContextPolynomial::variable(
  context : VariableContext,
  variable : Variable,
) -> ContextPolynomial[A] {
  match ContextPolynomial::variable_checked(context, variable) {
    None => abort("Variable is outside the context")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_named_terms_as_terms_checked(
  context : VariableContext,
  terms : Array[(Array[(Variable, UInt)], A)],
) -> ContextPolynomial[A]? {
  match
    @immut_context.ContextPolynomial::from_named_terms_as_terms_checked(
      context, terms,
    ) {
    None => None
    Some(value) => Some(ContextPolynomial::from_immut(value))
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_named_terms_as_terms(
  context : VariableContext,
  terms : Array[(Array[(Variable, UInt)], A)],
) -> ContextPolynomial[A] {
  match ContextPolynomial::from_named_terms_as_terms_checked(context, terms) {
    None => abort("Named terms contain variables outside the context")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_named_terms_as_sparse_checked(
  context : VariableContext,
  terms : Array[(Array[(Variable, UInt)], A)],
) -> ContextPolynomial[A]? {
  match
    @immut_context.ContextPolynomial::from_named_terms_as_sparse_checked(
      context, terms,
    ) {
    None => None
    Some(value) => Some(ContextPolynomial::from_immut(value))
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::from_named_terms_as_sparse(
  context : VariableContext,
  terms : Array[(Array[(Variable, UInt)], A)],
) -> ContextPolynomial[A] {
  match ContextPolynomial::from_named_terms_as_sparse_checked(context, terms) {
    None => abort("Named terms contain variables outside the context")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A] ContextPolynomial::context(
  self : ContextPolynomial[A],
) -> VariableContext {
  self.value.context()
}

///|
pub fn[A] ContextPolynomial::term_count(self : ContextPolynomial[A]) -> Int {
  self.to_terms().length()
}

///|
pub fn[A] ContextPolynomial::arity(self : ContextPolynomial[A]) -> Int {
  let mut result = 0
  for term in self.to_terms() {
    let (exponent, _) = term
    result = @cmp.maximum(result, exponent.length())
  }
  result
}

///|
pub impl[A] @poly_core.HasContext for ContextPolynomial[A] with fn context(self) {
  self.context()
}

///|
pub impl[A] @poly_core.HasTermCount for ContextPolynomial[A] with fn term_count(
  self,
) {
  self.term_count()
}

///|
pub impl[A] @poly_core.HasArity for ContextPolynomial[A] with fn arity(self) {
  self.arity()
}

///|
pub impl[A] @poly_core.HasShape for ContextPolynomial[A] with fn shape(self) {
  self.value.shape()
}

///|
pub impl[A] @poly_core.IsZero for ContextPolynomial[A] with fn is_zero(self) {
  self.term_count() == 0
}

///|
pub impl[A] @poly_core.ContextualPolynomial for ContextPolynomial[A]

///|
pub fn[A] ContextPolynomial::to_terms(
  self : ContextPolynomial[A],
) -> Array[(ExponentVector, A)] {
  self.value.to_terms()
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::to_term_polynomial(
  self : ContextPolynomial[A],
) -> TermPolynomial[A] {
  TermPolynomial::from_immut(self.value.to_term_polynomial())
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::to_sparse_polynomial(
  self : ContextPolynomial[A],
) -> SparsePolynomial[A] {
  SparsePolynomial::from_immut(self.value.to_sparse_polynomial())
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval(
  self : ContextPolynomial[A],
  values : Array[A],
) -> A {
  self.value.eval(values)
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_checked(
  self : ContextPolynomial[A],
  values : Array[A],
) -> A? {
  self.value.eval_checked(values)
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_named_checked(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> A? {
  self.value.eval_named_checked(assignments)
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_named(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> A {
  self.value.eval_named(assignments)
}

///|
fn[A] substitutions_to_immut(
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
) -> Array[(Variable, @immut_context.ContextSubstitutionValue[A])] {
  replacements.map(fn(replacement) { (replacement.0, replacement.1.to_immut()) })
}

///|
fn[A] named_substitutions_to_immut(
  replacements : Array[(@tt_core.Name, ContextSubstitutionValue[A])],
) -> Array[(@tt_core.Name, @immut_context.ContextSubstitutionValue[A])] {
  replacements.map(fn(replacement) { (replacement.0, replacement.1.to_immut()) })
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::substitute_checked(
  self : ContextPolynomial[A],
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
) -> ContextPolynomial[A]? {
  match self.value.substitute_checked(substitutions_to_immut(replacements)) {
    None => None
    Some(polynomial) => Some(ContextPolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::substitute(
  self : ContextPolynomial[A],
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
) -> ContextPolynomial[A] {
  match self.substitute_checked(replacements) {
    None => abort("Invalid context polynomial substitution")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::substitute_names_checked(
  self : ContextPolynomial[A],
  replacements : Array[(@tt_core.Name, ContextSubstitutionValue[A])],
) -> ContextPolynomial[A]? {
  match
    self.value.substitute_names_checked(
      named_substitutions_to_immut(replacements),
    ) {
    None => None
    Some(polynomial) => Some(ContextPolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::substitute_names(
  self : ContextPolynomial[A],
  replacements : Array[(@tt_core.Name, ContextSubstitutionValue[A])],
) -> ContextPolynomial[A] {
  match self.substitute_names_checked(replacements) {
    None => abort("Invalid named context polynomial substitution")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::eval_partial_checked(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> ContextPolynomial[A]? {
  match self.value.eval_partial_checked(assignments) {
    None => None
    Some(polynomial) => Some(ContextPolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::eval_partial(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> ContextPolynomial[A] {
  match self.eval_partial_checked(assignments) {
    None => abort("Invalid partial context polynomial assignments")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::eval_partial_named_checked(
  self : ContextPolynomial[A],
  assignments : Array[(@tt_core.Name, A)],
) -> ContextPolynomial[A]? {
  match self.value.eval_partial_named_checked(assignments) {
    None => None
    Some(polynomial) => Some(ContextPolynomial::from_immut(polynomial))
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::eval_partial_named(
  self : ContextPolynomial[A],
  assignments : Array[(@tt_core.Name, A)],
) -> ContextPolynomial[A] {
  match self.eval_partial_named_checked(assignments) {
    None => abort("Invalid named partial context polynomial assignments")
    Some(polynomial) => polynomial
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::ops() -> @poly_core.ContextOps[
  ContextPolynomial[A],
  A,
] {
  @poly_core.ContextOps::new(
    fn(context, terms) {
      ContextPolynomial::from_immut(
        @immut_context.ContextPolynomial::from_term_polynomial(
          context,
          @immut_term.TermPolynomial::from_terms(terms),
        ),
      )
    },
    fn(polynomial) { polynomial.to_terms() },
    fn(polynomial, assignments) { polynomial.eval_named_checked(assignments) },
    fn(left, right) {
      match left.value.add_checked(right.value) {
        None => None
        Some(value) => Some(ContextPolynomial::from_immut(value))
      }
    },
    fn(left, right) {
      match left.value.mul_checked(right.value) {
        None => None
        Some(value) => Some(ContextPolynomial::from_immut(value))
      }
    },
  )
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::add_inplace(
  self : ContextPolynomial[A],
  other : ContextPolynomial[A],
) -> Unit {
  match self.value.add_checked(other.value) {
    None => abort("ContextPolynomial contexts are not compatible")
    Some(value) => self.value = value
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul] ContextPolynomial::mul_inplace(
  self : ContextPolynomial[A],
  other : ContextPolynomial[A],
) -> Unit {
  match self.value.mul_checked(other.value) {
    None => abort("ContextPolynomial contexts are not compatible")
    Some(value) => self.value = value
  }
}

///|
pub fn[A] ContextPolynomial::copy(
  self : ContextPolynomial[A],
) -> ContextPolynomial[A] {
  { value: self.value, }
}

///|
pub impl[A : Eq + AddMonoid] @poly_core.Clearable for ContextPolynomial[A] with fn clear(
  self,
) {
  self.value = @immut_context.ContextPolynomial::from_named_terms_as_sparse(
    self.context(),
    [],
  )
}

///|
pub impl[A] @poly_core.Copyable for ContextPolynomial[A] with fn copy(self) {
  self.copy()
}

///|
pub impl[A : Eq + AddMonoid] @poly_core.MutablePolynomial for ContextPolynomial[
  A,
]

///|
pub impl[A : Eq + AddMonoid] Add for ContextPolynomial[A] with fn add(
  self,
  other,
) {
  let result = self.copy()
  result.add_inplace(other)
  result
}

///|
pub impl[A : Eq + AddMonoid + Mul] Mul for ContextPolynomial[A] with fn mul(
  self,
  other,
) {
  let result = self.copy()
  result.mul_inplace(other)
  result
}

///|
pub impl[A : Eq + Zero + Neg] Neg for ContextPolynomial[A] with fn neg(self) {
  ContextPolynomial::from_immut(-self.value)
}

///|
pub impl[A : Eq + AddMonoid + Neg] Sub for ContextPolynomial[A] with fn sub(
  self,
  other,
) {
  self + -other
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::pow(
  self : ContextPolynomial[A],
  exponent : UInt,
) -> ContextPolynomial[A] {
  ContextPolynomial::from_immut(self.value.pow(exponent))
}

///|
pub impl[A : Show + Zero] Show for ContextPolynomial[A] with fn output(
  self,
  logger,
) {
  Show::output(self.value, logger)
}

///|
test "mutable context polynomial delegates named evaluation" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 2),
  ])
  p.add_inplace(
    ContextPolynomial::from_named_terms_as_terms(context, [([], 1)]),
  )
  assert_eq(p.eval_named([(x, 4)]), 9)
}

///|
test "mutable context polynomial delegates named polynomial substitution" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
    ([(y, 1U)], 1),
  ])
  let y_plus_one = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(y, 1U)], 1),
    ([], 1),
  ])
  let substituted = p.substitute_names([
    (x.to_type_theory_name(), Polynomial(y_plus_one)),
    (y.to_type_theory_name(), Scalar(2)),
  ])
  assert_eq(substituted.eval_named([(x, 0), (y, 3)]), 6)
}

///|
test "mutable context polynomial rejects duplicate named substitutions" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
  ])
  let x_name = x.to_type_theory_name()
  assert_true(p.eval_partial_named_checked([(x_name, 1), (x_name, 2)]) is None)
  assert_true(
    p.substitute_names_checked([(x_name, Scalar(1)), (x_name, Scalar(2))]) is None,
  )
}

///|
test "mutable context polynomial rejects incompatible named polynomial substitution" {
  let context = VariableContext::from_names(["x"])
  let other_context = VariableContext::from_names(["z"])
  let x = context.require_variable("x")
  let z = other_context.require_variable("z")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
  ])
  let replacement = ContextPolynomial::from_named_terms_as_sparse(
    other_context,
    [([(z, 1U)], 1)],
  )
  assert_true(
    p.substitute_names_checked([
      (x.to_type_theory_name(), Polynomial(replacement)),
    ]) is None,
  )
}

///|
test "eval_named_checked rejects polynomials wider than the context" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let wide : TermPolynomial[Int] = TermPolynomial::from_terms([
    (ExponentVector::from_array([1, 1]), 1),
  ])
  let p = ContextPolynomial::from_term_polynomial(context, wide)
  assert_true(p.eval_named_checked([(x, 2)]) is None)
  assert_true(ContextPolynomial::ops().eval_named_checked(p, [(x, 2)]) is None)
}
