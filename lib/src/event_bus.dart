import 'dart:async';

/// A typed event bus for decoupled communication.
///
/// Events are dispatched by type — listeners only receive events matching
/// the type they subscribed to.
///
/// ```dart
/// final bus = EventBus();
/// bus.on<String>().listen(print);
/// bus.fire('hello');
/// ```
class EventBus {
  final _controller = StreamController<dynamic>.broadcast();
  final _stickyEvents = <Type, dynamic>{};
  final Map<Type, List<dynamic>> _history = {};
  final Map<Type, int> _historyMaxSize = {};
  int _listenerCount = 0;

  /// Fire an [event] to all listeners of type [T].
  void fire<T>(T event) {
    _controller.add(event);
    if (_historyMaxSize.containsKey(T)) {
      final list = _history[T] ??= [];
      list.add(event);
      if (list.length > _historyMaxSize[T]!) {
        list.removeAt(0);
      }
    }
  }

  /// Fire a sticky [event]. New subscribers of type [T] will immediately
  /// receive the last sticky event.
  void fireSticky<T>(T event) {
    _stickyEvents[T] = event;
    _controller.add(event);
    if (_historyMaxSize.containsKey(T)) {
      final list = _history[T] ??= [];
      list.add(event);
      if (list.length > _historyMaxSize[T]!) {
        list.removeAt(0);
      }
    }
  }

  /// Get the last sticky event of type [T], or `null` if none.
  T? lastSticky<T>() {
    final event = _stickyEvents[T];
    return event is T ? event : null;
  }

  /// Clear the sticky event of type [T].
  void clearSticky<T>() {
    _stickyEvents.remove(T);
  }

  /// Returns a [Future] that completes with the next event of type [T].
  ///
  /// The subscription is automatically cancelled after the first event.
  Future<T> once<T>() {
    final completer = Completer<T>();
    late final StreamSubscription<T> subscription;
    subscription = on<T>().listen((event) {
      if (!completer.isCompleted) {
        completer.complete(event);
        subscription.cancel();
      }
    });
    return completer.future;
  }

  /// Enables event history for type [T] with a maximum of [maxSize] events.
  ///
  /// When history is enabled, fired events of type [T] are stored and can
  /// be replayed to new subscribers via [onWithHistory].
  void enableHistory<T>({int maxSize = 100}) {
    _historyMaxSize[T] = maxSize;
    _history[T] ??= [];
  }

  /// Returns stored events of type [T], or an empty list if history
  /// is not enabled for [T].
  List<T> history<T>() {
    return List<T>.unmodifiable((_history[T] ?? []).cast<T>());
  }

  /// Returns a stream that first emits all stored events of type [T],
  /// then continues with live events.
  Stream<T> onWithHistory<T>() async* {
    for (final event in history<T>()) {
      yield event;
    }
    yield* on<T>();
  }

  /// Whether there are any active listeners on this event bus.
  bool get hasListeners => _controller.hasListener;

  /// The number of active stream subscriptions created via [on] or [onWithHistory].
  int get listenerCount => _listenerCount;

  /// Listen to all events regardless of type.
  ///
  /// Returns a broadcast stream that fires for every event dispatched
  /// through this bus. Useful for logging and debugging.
  Stream<dynamic> onAny() {
    return _CountedStream<dynamic>(
      _controller.stream,
      onListen: () => _listenerCount++,
      onCancel: () => _listenerCount--,
    );
  }

  /// Listen to events of type [T].
  ///
  /// If a sticky event of type [T] exists, it is emitted immediately
  /// to the new listener.
  Stream<T> on<T>() {
    final stream = _controller.stream.where((event) => event is T).cast<T>();
    final sticky = lastSticky<T>();
    if (sticky != null) {
      return _CountedStream<T>(
        Stream<T>.value(sticky).followedBy(stream),
        onListen: () => _listenerCount++,
        onCancel: () => _listenerCount--,
      );
    }
    return _CountedStream<T>(
      stream,
      onListen: () => _listenerCount++,
      onCancel: () => _listenerCount--,
    );
  }

  /// Close the event bus and release resources.
  ///
  /// After calling dispose, no more events can be fired or received.
  void dispose() {
    _controller.close();
    _stickyEvents.clear();
    _history.clear();
    _historyMaxSize.clear();
  }
}

extension _StreamFollowedBy<T> on Stream<T> {
  /// Concatenate this stream with [other].
  Stream<T> followedBy(Stream<T> other) {
    final controller = StreamController<T>.broadcast();
    listen(
      controller.add,
      onError: controller.addError,
      onDone: () {
        other.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      },
    );
    return controller.stream;
  }
}

class _CountedStream<T> extends Stream<T> {
  _CountedStream(this._source, {required this.onListen, required this.onCancel});

  final Stream<T> _source;
  final void Function() onListen;
  final void Function() onCancel;

  @override
  StreamSubscription<T> listen(
    void Function(T event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onListen();
    final sub = _source.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
    return _CountedSubscription<T>(sub, onCancel);
  }

  @override
  bool get isBroadcast => _source.isBroadcast;
}

class _CountedSubscription<T> implements StreamSubscription<T> {
  _CountedSubscription(this._inner, this._onCancel);

  final StreamSubscription<T> _inner;
  final void Function() _onCancel;
  var _cancelled = false;

  @override
  Future<void> cancel() {
    if (!_cancelled) {
      _cancelled = true;
      _onCancel();
    }
    return _inner.cancel();
  }

  @override
  void onData(void Function(T data)? handleData) => _inner.onData(handleData);

  @override
  void onError(Function? handleError) => _inner.onError(handleError);

  @override
  void onDone(void Function()? handleDone) => _inner.onDone(handleDone);

  @override
  void pause([Future<void>? resumeSignal]) => _inner.pause(resumeSignal);

  @override
  void resume() => _inner.resume();

  @override
  bool get isPaused => _inner.isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => _inner.asFuture(futureValue);
}
