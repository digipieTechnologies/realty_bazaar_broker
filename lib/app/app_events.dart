// File: lib/app/app_events.dart
// Purpose: Application-wide event bus singleton and base events.

import 'package:event_bus_plus/event_bus_plus.dart' as ebp;

class AppEvents {
  AppEvents._();

  // Global EventBus singleton instance.
  static final ebp.EventBus _bus = ebp.EventBus();

  static ebp.EventBus get bus => _bus;

  /// Broadcasts an event to all subscribers.
  static void fire(ebp.AppEvent event) {
    _bus.fire(event);
  }

  /// Returns a stream of events of type [T].
  static Stream<T> on<T extends ebp.AppEvent>() {
    return _bus.on<T>();
  }
}

/// Base class for all custom application events.
/// This allows future feature modules to define their own events by extending this class.
abstract class AppEvent extends ebp.AppEvent {
  const AppEvent();

  @override
  List<Object?> get props => [];
}

// --- Common Base Events Placeholders ---

/// Triggered when the theme switches.
class ThemeChangedEvent extends AppEvent {
  final bool isDark;
  const ThemeChangedEvent(this.isDark);

  @override
  List<Object?> get props => [isDark];
}

/// Triggered when user session changes.
class UserAuthChangedEvent extends AppEvent {
  final bool isAuthenticated;
  const UserAuthChangedEvent(this.isAuthenticated);

  @override
  List<Object?> get props => [isAuthenticated];
}
