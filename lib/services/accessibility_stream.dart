import 'dart:async';
import 'package:flutter/services.dart';

class AccessibilityStream {

  static const EventChannel _channel =
      EventChannel('order_app/event');

  static Stream<String> get stream {
    return _channel.receiveBroadcastStream().map((event) {
      return event.toString();
    });
  }
}