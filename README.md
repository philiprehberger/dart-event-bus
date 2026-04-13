# philiprehberger_event_bus

[![Tests](https://github.com/philiprehberger/dart-event-bus/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-event-bus/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_event_bus.svg)](https://pub.dev/packages/philiprehberger_event_bus)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-event-bus)](https://github.com/philiprehberger/dart-event-bus/commits/main)

Typed event bus with Stream subscriptions, sticky events, event history, and scoped lifecycle

## Requirements

- Dart >= 3.6

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_event_bus: ^0.4.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_event_bus/philiprehberger_event_bus.dart';

final bus = EventBus();
```

### Fire and Listen

```dart
bus.on<String>().listen((event) {
  print('Received: $event');
});

bus.fire('hello');
```

### Typed Events

```dart
class UserLoggedIn {
  final String userId;
  UserLoggedIn(this.userId);
}

bus.on<UserLoggedIn>().listen((event) {
  print('User logged in: ${event.userId}');
});

bus.fire(UserLoggedIn('user-123'));
```

### Sticky Events

Sticky events are stored and replayed to new subscribers:

```dart
bus.fireSticky(UserLoggedIn('user-456'));

// New listener immediately receives the last sticky event
bus.on<UserLoggedIn>().listen((event) {
  print('Got sticky: ${event.userId}');
});

// Retrieve the last sticky event directly
final last = bus.lastSticky<UserLoggedIn>();

// Clear when no longer needed
bus.clearSticky<UserLoggedIn>();
```

### One-Time Listener

Listen for a single event and automatically unsubscribe:

```dart
final event = await bus.once<UserLoggedIn>();
print('Got one: ${event.userId}');
```

### Event History

Store past events and replay them to new subscribers:

```dart
bus.enableHistory<String>(maxSize: 50);

bus.fire('first');
bus.fire('second');

// Retrieve stored events
print(bus.history<String>()); // ['first', 'second']

// New subscriber receives history then live events
bus.onWithHistory<String>().listen((event) {
  print(event); // 'first', 'second', then any new events
});

// Clear stored events but keep collecting
bus.clearHistory<String>();

// Stop collecting history entirely
bus.disableHistory<String>();
```

### Wildcard Listener

Listen to all events regardless of type — useful for logging and debugging:

```dart
bus.onAny().listen((event) {
  print('Event fired: $event');
});

bus.fire('hello');
bus.fire(42);
// Prints: Event fired: hello
// Prints: Event fired: 42
```

### Listener Introspection

Check whether the bus has active listeners:

```dart
print(bus.hasListeners); // false

final sub = bus.on<String>().listen((_) {});
print(bus.hasListeners);  // true
print(bus.listenerCount); // 1

sub.cancel();
print(bus.listenerCount); // 0
```

### Dispose

```dart
bus.dispose();
```

After calling `dispose()`, no more events can be fired or received.

## API

| Method | Description |
|--------|-------------|
| `fire<T>(T event)` | Dispatch an event to all listeners of type `T` |
| `on<T>()` | Subscribe to events of type `T`, returns `Stream<T>` |
| `onAny()` | Subscribe to all events regardless of type, returns `Stream<dynamic>` |
| `once<T>()` | Returns a `Future<T>` that completes with the next event, then auto-cancels |
| `fireSticky<T>(T event)` | Dispatch a sticky event that replays to new subscribers |
| `lastSticky<T>()` | Get the last sticky event of type `T`, or `null` |
| `clearSticky<T>()` | Remove the stored sticky event of type `T` |
| `enableHistory<T>({int maxSize})` | Enable event history for type `T` with a max capacity |
| `history<T>()` | Get stored events of type `T` as an unmodifiable list |
| `onWithHistory<T>()` | Stream that emits stored history first, then live events |
| `clearHistory<T>()` | Clear stored events of type `T` without disabling collection |
| `disableHistory<T>()` | Stop collecting history for type `T` and discard stored events |
| `hasListeners` | Whether any listeners are currently active |
| `listenerCount` | Number of active stream subscriptions |
| `dispose()` | Close the bus and release all resources |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/dart-event-bus)

🐛 [Report issues](https://github.com/philiprehberger/dart-event-bus/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/dart-event-bus/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
