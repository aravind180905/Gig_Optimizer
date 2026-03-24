import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../db_service.dart';
import 'dart:async';

class OrderProvider extends ChangeNotifier {

  static const EventChannel _eventChannel = EventChannel("order_app/event");

  List<OrderModel> orders = [];
  String nativeMessage = "Waiting for data...";

  StreamSubscription? _subscription;

  // ✅ START LISTENING
void startListening() {

  _subscription = _eventChannel.receiveBroadcastStream().listen((event) async {

    final fare = (event["fare"] ?? 0).toDouble();
    final totalMile = (event["total_km"] ?? 0).toDouble();
    final firstMile = (event["first_km"] ?? 0).toDouble();
    final lastMile = (event["last_km"] ?? 0).toDouble();
    final text = event["text"] ?? "";
    final packageName = event["package_name"] ?? "";

    nativeMessage =
        "₹ $fare | Total: $totalMile | First: $firstMile | Last: $lastMile";

    // ✅ SAVE TO SQLITE
    await DBService.insertData(fare, totalMile, firstMile, lastMile, packageName);

    // ✅ ADD TO UI
    final order = OrderModel(
      platform: packageName,
      fare: fare,
      distance: totalMile,
      pickup: firstMile,
      drop: lastMile,
      dropDistance: totalMile,
    );

    orders.insert(0, order);

    notifyListeners();

  }, onError: (error) {
    nativeMessage = "Error receiving data";
    notifyListeners();
  });
}

  // ✅ LOAD FROM SQLITE ON START
Future<void> loadFromDB() async {
  final data = await DBService.getAllData();

  orders = data.map((item) {
    return OrderModel(
      platform: item['platform'],
      fare: item['fare'],
      distance: item['total_distance'],
      pickup: item['first_mile'],
      drop: item['last_mile'],
      dropDistance: item['total_distance'],
    );
  }).toList();

  notifyListeners();
}

  // ✅ STOP LISTENING-
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // ✅ MANUAL ADD (your existing)
  void addOrder(OrderModel order) {
    orders.insert(0, order);
    notifyListeners();
  }
}