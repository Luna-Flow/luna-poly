///| A hack to view private fields of a struct
struct ArrayInternal[T] {
  buf : UninitializedArray[T]
  len : Int
}

///| Value coerce function
fn coerce[A, B](a : A) -> B = "%identity"

///|
fn unsafe_array_make[T](len : Int) -> Array[T] {
  let it : ArrayInternal[T] = { buf: UninitializedArray::make(len), len }
  coerce(it)
}

///|
fn op_set[T](self : ArrayInternal[T], index : Int, value : T) -> Unit {
  UninitializedArray::op_set(self.buf, index, value)
}

///|
fn length[T](self : ArrayInternal[T]) -> Int {
  self.len
}
