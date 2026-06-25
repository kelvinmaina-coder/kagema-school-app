import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

/// The 'Dispatcher' for all app-wide events.
class EventHandlerService extends ChangeNotifier {
  static final EventHandlerService _instance = EventHandlerService._internal();
  factory EventHandlerService() => _instance;
  EventHandlerService._internal();

  // ──────────────────────────────────────────────────────────────────────────
  // EXISTING: Event Dispatcher
  // ──────────────────────────────────────────────────────────────────────────

  final _eventController = StreamController<AppEvent>.broadcast();
  Stream<AppEvent> get eventStream => _eventController.stream;

  void fire(AppEvent event) {
    debugPrint("DISPATCHING EVENT: ${event.type}");
    _eventController.add(event);
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NEW: EVENT LOG
  // ──────────────────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _eventLog = [];
  List<Map<String, dynamic>> get eventLog => _eventLog;

  // ──────────────────────────────────────────────────────────────────────────
  // KEYBOARD INPUT HANDLING
  // (Uses the modern HardwareKeyboard KeyEvent API — KeyDownEvent / KeyUpEvent
  //  — instead of the deprecated RawKeyEvent / RawKeyDownEvent API. This is
  //  what fixes the "RawKeyDownEvent can't be assigned to KeyEvent" error.)
  // ──────────────────────────────────────────────────────────────────────────

  void onKeyPressed(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final keyLabel = event.logicalKey.keyLabel;
    final timestamp = DateTime.now().toIso8601String();

    Map<String, dynamic> logEntry = {
      'type': 'keyboard',
      'action': 'Key Pressed',
      'key': keyLabel,
      'timestamp': timestamp,
    };

    switch (keyLabel) {
      case 'Enter':
        _logEvent('form_submitted', 'Form Submitted via Enter key');
        break;
      case 'Escape':
        _logEvent('form_cancelled', 'Form Cancelled via Escape key');
        break;
      case 'Tab':
        _logEvent('navigation', 'Tab key pressed - moving to next field');
        break;
      case 'Arrow Left':
        _logEvent('navigation', 'Arrow Left pressed');
        break;
      case 'Arrow Right':
        _logEvent('navigation', 'Arrow Right pressed');
        break;
      case 'Arrow Up':
        _logEvent('navigation', 'Arrow Up pressed');
        break;
      case 'Arrow Down':
        _logEvent('navigation', 'Arrow Down pressed');
        break;
      default:
        _logEvent('key_pressed', 'Key pressed: $keyLabel');
    }

    _addToLog(logEntry);
    fire(AppEvent(
      EventType.keyboardInput,
      data: {'key': keyLabel, 'action': 'pressed'},
    ));
    notifyListeners();
  }

  void onKeyReleased(KeyEvent event) {
    if (event is! KeyUpEvent) return;

    final keyLabel = event.logicalKey.keyLabel;
    _addToLog({
      'type': 'keyboard',
      'action': 'Key Released',
      'key': keyLabel,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logEvent('key_released', 'Key released: $keyLabel');
    notifyListeners();
  }

  /// Single entry point for KeyboardListener.onKeyEvent.
  /// Routes a raw KeyEvent to the pressed/released handlers above.
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      onKeyPressed(event);
    } else if (event is KeyUpEvent) {
      onKeyReleased(event);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TOUCH GESTURE HANDLING
  // ──────────────────────────────────────────────────────────────────────────

  void onTap(String source) {
    _addToLog({
      'type': 'gesture',
      'action': 'Tap',
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logEvent('tap_detected', 'Tap detected on: $source');
    fire(AppEvent(
      EventType.gestureDetected,
      data: {'gesture': 'tap', 'source': source},
    ));
    notifyListeners();
  }

  void onDoubleTap(String source) {
    _addToLog({
      'type': 'gesture',
      'action': 'Double Tap',
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logEvent('double_tap', 'Double tap detected on: $source');
    fire(AppEvent(
      EventType.gestureDetected,
      data: {'gesture': 'double_tap', 'source': source},
    ));
    notifyListeners();
  }

  void onLongPress(String source) {
    _addToLog({
      'type': 'gesture',
      'action': 'Long Press',
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logEvent('long_press', 'Long press detected on: $source');
    fire(AppEvent(
      EventType.gestureDetected,
      data: {'gesture': 'long_press', 'source': source},
    ));
    notifyListeners();
  }

  void onSwipe(String direction, String source) {
    _addToLog({
      'type': 'gesture',
      'action': 'Swipe',
      'direction': direction,
      'source': source,
      'timestamp': DateTime.now().toIso8601String(),
    });

    String message;
    switch (direction) {
      case 'left':
        message = 'Swiped left on: $source - Previous page';
        break;
      case 'right':
        message = 'Swiped right on: $source - Next page';
        break;
      case 'up':
        message = 'Swiped up on: $source';
        break;
      case 'down':
        message = 'Swiped down on: $source';
        break;
      default:
        message = 'Swipe detected on: $source';
    }
    _logEvent('swipe_$direction', message);
    fire(AppEvent(
      EventType.gestureDetected,
      data: {'gesture': 'swipe', 'direction': direction, 'source': source},
    ));
    notifyListeners();
  }

  void onDrag(String source, Offset offset) {
    _addToLog({
      'type': 'gesture',
      'action': 'Drag',
      'source': source,
      'dx': offset.dx,
      'dy': offset.dy,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logEvent('drag', 'Dragged on: $source');
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // INPUT VALIDATION
  // ──────────────────────────────────────────────────────────────────────────

  String validateUsername(String username) {
    if (username.isEmpty) return '❌ Username cannot be empty';
    if (username.length < 3) return '❌ Username must be at least 3 characters';
    if (username.length > 20) return '❌ Username cannot exceed 20 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return '❌ Only letters, numbers, and underscores';
    }
    fire(AppEvent(
      EventType.validationSuccess,
      data: {'field': 'username', 'value': username},
    ));
    return '✅ Valid username';
  }

  String validateEmail(String email) {
    if (email.isEmpty) return '❌ Email cannot be empty';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return '❌ Please enter a valid email address';
    }
    fire(AppEvent(
      EventType.validationSuccess,
      data: {'field': 'email', 'value': email},
    ));
    return '✅ Valid email';
  }

  String validatePassword(String password) {
    if (password.isEmpty) return '❌ Password cannot be empty';
    if (password.length < 6) return '❌ Password must be at least 6 characters';
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)) {
      return '❌ Must contain at least one letter and one number';
    }
    fire(AppEvent(
      EventType.validationSuccess,
      data: {'field': 'password', 'value': '***'},
    ));
    return '✅ Valid password';
  }

  String validatePhone(String phone) {
    if (phone.isEmpty) return '❌ Phone number cannot be empty';
    if (!RegExp(r'^\+?[\d\s-]{10,15}$').hasMatch(phone)) {
      return '❌ Please enter a valid phone number';
    }
    return '✅ Valid phone number';
  }

  // ──────────────────────────────────────────────────────────────────────────
  // EVENT LOGGING HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  void _addToLog(Map<String, dynamic> entry) {
    _eventLog.insert(0, entry);
    if (_eventLog.length > 200) {
      _eventLog.removeLast();
    }
  }

  void _logEvent(String eventType, String message) {
    debugPrint('[$eventType] $message');
    fire(AppEvent(
      EventType.logEvent,
      data: {'type': eventType, 'message': message},
    ));
  }

  void clearLog() {
    _eventLog.clear();
    notifyListeners();
  }

  Map<String, dynamic>? getLastEvent(String type) {
    try {
      return _eventLog.firstWhere((e) => e['type'] == type);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> getEventsByType(String type) {
    return _eventLog.where((e) => e['type'] == type).toList();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum EventType {
  attendanceUpdated,
  staffRegistered,
  studentEnrolled,
  feePaymentSync,
  networkStatusChanged,
  keyboardInput,
  gestureDetected,
  validationSuccess,
  validationFailed,
  logEvent,
}

// ─────────────────────────────────────────────────────────────────────────────
// APP EVENT CLASS
// ─────────────────────────────────────────────────────────────────────────────

class AppEvent {
  final EventType type;
  final dynamic data;
  final DateTime timestamp;

  AppEvent(this.type, {this.data}) : timestamp = DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// GESTURE AWARE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class GestureAwareWidget extends StatelessWidget {
  final Widget child;
  final String source;
  final EventHandlerService eventHandler;
  final VoidCallback? onTapCallback;
  final VoidCallback? onDoubleTapCallback;
  final VoidCallback? onLongPressCallback;

  const GestureAwareWidget({
    super.key,
    required this.child,
    required this.source,
    required this.eventHandler,
    this.onTapCallback,
    this.onDoubleTapCallback,
    this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        eventHandler.onTap(source);
        onTapCallback?.call();
      },
      onDoubleTap: () {
        eventHandler.onDoubleTap(source);
        onDoubleTapCallback?.call();
      },
      onLongPress: () {
        eventHandler.onLongPress(source);
        onLongPressCallback?.call();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            eventHandler.onSwipe('right', source);
          } else if (details.primaryVelocity! < 0) {
            eventHandler.onSwipe('left', source);
          }
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            eventHandler.onSwipe('down', source);
          } else if (details.primaryVelocity! < 0) {
            eventHandler.onSwipe('up', source);
          }
        }
      },
      onPanUpdate: (details) {
        eventHandler.onDrag(source, details.delta);
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRACKED TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────

class TrackedTextField extends StatefulWidget {
  final String label;
  final String source;
  final TextEditingController? controller;
  final Function(String)? onSubmitted;
  final String? Function(String)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final String? hintText;
  final IconData? prefixIcon;

  const TrackedTextField({
    super.key,
    required this.label,
    required this.source,
    this.controller,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.hintText,
    this.prefixIcon,
  });

  @override
  State<TrackedTextField> createState() => _TrackedTextFieldState();
}

class _TrackedTextFieldState extends State<TrackedTextField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        EventHandlerService()._logEvent('focus', '${widget.source} field focused');
      }
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        final handler = EventHandlerService();
        handler.handleKeyEvent(event);
        if (event is KeyDownEvent && widget.validator != null) {
          setState(() {
            _errorText = widget.validator!(_controller.text);
          });
        }
      },
      child: TextFormField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 20)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          errorText: _errorText,
          suffixIcon: IconButton(
            icon: const Icon(Icons.keyboard, size: 18),
            onPressed: () => _focusNode.requestFocus(),
          ),
        ),
        onFieldSubmitted: (value) {
          final handler = EventHandlerService();
          handler._logEvent('submit', '${widget.source} submitted: $value');
          if (widget.onSubmitted != null) {
            widget.onSubmitted!(value);
          }
        },
        validator: (value) => widget.validator != null
            ? widget.validator!(value ?? '')
            : null,
        onChanged: (value) {
          if (widget.validator != null) {
            setState(() {
              _errorText = widget.validator!(value);
            });
          }
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENT LOG VIEWER
// ─────────────────────────────────────────────────────────────────────────────

class EventLogViewer extends StatelessWidget {
  final EventHandlerService handler;
  final int maxHeight;

  const EventLogViewer({
    super.key,
    required this.handler,
    this.maxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final dt = context.dt;

    if (handler.eventLog.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: dt.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dt.cardBorder),
        ),
        child: const Center(
          child: Text(
            'No events logged yet.\nInteract with the app!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight.toDouble()),
      decoration: BoxDecoration(
        color: dt.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dt.cardBorder),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        shrinkWrap: true,
        itemCount: handler.eventLog.length,
        itemBuilder: (context, index) {
          final event = handler.eventLog[index];
          final isKeyboard = event['type'] == 'keyboard';
          final isGesture = event['type'] == 'gesture';
          final icon = isKeyboard
              ? Icons.keyboard
              : (isGesture ? Icons.touch_app : Icons.check_circle);
          final color = isKeyboard
              ? Colors.blue
              : (isGesture ? Colors.orange : Colors.green);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dt.roleSoftBg(color),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['action'] ?? 'Event',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: dt.textPrimary,
                          ),
                        ),
                        if (event['key'] != null)
                          Text(
                            'Key: ${event['key']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: dt.textMuted,
                            ),
                          ),
                        if (event['direction'] != null)
                          Text(
                            'Direction: ${event['direction']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: dt.textMuted,
                            ),
                          ),
                        if (event['source'] != null)
                          Text(
                            'Source: ${event['source']}',
                            style: TextStyle(
                              fontSize: 10,
                              color: dt.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    event['timestamp']?.toString().split('T').last.split('.').first ?? '',
                    style: TextStyle(
                      fontSize: 9,
                      color: dt.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}