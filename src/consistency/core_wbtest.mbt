///|
test "dense immutable and mutable operations stay aligned" {
  let immutable = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  let mutable = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  assert_true(immutable.to_coefficients() == mutable.to_coefficients())
  assert_true(
    (immutable * immutable).to_coefficients() ==
    (mutable * mutable).to_coefficients(),
  )
  assert_true(
    immutable.substitute(immutable).to_coefficients() ==
    mutable.substitute(mutable).to_coefficients(),
  )
  assert_eq(immutable.eval(2), mutable.eval(2))
}

///|
test "natural power follows arithmetic checked semantics" {
  let immutable = @immut.DensePolynomial::from_coefficients([1, 1])
  let mutable = @mutable.DensePolynomial::from_coefficients([1, 1])
  let context = @arithmetic.ArithmeticContext::new(0)
  let imm_zero = @arithmetic.PowNatChecked::pow_nat_checked(
    immutable, 0, context,
  ).unwrap()
  let mut_zero = @arithmetic.PowNatChecked::pow_nat_checked(mutable, 0, context).unwrap()
  assert_true(imm_zero.to_coefficients() == [1])
  assert_true(mut_zero.to_coefficients() == [1])
  assert_true(
    immutable.pow(5).to_coefficients() == mutable.pow(5).to_coefficients(),
  )
}

///|
test "mutable updates do not affect immutable conversions" {
  let mutable = @mutable.DensePolynomial::from_coefficients([1, 2, 3])
  let immutable = mutable.to_immut()
  mutable.set_coefficient(0, 9)
  assert_true(immutable.to_coefficients() == [1, 2, 3])
  assert_true(mutable.to_coefficients() == [9, 2, 3])
}

///|
test "multivariate representations stay aligned" {
  let terms = [([2U], 1), ([1U], 2), ([], 1)]
  let imm_term = @immut.TermPolynomial::from_array(terms)
  let mut_term = @mutable.TermPolynomial::from_array(terms)
  let imm_sparse = @immut.SparsePolynomial::from_array(terms)
  let mut_sparse = @mutable.SparsePolynomial::from_array(terms)
  assert_eq(imm_term.eval([2]), 9)
  assert_eq(mut_term.eval([2]), 9)
  assert_eq(imm_sparse.eval([2]), 9)
  assert_eq(mut_sparse.eval([2]), 9)
  assert_true(
    imm_term.pow(3).to_terms().map(fn(term) { (term.0.to_array(), term.1) }) ==
    mut_term.pow(3).to_terms().map(fn(term) { (term.0.to_array(), term.1) }),
  )
}

///|
fn[P : @immut.UnivariatePolynomial] is_univariate_zero(value : P) -> Bool {
  @immut.IsZero::is_zero(value)
}

///|
fn[P : @immut.MultivariatePolynomial] multivariate_term_count(value : P) -> Int {
  @immut.HasTermCount::term_count(value)
}

///|
fn[T : @immut.Zero] zero_from_immut() -> T {
  T::zero()
}

///|
fn[T : @mutable.One] one_from_mutable() -> T {
  T::one()
}

///|
test "facade traits and ops hide concrete polynomial representation" {
  let dense = @immut.DensePolynomial::from_coefficients([1, 2, 3])
  let dense_ops = @immut.DensePolynomial::ops()
  assert_false(is_univariate_zero(dense))
  assert_eq(dense_ops.eval(dense, 2), 17)

  let term = @immut.TermPolynomial::from_array([([1U], 2), ([], 1)])
  let sparse = @immut.SparsePolynomial::from_array([([1U], 2), ([], 1)])
  let term_ops = @immut.TermPolynomial::ops()
  let sparse_ops = @immut.SparsePolynomial::ops()
  assert_eq(multivariate_term_count(term), 2)
  assert_eq(multivariate_term_count(sparse), 2)
  assert_eq(term_ops.eval_indexed(term, [3]), 7)
  assert_eq(sparse_ops.eval_indexed(sparse, [3]), 7)
}

///|
test "mutable facade implements shared traits" {
  let dense = @mutable.DensePolynomial::from_coefficients([1, 2])
  let dense_ops = @mutable.DensePolynomial::ops()
  assert_false(@mutable.IsZero::is_zero(dense))
  assert_eq(dense_ops.eval(dense, 3), 7)
  @mutable.Clearable::clear(dense)
  assert_true(@mutable.IsZero::is_zero(dense))
}

///|
test "polynomial shapes expose linear algebra style dimensions" {
  let dense = @immut.DensePolynomial::from_coefficients([1, 2, 0])
  let dense_shape = @immut.HasShape::shape(dense)
  assert_eq(dense_shape.arity(), 1)
  assert_true(dense_shape.term_count() is None)

  let sparse = @immut.SparsePolynomial::from_array([([1U, 0], 2), ([0U, 1], 3)])
  let sparse_shape = @immut.HasShape::shape(sparse)
  assert_eq(sparse_shape.arity(), 2)
  assert_true(sparse_shape.term_count() == Some(2))

  let context = @immut.VariableContext::from_names(["x"])
  let x = context.require_variable("x")
  let contextual = @immut.ContextPolynomial::from_named_terms_as_sparse(
    context,
    [([(x, 1U)], 2)],
  )
  let contextual_shape = @immut.HasShape::shape(contextual)
  assert_true(contextual_shape.is_compatible_with(contextual_shape))
  assert_false(contextual_shape.is_compatible_with(sparse_shape))
}

///|
test "checked APIs expose contract failures without aborting" {
  let dense = @immut.DensePolynomial::from_coefficients([1, 2])
  assert_true(dense.coefficient_checked(-1) is None)
  assert_true(@immut.DensePolynomial::monomial_checked(-1, 2) is None)
  assert_true(dense.scale_checked(-1, 2) is None)
  assert_true(dense.coefficient_checked(5) == Some(0))

  let exponent = @immut.ExponentVector::from_array([1U])
  assert_true(exponent.get_checked(-1) is None)
  assert_true(exponent.with_exponent_checked(-1, 2) is None)

  let term = @immut.TermPolynomial::from_array([([1U, 1], 2)])
  let sparse = @immut.SparsePolynomial::from_array([([1U, 1], 2)])
  assert_true(term.eval_checked([3]) is None)
  assert_true(sparse.eval_checked([3]) is None)
}

///|
test "extended ops records support generic construction and algebra" {
  let dense_ops = @immut.DensePolynomial::ops()
  let dense = dense_ops.from_coefficients([1, 1])
  let dense_product = dense_ops.mul(dense, dense)
  assert_true(dense_product.to_coefficients() == [1, 2, 1])
  assert_true(dense_ops.scale_checked(dense, -1, 2) is None)

  let sparse_ops = @immut.SparsePolynomial::ops()
  let sparse = sparse_ops.from_terms([
    (@immut.ExponentVector::from_array([1U]), 2),
    (@immut.ExponentVector::one(), 1),
  ])
  let doubled = sparse_ops.add(sparse, sparse)
  assert_eq(sparse_ops.eval_indexed_checked(doubled, [3]).unwrap(), 14)
}

///|
test "facades re-export algebra capability traits" {
  let zero : Int = zero_from_immut()
  let one : Int = one_from_mutable()
  assert_eq(zero, 0)
  assert_eq(one, 1)
}

///|
test "mutable context delegates partial evaluation" {
  let context = @mutable.VariableContext::from_names(["x", "y"])
  let x = context.require_variable("x")
  let y = context.require_variable("y")
  let p = @mutable.ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U), (y, 1U)], 2),
    ([], 1),
  ])
  let partial = p.eval_partial([(x, 3)])
  assert_eq(partial.eval_named([(x, 0), (y, 4)]), 25)
}

///|
test "mutable context delegates substitution failures" {
  let context = @mutable.VariableContext::from_names(["x"])
  let other_context = @mutable.VariableContext::from_names(["z"])
  let x = context.require_variable("x")
  let z = other_context.require_variable("z")
  let p = @mutable.ContextPolynomial::from_named_terms_as_sparse(context, [
    ([(x, 1U)], 1),
  ])
  assert_true(p.eval_partial_checked([(z, 1)]) is None)
  assert_true(p.eval_partial_checked([(x, 1), (x, 2)]) is None)
}
