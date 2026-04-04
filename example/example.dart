import 'package:philiprehberger_event_bus/philiprehberger_event_bus.dart';

class UserLoggedIn {
  final String userId;
  UserLoggedIn(this.userId);
}

class ItemAdded {
  final String item;
  ItemAdded(this.item);
}

void main() async {
  final bus = EventBus();

  // Type-safe subscriptions
  bus.on<UserLoggedIn>().listen((event) {
    print('User logged in: ${event.userId}');
  });

  bus.on<ItemAdded>().listen((event) {
    print('Item added: ${event.item}');
  });

  // Fire events
  bus.fire(UserLoggedIn('user-123'));
  bus.fire(ItemAdded('Widget'));

  // Sticky events
  bus.fireSticky(UserLoggedIn('user-456'));
  print('Last sticky: ${bus.lastSticky<UserLoggedIn>()?.userId}');

  // Clean up
  await Future<void>.delayed(Duration(milliseconds: 100));
  bus.dispose();
}
