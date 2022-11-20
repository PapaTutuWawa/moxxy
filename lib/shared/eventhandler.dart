import 'package:meta/meta.dart';

typedef EventCallbackType<E> = Future<void> Function(E event, { dynamic extra});

abstract class EventMatcher<E> {
  @mustCallSuper
  EventMatcher(this.callback);

  /// Return true if the event matches some criteria. False if
  /// not.
  bool matches(dynamic event);

  /// Function to be called when an event matches the description.
  EventCallbackType<E> callback;

  /// Function to be overriden by the matcher. Convert [event] to T and call the
  /// callback.
  Future<void> call(dynamic event, dynamic extra);
}

/// Matches an event according to if the event "is T".
class EventTypeMatcher<T> extends EventMatcher<T> {
  EventTypeMatcher(super.callback);

  @override
  bool matches(dynamic event) => event is T;

  @override
  Future<void> call(dynamic event, dynamic extra) async {
    await callback(event as T, extra: extra);
  }
}

/// A simple system for registering event handlers. Those handlers are checked whenever
/// [run] is called.
class EventHandler {
  EventHandler() : _matchers = List.empty(growable: true);
  final List<EventMatcher<dynamic>> _matchers;

  void addMatchers(List<EventMatcher<dynamic>> matchers) => _matchers.addAll(matchers);
  void addMatcher(EventMatcher<dynamic> matcher) => _matchers.add(matcher);

  /// Calls the callback of the first [EventMatcher] for which matches returns true.
  /// Returns true in that case. Otherwise, returns false if no [EventMatcher] matches.
  /// If extra is provided, it will be passed down to the callback if it is called.
  Future<bool> run(dynamic event, { dynamic extra }) async {
    for (final matcher in _matchers) {
      if (matcher.matches(event)) {
        await matcher.call(event, extra);
        return true;
      }
    }

    return false;
  }
}
