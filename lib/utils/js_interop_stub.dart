class JS {
  const JS([String? name]);
}

class JSFunction {}

class JSString {
  final String value;
  const JSString([this.value = '']);
  String get toDart => value;
}

extension FunctionToJsFunction on Function {
  JSFunction get toJS => JSFunction();
}
