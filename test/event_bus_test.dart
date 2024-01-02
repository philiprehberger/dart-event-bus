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
}
