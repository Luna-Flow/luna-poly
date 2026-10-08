///|
/// Canonical exponent vector. Trailing zero exponents are never stored.
struct ExponentVector {
  exponents : @core_vector.Vector[UInt]
  degree : UInt
} derive(Debug)

///|
fn ExponentVector::from_vector(
  values : @core_vector.Vector[UInt],
) -> ExponentVector {
  let mut length = values.length()
  while length > 0 && values[length - 1] == 0 {
    length = length - 1
  }
  let exponents = @core_vector.makei(length, fn(i) { values[i] })
  let mut degree = 0U
  for exponent in exponents {
    degree = degree + exponent
  }
  { exponents, degree, }
}

///|
pub fn ExponentVector::from_array(values : Array[UInt]) -> ExponentVector {
  ExponentVector::from_vector(@core_vector.from_array(values))
}

///|
pub fn ExponentVector::one() -> ExponentVector {
  { exponents: @core_vector.from_array([]), degree: 0, }
}

///|
pub fn ExponentVector::length(self : ExponentVector) -> Int {
  self.exponents.length()
}

///|
pub fn ExponentVector::degree(self : ExponentVector) -> UInt {
  self.degree
}

///|
pub fn ExponentVector::is_one(self : ExponentVector) -> Bool {
  self.exponents.length() == 0
}

///|
#alias("_[_]")
pub fn ExponentVector::get(self : ExponentVector, index : Int) -> UInt {
  match self.get_checked(index) {
    None => abort("ExponentVector index out of bounds")
    Some(value) => value
  }
}

///|
pub fn ExponentVector::get_checked(self : ExponentVector, index : Int) -> UInt? {
  if index < 0 {
    None
  } else if index < self.length() {
    Some(self.exponents[index])
  } else {
    Some(0)
  }
}

///|
pub fn ExponentVector::with_exponent(
  self : ExponentVector,
  index : Int,
  value : UInt,
) -> ExponentVector {
  match self.with_exponent_checked(index, value) {
    None => abort("ExponentVector index out of bounds")
    Some(vector) => vector
  }
}

///|
pub fn ExponentVector::with_exponent_checked(
  self : ExponentVector,
  index : Int,
  value : UInt,
) -> ExponentVector? {
  if index < 0 {
    return None
  }
  let length = @cmp.maximum(self.length(), index + 1)
  let values = @core_vector.makei(length, fn(i) {
    if i == index {
      value
    } else {
      self[i]
    }
  })
  Some(ExponentVector::from_vector(values))
}

///|
pub fn ExponentVector::to_array(self : ExponentVector) -> Array[UInt] {
  self.exponents.iter().to_array()
}

///|
pub impl One for ExponentVector with fn one() {
  ExponentVector::one()
}

///|
pub impl Mul for ExponentVector with fn mul(self, other) {
  let length = @cmp.maximum(self.length(), other.length())
  ExponentVector::from_vector(
    @core_vector.makei(length, fn(i) { self[i] + other[i] }),
  )
}

///|
pub impl Eq for ExponentVector with fn equal(self, other) {
  self.degree == other.degree && self.exponents == other.exponents
}

///|
pub impl Compare for ExponentVector with fn compare(self, other) {
  if self.degree != other.degree {
    self.degree.compare(other.degree)
  } else {
    let length = @cmp.maximum(self.length(), other.length())
    for i = length - 1; i >= 0; i = i - 1 {
      let ordering = self[i].compare(other[i])
      if ordering != 0 {
        break ordering
      }
    } nobreak {
      0
    }
  }
}

///|
pub impl Hash for ExponentVector with fn hash_combine(self, hasher) {
  hasher.combine_uint(self.degree)
  for exponent in self.exponents {
    hasher.combine_uint(exponent)
  }
}

///|
pub impl Show for ExponentVector with fn output(self, logger) {
  if self.is_one() {
    logger.write_char('1')
    return
  }
  let mut first = true
  for i in 0..<self.length() {
    let exponent = self.exponents[i]
    if exponent != 0 {
      if !first {
        logger.write_string(" * ")
      }
      first = false
      if i == 0 {
        logger.write_char('x')
      } else {
        logger..write_string("x_").write_object(i)
      }
      if exponent != 1 {
        logger..write_char('^').write_object(exponent)
      }
    }
  }
}

///|
test "exponent vector is canonical and immutable" {
  let source = [1U, 2, 0, 0]
  let vector = ExponentVector::from_array(source)
  source[0] = 9
  assert_true(vector.to_array() == [1U, 2])
  assert_eq(vector.degree(), 3U)
  let updated = vector.with_exponent(1, 0)
  assert_true(vector.to_array() == [1U, 2])
  assert_true(updated.to_array() == [1U])
}

///|
test "exponent vector separates its factors" {
  inspect(ExponentVector::from_array([1, 1]), content="x * x_1")
  inspect(ExponentVector::from_array([2, 0, 3]), content="x^2 * x_2^3")
  inspect(ExponentVector::from_array([0, 1]), content="x_1")
  inspect(ExponentVector::one(), content="1")
}
