import "package:meta/meta.dart";

/// Base event class. All events must extend this.
abstract class BaseEvent {}

typedef EventCallbackType = Future<void> Function(BaseEvent event, { dynamic extra});

abstract class EventMatcher {
  @mustCallSuper
  EventMatcher(this.callback);

  /// Return true if the event matches some criteria. False if
  /// not.
  bool matches(BaseEvent event);

  /// Function to be called when an event matches the description.
  EventCallbackType callback;
}

/// Matches an event according to if the event "is T".
class EventTypeMatcher<T extends BaseEvent> extends EventMatcher {
  EventTypeMatcher(EventCallbackType callback) : super(callback);

  @override
  bool matches(BaseEvent event) => event is T;
}

/// A simple system for registering event handlers. Those handlers are checked whenever
/// [run] is called.
class EventHandler {
  final List<EventMatcher> _matchers;

  EventHandler() : _matchers = List.empty(growable: true);

  void addMatchers(List<EventMatcher> matchers) => _matchers.addAll(matchers);
  void addMatcher(EventMatcher matcher) => _matchers.add(matcher);

  /// Calls the callback of the first [EventMatcher] for which [matches] returns true.
  /// Returns true in that case. Otherwise, returns false if no [EventMatcher] matches.
  /// If extra is provided, it will be passed down to the callback if it is called.
  bool run(BaseEvent event, { dynamic extra }) {
    for (final matcher in _matchers) {
      if (matcher.matches(event)) {
        matcher.callback(event, extra: extra);
        return true;
      }
    }

    return false;
  }
}
