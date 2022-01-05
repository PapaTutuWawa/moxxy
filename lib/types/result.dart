class Result<S, V> {
  final S _state;
  final V _value;

  Result(S state, V value) : _state = state, _value = value;

  S getState() => this._state;
  V getValue() => this._value;
}
