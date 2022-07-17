/// Class that is supposed to by used with a state type S and a value type V.
/// The state indicates if an action was successful or not, while the value
/// type indicates the return value, i.e. a result in a computation or the
/// actual error description.
class Result<S, V> {

  Result(S state, V value) : _state = state, _value = value;
  final S _state;
  final V _value;

  S getState() => _state;
  V getValue() => _value;
}
