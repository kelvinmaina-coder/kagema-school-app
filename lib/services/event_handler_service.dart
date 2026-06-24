import 'dart:async';
import 'package:flutter/material.dart';

/// The 'Dispatcher' for all app-wide events.
/// This allows modules to talk to each other without being connected.
class EventHandlerService extends ChangeNotifier {
  static final EventHandlerService _instance = EventHandlerService._internal();
  factory EventHandlerService() => _instance;
  EventHandlerService._internal();

  // The stream that broadcasts events
  final _eventController = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get eventStream => _eventController.stream;

  /// Fire an event to the whole app
  void fire(AppEvent event) {
    debugPrint("DISPATCHING EVENT: ${event.type}");
    _eventController.add(event);
    
    // We also notify listeners for simple UI updates
    notifyListeners();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}

/// Define the types of events your app handles
enum EventType {
  attendanceUpdated,
  staffRegistered,
  studentEnrolled,
  feePaymentSync,
  networkStatusChanged
}

class AppEvent {
  final EventType type;
  final dynamic data;
  final DateTime timestamp;

  AppEvent(this.type, {this.data}) : timestamp = DateTime.now();
}
