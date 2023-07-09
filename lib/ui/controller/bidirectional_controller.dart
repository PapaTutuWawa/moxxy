import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

class BidirectionalController<T> {
  BidirectionalController({
    required this.pageSize,
    required this.maxPageAmount,
    this.scrollActivationOffset = 10,
  }) {
    _controller.addListener(handleScroll);
  }

  /// The offset for scrolling at which to trigger data fetching.
  final double scrollActivationOffset;

  /// The amount of data items to expect per fetch.
  final int pageSize;

  /// The amount of pages to keep in the cache before evicting items
  final int maxPageAmount;

  /// The controller that deals with scrolling
  final ScrollController _controller = ScrollController();
  ScrollController get scrollController => _controller;

  /// The backing cache:
  /// 0: The oldest data item we know about
  /// _cache.length - 1: The newest data item we know about
  final List<T> _cache = List<T>.empty(growable: true);
  final StreamController<List<T>> _dataStreamController =
      StreamController<List<T>>.broadcast();
  Stream<List<T>> get dataStream => _dataStreamController.stream;

  //@protected
  List<T> get cache => _cache;

  /// True if the cache has exceeded the size limit of pageSize * maxPageAmount.
  bool get _isCacheTooBig => _cache.length >= pageSize * maxPageAmount;

  /// Flag indicating whether we are currently fetching data
  bool _isFetching = false;
  bool get isFetching => _isFetching;
  final StreamController<bool> _isFetchingStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get isFetchingStream => _isFetchingStreamController.stream;

  /// Flag indicating whether we are able to request newer data
  @protected
  bool hasNewerData = false;

  /// Flag indicating whether we are able to request older data
  @protected
  bool hasOlderData = true;

  /// Flag indicating whether data has been loaded at least once
  bool hasFetchedOnce = false;

  /// True if we are scrolled to the bottom of the view. False, otherwise.
  bool get isScrolledToBottom => _controller.offset <= scrollActivationOffset;

  /// True if we are scrolled to the top of the viwe. False, otherwise.
  bool get isScrolledToTop =>
      _controller.offset >=
      _controller.position.maxScrollExtent - scrollActivationOffset;

  @visibleForOverriding
  void handleScroll() {
    if (!_controller.hasClients) return;
    if (_isFetching) return;

    if (isScrolledToTop) {
      // Fetch older messages when we reach the top edge of the list
      unawaited(fetchOlderData());
    } else if (isScrolledToBottom) {
      // Fetch newer data when we reach the bottom edge of the list
      unawaited(_fetchNewerData());
    }
  }

  /// Set the _isFetching flag, but also update the UI using the stream
  void _setIsFetching(bool state) {
    _isFetching = state;
    _isFetchingStreamController.add(state);
  }

  Future<void> fetchOlderData() async {
    if (_isFetching || _cache.isEmpty && hasFetchedOnce) return;
    if (!hasOlderData) return;

    _setIsFetching(true);

    final data = await fetchOlderDataImpl(
      _cache.isEmpty ? null : _cache.first,
    );

    hasFetchedOnce = true;
    hasOlderData = data.length >= pageSize;

    // Don't trigger an update if we fetched nothing
    _setIsFetching(false);
    _cache.insertAll(0, data);

    // Evict items from the cache if we overstep the maximum
    if (_cache.length >= pageSize * maxPageAmount) {
      _cache.removeRange(_cache.length - 1 - pageSize, _cache.length);
      hasNewerData = true;
    }

    // Update the UI
    _setIsFetching(false);
    _dataStreamController.add(_cache);
  }

  Future<void> _fetchNewerData() async {
    if (_isFetching || _cache.isEmpty && hasFetchedOnce) return;
    if (!hasNewerData) return;

    _setIsFetching(true);

    final data = await fetchNewerDataImpl(
      _cache.isEmpty ? null : _cache.last,
    );

    hasFetchedOnce = true;
    hasNewerData = data.length >= pageSize;

    // Don't trigger an update if we fetched nothing
    if (data.isEmpty) {
      _setIsFetching(false);
      return;
    }

    _cache.addAll(data);

    // Evict items from the cache if we overstep the maximum
    if (_cache.length >= pageSize * maxPageAmount) {
      _cache.removeRange(0, pageSize);
      hasOlderData = true;
    }

    // Update the UI
    _setIsFetching(false);
    _dataStreamController.add(_cache);
  }

  @visibleForOverriding
  Future<List<T>> fetchOlderDataImpl(T? oldestElement) async {
    return [];
  }

  @visibleForOverriding
  Future<List<T>> fetchNewerDataImpl(T? newestElement) async {
    return [];
  }

  /// Add [item] to the cache, deal with the cache and update the UI.
  void addItem(T item) {
    _cache.add(item);

    if (_isCacheTooBig) {
      _cache.removeAt(0);
      hasOlderData = true;
    }

    _dataStreamController.add(_cache);
  }

  /// Adds [item] to the first index where [test] returns true.
  /// [test] takes the item and the next item (or null).
  bool addItemWhereFirst(bool Function(T, T?) test, T item) {
    var foundPlace = false;
    for (var i = 0; i < _cache.length; i++) {
      final nextItem = i + 1 < _cache.length ? _cache[i + 1] : null;
      if (test(_cache[i], nextItem)) {
        foundPlace = true;
        _cache.insert(i, item);
        break;
      }
    }

    // Update the UI
    if (foundPlace) {
      _dataStreamController.add(_cache);
    }

    return foundPlace;
  }

  /// Sends the current cache to the UI to force an update.
  @protected
  void forceUpdateUI() {
    _dataStreamController.add(_cache);
  }

  /// Replaces the first item for which [test] returns true with [newItem].
  bool replaceItem(bool Function(T) test, T newItem) {
    // We iterate in reverse as we can assume that the newer messages have a higher
    // likeliness of being updated than older messages.
    var found = false;
    for (var i = _cache.length - 1; i >= 0; i--) {
      if (test(_cache[i])) {
        _cache[i] = newItem;
        found = true;
        break;
      }
    }

    if (found) {
      _dataStreamController.add(_cache);
    }

    return found;
  }

  /// Animate to the bottom of the view.
  void animateToBottom() {
    _controller.animateTo(
      _controller.position.minScrollExtent,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 300),
    );
  }

  /// Dispose of the backing controller
  void dispose() {
    _controller.dispose();
  }
}
