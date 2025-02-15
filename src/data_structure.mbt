///|
fn prob(probability : Float) -> Bool {
  @random.int(@random.new(), limit=100) <= (probability * 100.0).to_int()
}

///|
enum SkipList[A] {
  // Node(value, forward, downward)
  Node(A, SkipList[A], SkipList[A])
  Empty
}

///|
pub fn SkipList::new[A]() -> SkipList[A] {
  SkipList::Empty
}

///|
/// Searches for a target element in the skip list using natural ordering.
///
/// Parameters:
///
/// * `self` : The skip list to search in.
/// * `target` : The value to search for in the skip list.
///
/// Returns `true` if the target value is found in the skip list, `false`
/// otherwise.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "SkipList::contains" {
///   let list = SkipList::Node(
///     2,
///     SkipList::Node(3, SkipList::Empty, SkipList::Empty),
///     SkipList::Node(1, SkipList::Empty, SkipList::Empty),
///   )
///   inspect!(list.contains(3), content="true")
///   inspect!(list.contains(4), content="false")
/// }
/// ```
pub fn SkipList::contains[A : Compare](self : SkipList[A], target : A) -> Bool {
  match self {
    Node(value, forward, downward) =>
      if value == target {
        return true
      } else if value < target {
        return SkipList::contains(forward, target)
      } else {
        return SkipList::contains(downward, target)
      }
    Empty => false
  }
}

///|
/// Searches for a target element in the skip list and returns the sublist
/// starting from the target element if found.
///
/// Parameters:
///
/// * `self` : The skip list to search in.
/// * `target` : The value to search for in the skip list.
///
/// Returns an optional skip list (`Some(list)`) if the target value is found,
/// where `list` is the sublist starting from the target element. Returns `None`
/// if the target value is not found.
pub fn SkipList::find[A : Compare](
  self : SkipList[A],
  target : A
) -> SkipList[A]? {
  match self {
    Node(value, forward, downward) =>
      if value == target {
        return Some(self)
      } else if value < target {
        return SkipList::find(forward, target)
      } else {
        return SkipList::find(downward, target)
      }
    Empty => None
  }
}

///|
enum Ord {
  Less
  Equal
  Greater
}

///|
pub fn SkipList::insert[A : Compare](
  self : SkipList[A],
  value : A,
  probability~ : Float = 0.5
) -> SkipList[A] {
  match self {
    Node(v, forward, downward) =>
      if value < v {
        let new_downward = SkipList::Node(value, Empty, downward)
        if prob(probability) {
          SkipList::Node(value, Node(v, forward, new_downward), new_downward)
        } else {
          SkipList::Node(
            v,
            SkipList::insert(forward, value, probability~),
            downward,
          )
        }
      } else {
        SkipList::Node(
          v,
          SkipList::insert(forward, value, probability~),
          SkipList::insert(downward, value, probability~),
        )
      }
    Empty =>
      if prob(probability) {
        SkipList::Node(value, Empty, Node(value, Empty, Empty))
      } else {
        SkipList::Node(value, Empty, Empty)
      }
  }
}

///|
enum SkipListRuled[A] {
  // Node(rule, value, forward, downward)
  Node((A, A) -> Ord, A, SkipListRuled[A], SkipListRuled[A])
  Empty((A, A) -> Ord)
}

///|
pub fn SkipListRuled::new[A](rule : (A, A) -> Ord) -> SkipListRuled[A] {
  SkipListRuled::Empty(rule)
}

///|
pub fn SkipListRuled::contains[A](self : SkipListRuled[A], target : A) -> Bool {
  match self {
    Node(rule, value, forward, downward) =>
      match rule(value, target) {
        Ord::Equal => true
        Ord::Less => SkipListRuled::contains(forward, target)
        Ord::Greater => SkipListRuled::contains(downward, target)
      }
    Empty(_) => false
  }
}

///|
pub fn SkipListRuled::find[A](
  self : SkipListRuled[A],
  target : A
) -> SkipListRuled[A]? {
  match self {
    Node(rule, value, forward, downward) =>
      match rule(value, target) {
        Ord::Equal => Some(self)
        Ord::Less => SkipListRuled::find(forward, target)
        Ord::Greater => SkipListRuled::find(downward, target)
      }
    Empty(_) => None
  }
}

///|
pub fn SkipListRuled::insert[A : Compare](
  self : SkipListRuled[A],
  value : A,
  probability~ : Float = 0.5
) -> SkipListRuled[A] {
  match self {
    Node(rule, v, forward, downward) =>
      if value < v {
        let new_downward = SkipListRuled::Node(
          rule,
          value,
          Empty(rule),
          downward,
        )
        if prob(probability) {
          SkipListRuled::Node(
            rule,
            value,
            Node(rule, v, forward, new_downward),
            new_downward,
          )
        } else {
          SkipListRuled::Node(
            rule,
            v,
            SkipListRuled::insert(forward, value, probability~),
            downward,
          )
        }
      } else {
        SkipListRuled::Node(
          rule,
          v,
          SkipListRuled::insert(forward, value, probability~),
          SkipListRuled::insert(downward, value, probability~),
        )
      }
    Empty(rule) =>
      if prob(probability) {
        SkipListRuled::Node(
          rule,
          value,
          Empty(rule),
          Node(rule, value, Empty(rule), Empty(rule)),
        )
      } else {
        SkipListRuled::Node(rule, value, Empty(rule), Empty(rule))
      }
  }
}
