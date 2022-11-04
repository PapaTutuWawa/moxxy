class Result<T, V> {

  const Result(this._data) : assert(_data is T || _data is V, 'Invalid data type: Must be either $T or $V');
  final dynamic _data;

  bool isType<S>() => _data is S;

  S get<S>() {
    assert(_data is S, 'Data is not $S');

    return _data as S;
  }
}
