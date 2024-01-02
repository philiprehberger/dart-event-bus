# philiprehberger_event_bus

[![Tests](https://github.com/philiprehberger/dart-event-bus/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/dart-event-bus/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/philiprehberger_event_bus.svg)](https://pub.dev/packages/philiprehberger_event_bus)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/dart-event-bus)](https://github.com/philiprehberger/dart-event-bus/commits/main)

Typed event bus with Stream subscriptions, sticky events, and scoped lifecycle

## Requirements

- Dart >= 3.6

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  philiprehberger_event_bus: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Usage

```dart
import 'package:philiprehberger_event_bus/event_bus.dart';

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
| `fireSticky<T>(T event)` | Dispatch a sticky event that replays to new subscribers |
| `lastSticky<T>()` | Get the last sticky event of type `T`, or `null` |
| `clearSticky<T>()` | Remove the stored sticky event of type `T` |
| `dispose()` | Close the bus and release all resources |

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart test
```

## Support

If you find this project useful:

- [Star the repo](https://github.com/philiprehberger/dart-event-bus)
- [Report issues](https://github.com/philiprehberger/dart-event-bus/issues?q=is%3Aissue+is%3Aopen+label%3Abug)
- [Suggest features](https://github.com/philiprehberger/dart-event-bus/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)
- [Sponsor development](https://github.com/sponsors/philiprehberger)
- [All Open Source Projects](https://philiprehberger.com/open-source-packages)
- [GitHub Profile](https://github.com/philiprehberger)
- [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
