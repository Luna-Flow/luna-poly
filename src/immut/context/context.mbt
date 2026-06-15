///|
priv enum ContextPolynomialStorage[A] {
  TermStorage(TermPolynomial[A])
  SparseStorage(SparsePolynomial[A])
}

///|
/// Context-bound multivariate polynomial with selectable term or sparse storage.
struct ContextPolynomial[A] {
  context : VariableContext
  storage : ContextPolynomialStorage[A]
}

///|
pub(all) enum ContextSubstitutionValue[A] {
  Scalar(A)
  Polynomial(ContextPolynomial[A])
}

///|
fn VariableContext::exponent_checked(
  self : VariableContext,
  factors : Array[(Variable, UInt)],
) -> ExponentVector? {
  let exponents = Array::make(self.size(), 0U)
  for factor in factors {
    let (variable, exponent) = factor
    if !self.contains(variable) {
      return None
    }
    let index = variable.index()
    exponents[index] = exponents[index] + exponent
  }
  Some(ExponentVector::from_array(exponents))
}

///|
fn[A] VariableContext::terms_checked(
  self : VariableContext,
  terms : Array[(Array[(Variable, UInt)], A)],
) -> Array[(ExponentVector, A)]? {
  let result : Array[(ExponentVector, A)] = []
  for term in terms {
    let (factors, coefficient) = term
    match self.exponent_checked(factors) {
      None => return None
      Some(exponent) => result.push((exponent, coefficient))
    }
  }
  Some(result)
}

///|
pub fn[A] ContextPolynomial::from_term_polynomial(
  context : VariableContext,
  polynomial : TermPolynomial[A],
) -> ContextPolynomial[A] {
  { context, storage: TermStorage(polynomial) }
}

///|
pub fn[A] ContextPolynomial::from_sparse_polynomial(
  context : VariableContext,
  polynomial : SparsePolynomial[A],
) -> ContextPolynomial[A] {
  { context, storage: SparseStorage(polynomial) }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::constant(
  context : VariableContext,
  value : A,
) -> ContextPolynomial[A] {
  ContextPolynomial::from_sparse_polynomial(
    context,
    SparsePolynomial::from_terms([(ExponentVector::one(), value)]),
  )
}

///|
pub fn[A : Eq + AddMonoid + One] ContextPolynomial::variable_checked(
  context : VariableContext,
  variable : Variable,
) -> ContextPolynomial[A]? {
  if !context.contains(variable) {
    return None
  }
  Some(
    ContextPolynomial::from_sparse_polynomial(
      context,
      SparsePolynomial::from_terms([
        (ExponentVector::one().with_exponent(variable.index(), 1), A::one()),
      ]),
    ),
  )
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
  match context.terms_checked(terms) {
    None => None
    Some(index_terms) =>
      Some(
        ContextPolynomial::from_term_polynomial(
          context,
          TermPolynomial::from_terms(index_terms),
        ),
      )
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
  match context.terms_checked(terms) {
    None => None
    Some(index_terms) =>
      Some(
        ContextPolynomial::from_sparse_polynomial(
          context,
          SparsePolynomial::from_terms(index_terms),
        ),
      )
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
  self.context
}

///|
fn[A] ContextPolynomial::term_count(self : ContextPolynomial[A]) -> Int {
  self.to_terms().length()
}

///|
fn[A] ContextPolynomial::arity(self : ContextPolynomial[A]) -> Int {
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
  @poly_core.PolynomialShape::contextual(
    self.context,
    self.arity(),
    self.term_count(),
  )
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
  match self.storage {
    TermStorage(polynomial) => polynomial.to_terms()
    SparseStorage(polynomial) => polynomial.to_terms()
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::to_term_polynomial(
  self : ContextPolynomial[A],
) -> TermPolynomial[A] {
  match self.storage {
    TermStorage(polynomial) => polynomial
    SparseStorage(polynomial) =>
      TermPolynomial::from_terms(polynomial.to_terms())
  }
}

///|
pub fn[A : Eq + AddMonoid] ContextPolynomial::to_sparse_polynomial(
  self : ContextPolynomial[A],
) -> SparsePolynomial[A] {
  match self.storage {
    TermStorage(polynomial) =>
      SparsePolynomial::from_terms(polynomial.to_terms())
    SparseStorage(polynomial) => polynomial
  }
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval(
  self : ContextPolynomial[A],
  values : Array[A],
) -> A {
  match self.eval_checked(values) {
    None => abort("Missing value for multivariate polynomial variable")
    Some(value) => value
  }
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_checked(
  self : ContextPolynomial[A],
  values : Array[A],
) -> A? {
  if self.arity() > values.length() {
    return None
  }
  match self.storage {
    TermStorage(polynomial) => polynomial.eval_checked(values)
    SparseStorage(polynomial) => polynomial.eval_checked(values)
  }
}

///|
fn[A] lookup_assignment(
  assignments : Array[(Variable, A)],
  variable : Variable,
) -> A? {
  let mut found = false
  let mut result : A? = None
  for assignment in assignments {
    let (current, value) = assignment
    if current == variable {
      if found {
        return None
      }
      found = true
      result = Some(value)
    }
  }
  result
}

///|
fn[A] ContextPolynomial::assignment_values_checked(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> Array[A]? {
  for assignment in assignments {
    let (variable, _) = assignment
    if !self.context.contains(variable) {
      return None
    }
  }
  let values : Array[A] = []
  for i in 0..<self.arity() {
    let variable = self.context.variables()[i]
    match lookup_assignment(assignments, variable) {
      None => return None
      Some(value) => values.push(value)
    }
  }
  Some(values)
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_named_checked(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> A? {
  match self.assignment_values_checked(assignments) {
    None => None
    Some(values) => Some(self.eval(values))
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::ops() -> @poly_core.ContextOps[
  ContextPolynomial[A],
  A,
] {
  @poly_core.ContextOps::new(
    fn(context, terms) {
      ContextPolynomial::from_term_polynomial(
        context,
        TermPolynomial::from_terms(terms),
      )
    },
    fn(polynomial) { polynomial.to_terms() },
    fn(polynomial, assignments) { polynomial.eval_named_checked(assignments) },
    fn(left, right) { left.add_checked(right) },
    fn(left, right) { left.mul_checked(right) },
  )
}

///|
pub fn[A : AddMonoid + Mul + One] ContextPolynomial::eval_named(
  self : ContextPolynomial[A],
  assignments : Array[(Variable, A)],
) -> A {
  match self.eval_named_checked(assignments) {
    None => abort("Invalid or incomplete context polynomial assignments")
    Some(value) => value
  }
}

///|
fn[A] ContextPolynomial::validate_substitution_values(
  self : ContextPolynomial[A],
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
) -> Bool {
  for i in 0..<replacements.length() {
    let (variable, value) = replacements[i]
    if !self.context.contains(variable) {
      return false
    }
    match value {
      Scalar(_) => ()
      Polynomial(polynomial) =>
        if polynomial.context != self.context {
          return false
        }
    }
    for j in (i + 1)..<replacements.length() {
      if replacements[j].0 == variable {
        return false
      }
    }
  }
  true
}

///|
fn[A] lookup_substitution_value(
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
  variable : Variable,
) -> ContextSubstitutionValue[A]? {
  for replacement in replacements {
    if replacement.0 == variable {
      return Some(replacement.1)
    }
  }
  None
}

///|
pub fn[A : Eq + AddMonoid + Mul + One] ContextPolynomial::substitute_checked(
  self : ContextPolynomial[A],
  replacements : Array[(Variable, ContextSubstitutionValue[A])],
) -> ContextPolynomial[A]? {
  if !self.validate_substitution_values(replacements) {
    return None
  }
  let mut result = ContextPolynomial::constant(self.context, A::zero())
  let variables = self.context.variables()
  for term in self.to_terms() {
    let (exponent, coefficient) = term
    let mut product = ContextPolynomial::constant(self.context, coefficient)
    if exponent.length() > variables.length() {
      return None
    }
    for i in 0..<exponent.length() {
      let power = exponent[i]
      if power == 0 {
        continue
      }
      let variable = variables[i]
      let factor = match lookup_substitution_value(replacements, variable) {
        None => ContextPolynomial::variable(self.context, variable).pow(power)
        Some(Scalar(value)) =>
          ContextPolynomial::constant(
            self.context,
            @internal.pow_nat(value, power, one=A::one()),
          )
        Some(Polynomial(polynomial)) => polynomial.pow(power)
      }
      product = product * factor
    }
    result = result + product
  }
  Some(result)
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
  let converted : Array[(Variable, ContextSubstitutionValue[A])] = []
  for replacement in replacements {
    match self.context.variable_by_type_theory_name(replacement.0) {
      None => return None
      Some(variable) => converted.push((variable, replacement.1))
    }
  }
  self.substitute_checked(converted)
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
  let replacements = assignments.map(fn(assignment) {
    (assignment.0, ContextSubstitutionValue::Scalar(assignment.1))
  })
  self.substitute_checked(replacements)
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
  let replacements = assignments.map(fn(assignment) {
    (assignment.0, ContextSubstitutionValue::Scalar(assignment.1))
  })
  self.substitute_names_checked(replacements)
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
pub fn[A : Eq + AddMonoid] ContextPolynomial::add_checked(
  self : ContextPolynomial[A],
  other : ContextPolynomial[A],
) -> ContextPolynomial[A]? {
  if self.context != other.context {
    return None
  }
  match (self.storage, other.storage) {
    (TermStorage(left), TermStorage(right)) =>
      Some(ContextPolynomial::from_term_polynomial(self.context, left + right))
    (SparseStorage(left), SparseStorage(right)) =>
      Some(
        ContextPolynomial::from_sparse_polynomial(self.context, left + right),
      )
    _ =>
      Some(
        ContextPolynomial::from_sparse_polynomial(
          self.context,
          self.to_sparse_polynomial() + other.to_sparse_polynomial(),
        ),
      )
  }
}

///|
pub fn[A : Eq + AddMonoid + Mul] ContextPolynomial::mul_checked(
  self : ContextPolynomial[A],
  other : ContextPolynomial[A],
) -> ContextPolynomial[A]? {
  if self.context != other.context {
    return None
  }
  match (self.storage, other.storage) {
    (TermStorage(left), TermStorage(right)) =>
      Some(ContextPolynomial::from_term_polynomial(self.context, left * right))
    (SparseStorage(left), SparseStorage(right)) =>
      Some(
        ContextPolynomial::from_sparse_polynomial(self.context, left * right),
      )
    _ =>
      Some(
        ContextPolynomial::from_sparse_polynomial(
          self.context,
          self.to_sparse_polynomial() * other.to_sparse_polynomial(),
        ),
      )
  }
}

///|
pub impl[A : Eq + AddMonoid] Add for ContextPolynomial[A] with fn add(
  self,
  other,
) {
  match self.add_checked(other) {
    None => abort("ContextPolynomial contexts are not compatible")
    Some(result) => result
  }
}

///|
pub impl[A : Eq + AddMonoid + Mul] Mul for ContextPolynomial[A] with fn mul(
  self,
  other,
) {
  match self.mul_checked(other) {
    None => abort("ContextPolynomial contexts are not compatible")
    Some(result) => result
  }
}

///|
pub impl[A : Eq + Zero + Neg] Neg for ContextPolynomial[A] with fn neg(self) {
  match self.storage {
    TermStorage(polynomial) =>
      ContextPolynomial::from_term_polynomial(self.context, -polynomial)
    SparseStorage(polynomial) =>
      ContextPolynomial::from_sparse_polynomial(self.context, -polynomial)
  }
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
  match self.storage {
    TermStorage(polynomial) =>
      ContextPolynomial::from_term_polynomial(
        self.context,
        polynomial.pow(exponent),
      )
    SparseStorage(polynomial) =>
      ContextPolynomial::from_sparse_polynomial(
        self.context,
        polynomial.pow(exponent),
      )
  }
}

///|
pub impl[A : Show + Zero] Show for ContextPolynomial[A] with fn output(
  self,
  logger,
) {
  let terms = self.to_terms()
  if terms.is_empty() {
    logger.write_object(A::zero())
    return
  }
  for i in 0..<terms.length() {
    if i > 0 {
      logger.write_string(" + ")
    }
    let exponent = terms[i].0
    logger.write_object(terms[i].1)
    for variable_index in 0..<exponent.length() {
      let power = exponent[variable_index]
      if power != 0 {
        logger.write_string(" * ")
        logger.write_object(self.context.variables()[variable_index])
        if power != 1 {
          logger..write_char('^').write_object(power)
        }
      }
    }
  }
}

///|
test "variable context rejects duplicate names" {
  assert_true(VariableContext::from_names_checked(["x", "x"]) is None)
  let context = VariableContext::from_names(["x", "y"])
  assert_eq(context.size(), 2)
  assert_eq(context.require_variable("y").index(), 1)
}

///|
test "context polynomial named evaluation matches indexed evaluation" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 2U)], 1),
    ([(x, 1U), (y, 1U)], 3),
    ([], 4),
  ])
  assert_eq(p.eval([2, 5]), 38)
  assert_eq(p.eval_named([(x, 2), (y, 5)]), 38)
  assert_true(p.eval_named_checked([(x, 2)]) is None)
}

///|
test "context polynomial preserves selected storage behavior" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let term = ContextPolynomial::from_named_terms_as_terms(context, [
    ([(x, 1U)], 2),
  ])
  let sparse = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 3),
  ])
  assert_eq((term + sparse).eval_named([(x, 4)]), 20)
}

///|
test "context polynomial partial evaluation preserves unknown variables" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U), (y, 1U)], 3),
    ([(y, 2U)], 1),
    ([], 4),
  ])
  let partial = p.eval_partial([(x, 2)])
  assert_eq(partial.eval_named([(x, 0), (y, 5)]), 59)
  assert_true(
    partial.eval_partial_named_checked([(@tt_core.Name::new("z"), 2)]) is None,
  )
}

///|
test "context polynomial substitutes variables by polynomials" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 2U)], 1),
    ([(y, 1U)], 1),
  ])
  let y_plus_one = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(y, 1U)], 1),
    ([], 1),
  ])
  let substituted = p.substitute([(x, Polynomial(y_plus_one))])
  assert_eq(substituted.eval_named([(x, 0), (y, 4)]), 29)
}

///|
test "context polynomial accepts type-theory names for substitutions" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U), (y, 1U)], 2),
    ([], 1),
  ])
  let partial = p.eval_partial_named([(x.to_type_theory_name(), 3)])
  assert_eq(partial.eval_named([(x, 0), (y, 4)]), 25)
  assert_true(
    p.eval_partial_named_checked([(@tt_core.Name::new("z"), 1)]) is None,
  )
}

///|
test "context substitution rejects invalid replacement variables" {
  let context = VariableContext::from_names(["x"])
  let other_context = VariableContext::from_names(["z"])
  let x = context.require_variable("x")
  let z = other_context.require_variable("z")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
  ])
  assert_true(p.eval_partial_checked([(z, 2)]) is None)
  assert_true(p.substitute_checked([(z, Scalar(2))]) is None)
}

///|
test "context substitution rejects polynomial from incompatible context" {
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
  assert_true(p.substitute_checked([(x, Polynomial(replacement))]) is None)
}

///|
test "context substitution rejects duplicate replacement variables" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
  ])
  assert_true(p.eval_partial_checked([(x, 1), (x, 2)]) is None)
  assert_true(p.substitute_checked([(x, Scalar(1)), (x, Scalar(2))]) is None)
}

///|
test "context variable constructor rejects foreign variables" {
  let context = VariableContext::from_names(["x"])
  let other_context = VariableContext::from_names(["z"])
  let z = other_context.require_variable("z")
  let variable : ContextPolynomial[Int]? = ContextPolynomial::variable_checked(
    context, z,
  )
  assert_true(variable is None)
}

///|
test "context substitution is simultaneous and one pass" {
  let context = VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
    ([(y, 1U)], 1),
  ])
  let y_poly = ContextPolynomial::variable(context, y)
  let substituted = p.substitute([(x, Polynomial(y_poly)), (y, Scalar(2))])
  assert_eq(substituted.eval_named([(x, 0), (y, 3)]), 5)
}

///|
test "zero substitutions are canonicalized" {
  let context = VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let p = ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 2U)], 3),
    ([], 1),
  ])
  let substituted = p.substitute([(x, Scalar(0))])
  assert_true(substituted.to_terms() == [(ExponentVector::one(), 1)])
}
