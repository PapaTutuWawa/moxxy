import "dart:async";

import "package:synchronized/synchronized.dart";
import "package:uuid/uuid.dart";
import "package:logging/logging.dart";
import "package:meta/meta.dart";

/// Interface to allow arbitrary data to be sent as long as it can be
/// JSON serialized/deserialized.
class JsonImplementation {
  JsonImplementation();

  Map<String, dynamic> toJson() => {};
  factory JsonImplementation.fromJson(Map<String, dynamic> json) {
    return JsonImplementation();
  }
}

/// Wrapper class that adds an ID to the data packet to be sent.
class DataWrapper<T extends JsonImplementation> {
  final String id;
  final T data;

  const DataWrapper(
    this.id,
    this.data
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "data": data.toJson()
  };

  static DataWrapper fromJson<T extends JsonImplementation>(Map<String, dynamic> json) => DataWrapper<T>(
    json["id"]! as String,
    json["data"]! as T
  );
  
  DataWrapper reply(T newData) => DataWrapper(id, newData);
}

/// This class is useful in contexts where data is sent between two parties, e.g. the
/// UI and the background service and a correlation between requests and responses is
/// to be enabled.
///
/// awaiting [sendData] will return a [Future] that will resolve to the reresponse when
/// received via [onData].
abstract class AwaitableDataSender<
  S extends JsonImplementation,
  R extends JsonImplementation
> {
  final Lock _lock;
  final Map<String, Completer<R>> _awaitables;
  final Uuid _uuid;
  final Logger _log;

  @mustCallSuper
  AwaitableDataSender() : _awaitables = {}, _uuid = const Uuid(), _lock = Lock(), _log = Logger("AwaitableDataSender");

  @visibleForTesting
  Map<String, Completer> getAwaitables() => _awaitables;

  /// Called after an awaitable has been added.
  @visibleForTesting
  void onAdd() {}

  /// NOTE: Must be overwritten by the actual implementation
  @visibleForOverriding
  Future<void> sendDataImpl(DataWrapper data);
  
  /// Sends [data] using [sendDataImpl]. If [awaitable] is true, then a
  /// Future will be returned that can be used to await a response. If it
  /// is false, then null will be imediately resolved.
  Future<R?> sendData(S data, { bool awaitable = true, @visibleForTesting String? id }) async {
    final _id = id ?? _uuid.v4();
    Future<R?> future = Future.value(null);
    _log.fine("sendData: Waiting to acquire lock...");
    await _lock.synchronized(() async {
        _log.fine("sendData: Done");
        if (awaitable) {
          _awaitables[_id] = Completer();
          onAdd();
        }
        
        await sendDataImpl(
          DataWrapper<S>(
            _id,
            data
          )
        );

        if (awaitable) {
          future = _awaitables[_id]!.future;
        }

        _log.fine("sendData: Releasing lock...");
    });

    return future;
  }

  /// Should be called when a [DataWrapper] has been received. Will resolve
  /// the promise received from [sendData].
  Future<bool> onData(DataWrapper<R> data) async {
    bool found = false;
    Completer? completer;
    _log.fine("onData: Waiting to acquire lock...");
    await _lock.synchronized(() async {
        _log.fine("onData: Done");
        completer = _awaitables[data.id];
        if (completer != null) {
          _awaitables.remove(data.id);
          found = true;
        }

        _log.fine("onData: Releasing lock");
    });

    if (found) {
      completer!.complete(data.data);
    }
    
    return found;
  }
}
