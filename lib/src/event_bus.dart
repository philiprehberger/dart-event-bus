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

  /// Fire an [event] to all listeners of type [T].
  void fire<T>(T event) {
    _controller.add(event);
  }

  /// Fire a sticky [event]. New subscribers of type [T] will immediately
  /// receive the last sticky event.
  void fireSticky<T>(T event) {
    _stickyEvents[T] = event;
    _controller.add(event);
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

  /// Listen to events of type [T].
  ///
  /// If a sticky event of type [T] exists, it is emitted immediately
  /// to the new listener.
  Stream<T> on<T>() {
    final stream = _controller.stream.where((event) => event is T).cast<T>();
    final sticky = lastSticky<T>();
    if (sticky != null) {
      return Stream<T>.value(sticky).followedBy(stream);
    }
    return stream;
  }

  /// Close the event bus and release resources.
  ///
  /// After calling dispose, no more events can be fired or received.
  void dispose() {
    _controller.close();
    _stickyEvents.clear();
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
