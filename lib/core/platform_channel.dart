import 'package:flutter/services.dart';

class PlatformChannel {

  static const MethodChannel _method =
      MethodChannel("order_app/method");

  static const EventChannel _event =
      EventChannel("order_app/event");

  static Future<String?> getMessage() async {
    return await _method.invokeMethod("getMessage");
  }

  static const MethodChannel _settingsChannel =
    MethodChannel("settings/channel");

static Future<void> openAccessibilitySettings() async {
  await _settingsChannel.invokeMethod("openAccessibilitySettings");
}

  static Stream<dynamic> get stream =>
      _event.receiveBroadcastStream();
}