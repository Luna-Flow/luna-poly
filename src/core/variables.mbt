///|
/// Named variable with a stable context-local index.
struct Variable {
  name : String
  index : Int
} derive(Eq, Compare)

///|
pub fn Variable::name(self : Variable) -> String {
  self.name
}

///|
pub fn Variable::index(self : Variable) -> Int {
  self.index
}

///|
pub fn Variable::to_type_theory_name(self : Variable) -> @tt_core.Name {
  @tt_core.Name::new(self.name)
}

///|
pub impl Show for Variable with fn output(self, logger) {
  logger.write_string(self.name)
}

///|
/// Variable table used by context-aware multivariate polynomials.
struct VariableContext {
  variables : @core_vector.Vector[Variable]
} derive(Eq)

///|
pub fn VariableContext::new() -> VariableContext {
  { variables: @core_vector.from_array([]) }
}

///|
fn VariableContext::has_name(self : VariableContext, name : String) -> Bool {
  for variable in self.variables {
    if variable.name == name {
      return true
    }
  }
  false
}

///|
pub fn VariableContext::from_names_checked(
  names : Array[String],
) -> VariableContext? {
  let mut context = VariableContext::new()
  for name in names {
    match context.extend_checked(name) {
      None => return None
      Some(next) => context = next.0
    }
  }
  Some(context)
}

///|
pub fn VariableContext::from_names(names : Array[String]) -> VariableContext {
  match VariableContext::from_names_checked(names) {
    None => abort("VariableContext contains duplicate variable names")
    Some(context) => context
  }
}

///|
pub fn VariableContext::extend_checked(
  self : VariableContext,
  name : String,
) -> (VariableContext, Variable)? {
  if self.has_name(name) {
    return None
  }
  let variable : Variable = { name, index: self.variables.length() }
  let variables = self.variables.iter().to_array()
  variables.push(variable)
  Some(({ variables: @core_vector.from_array(variables) }, variable))
}

///|
pub fn VariableContext::extend(
  self : VariableContext,
  name : String,
) -> (VariableContext, Variable) {
  match self.extend_checked(name) {
    None => abort("VariableContext contains duplicate variable names")
    Some(result) => result
  }
}

///|
pub fn VariableContext::size(self : VariableContext) -> Int {
  self.variables.length()
}

///|
pub fn VariableContext::variables(self : VariableContext) -> Array[Variable] {
  self.variables.iter().to_array()
}

///|
pub fn VariableContext::get(self : VariableContext, index : Int) -> Variable? {
  if index < 0 || index >= self.size() {
    None
  } else {
    Some(self.variables[index])
  }
}

///|
pub fn VariableContext::variable(
  self : VariableContext,
  name : String,
) -> Variable? {
  for variable in self.variables {
    if variable.name == name {
      return Some(variable)
    }
  }
  None
}

///|
pub fn VariableContext::variable_by_type_theory_name(
  self : VariableContext,
  name : @tt_core.Name,
) -> Variable? {
  self.variable(name.text())
}

///|
pub fn VariableContext::require_type_theory_name(
  self : VariableContext,
  name : @tt_core.Name,
) -> Variable {
  match self.variable_by_type_theory_name(name) {
    None => abort("Unknown type-theory variable name")
    Some(variable) => variable
  }
}

///|
pub fn VariableContext::require_variable(
  self : VariableContext,
  name : String,
) -> Variable {
  match self.variable(name) {
    None => abort("Unknown variable name")
    Some(variable) => variable
  }
}

///|
pub fn VariableContext::contains(
  self : VariableContext,
  variable : Variable,
) -> Bool {
  match self.get(variable.index) {
    None => false
    Some(current) => current == variable
  }
}

///|
pub impl Show for VariableContext with fn output(self, logger) {
  logger.write_string("VariableContext(")
  for i in 0..<self.size() {
    if i > 0 {
      logger.write_string(", ")
    }
    logger.write_object(self.variables[i])
  }
  logger.write_char(')')
}
