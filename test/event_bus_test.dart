import 'dart:async';

import 'package:philiprehberger_event_bus/philiprehberger_event_bus.dart';
import 'package:test/test.dart';

void main() {
  group('EventBus', () {
    late EventBus bus;

    setUp(() {
      bus = EventBus();
    });

    tearDown(() {
      bus.dispose();
    });

    test('fires and receives typed events', () async {
      final completer = Completer<String>();
      bus.on<String>().listen(completer.complete);
      bus.fire('hello');
      expect(await completer.future, equals('hello'));
    });

    test('only receives matching type', () async {
      final strings = <String>[];
      bus.on<String>().listen(strings.add);
      bus.fire(42);
      bus.fire('hello');
      await Future<void>.delayed(Duration(milliseconds: 50));
      expect(strings, equals(['hello']));
    });

    test('multiple listeners receive same event', () async {
      var count = 0;
      bus.on<int>().listen((_) => count++);
      bus.on<int>().listen((_) => count++);
      bus.fire(1);
      await Future<void>.delayed(Duration(milliseconds: 50));
      expect(count, equals(2));
    });

    test('sticky event is stored', () {
      bus.fireSticky('sticky-value');
      expect(bus.lastSticky<String>(), equals('sticky-value'));
    });

    test('lastSticky returns null when none set', () {
      expect(bus.lastSticky<String>(), isNull);
    });

    test('clearSticky removes sticky event', () {
      bus.fireSticky('sticky');
      bus.clearSticky<String>();
      expect(bus.lastSticky<String>(), isNull);
    });

    test('dispose closes the bus', () {
      bus.dispose();
      expect(() => bus.fire('after-dispose'), throwsStateError);
    });
  });

  group('once', () {
    test('resolves with first matching event', () async {
      final bus = EventBus();
      final future = bus.once<String>();
      bus.fire('hello');
      expect(await future, equals('hello'));
      bus.dispose();
    });

    test('does not receive subsequent events', () async {
      final bus = EventBus();
      final future = bus.once<String>();
      bus.fire('first');
      bus.fire('second');
      expect(await future, equals('first'));
      bus.dispose();
    });
  });

  group('history', () {
    test('stores events when enabled', () {
      final bus = EventBus();
      bus.enableHistory<String>(maxSize: 10);
      bus.fire('a');
      bus.fire('b');
      expect(bus.history<String>(), equals(['a', 'b']));
      bus.dispose();
    });

    test('evicts oldest when capacity exceeded', () {
      final bus = EventBus();
      bus.enableHistory<String>(maxSize: 2);
      bus.fire('a');
      bus.fire('b');
      bus.fire('c');
      expect(bus.history<String>(), equals(['b', 'c']));
      bus.dispose();
    });

    test('returns empty list when history not enabled', () {
      final bus = EventBus();
      bus.fire('a');
      expect(bus.history<String>(), isEmpty);
      bus.dispose();
    });

    test('onWithHistory emits history then live events', () async {
      final bus = EventBus();
      bus.enableHistory<String>(maxSize: 10);
      bus.fire('old');

      final events = <String>[];
      final sub = bus.onWithHistory<String>().listen(events.add);

      // Allow async to settle
      await Future<void>.delayed(Duration.zero);
      bus.fire('new');
      await Future<void>.delayed(Duration.zero);

      expect(events, equals(['old', 'new']));
      await sub.cancel();
      bus.dispose();
    });

    test('clearHistory empties stored events but keeps collection active', () {
      final bus = EventBus();
      bus.enableHistory<String>(maxSize: 10);
      bus.fire('a');
      bus.fire('b');
      bus.clearHistory<String>();
      expect(bus.history<String>(), isEmpty);

      bus.fire('c');
      expect(bus.history<String>(), equals(['c']));
      bus.dispose();
    });

    test('disableHistory stops collection and removes stored events', () {
      final bus = EventBus();
      bus.enableHistory<String>(maxSize: 10);
      bus.fire('a');
      bus.disableHistory<String>();
      expect(bus.history<String>(), isEmpty);

      bus.fire('b');
      expect(bus.history<String>(), isEmpty);
      bus.dispose();
    });
  });

  group('onAny', () {
    test('receives events of all types', () async {
      final bus = EventBus();
      final events = <dynamic>[];
      bus.onAny().listen(events.add);

      bus.fire('hello');
      bus.fire(42);
      bus.fire(true);
      await Future<void>.delayed(Duration(milliseconds: 50));

      expect(events, equals(['hello', 42, true]));
      bus.dispose();
    });

    test('receives typed class events', () async {
      final bus = EventBus();
      final events = <dynamic>[];
      bus.onAny().listen(events.add);

      bus.fire('a');
      bus.fire(1);
      await Future<void>.delayed(Duration(milliseconds: 50));

      expect(events.length, equals(2));
      expect(events[0], isA<String>());
      expect(events[1], isA<int>());
      bus.dispose();
    });

    test('tracks listener count', () {
      final bus = EventBus();
      final sub = bus.onAny().listen((_) {});
      expect(bus.listenerCount, equals(1));
      sub.cancel();
      expect(bus.listenerCount, equals(0));
      bus.dispose();
    });
  });

  group('hasListeners', () {
    test('false when no subscriptions', () {
      final bus = EventBus();
      expect(bus.hasListeners, isFalse);
      bus.dispose();
    });

    test('true after subscribing', () {
      final bus = EventBus();
      final sub = bus.on<String>().listen((_) {});
      expect(bus.hasListeners, isTrue);
      sub.cancel();
      bus.dispose();
    });
  });

  group('listenerCount', () {
    test('starts at 0', () {
      final bus = EventBus();
      expect(bus.listenerCount, equals(0));
      bus.dispose();
    });

    test('increments on subscribe', () {
      final bus = EventBus();
      final sub1 = bus.on<String>().listen((_) {});
      expect(bus.listenerCount, equals(1));
      final sub2 = bus.on<String>().listen((_) {});
      expect(bus.listenerCount, equals(2));
      sub1.cancel();
      sub2.cancel();
      bus.dispose();
    });

    test('decrements on cancel', () {
      final bus = EventBus();
      final sub = bus.on<String>().listen((_) {});
      expect(bus.listenerCount, equals(1));
      sub.cancel();
      expect(bus.listenerCount, equals(0));
      bus.dispose();
    });
  });
}
