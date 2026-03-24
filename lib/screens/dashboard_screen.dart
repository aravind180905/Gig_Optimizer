import 'package:flutter/material.dart';
import 'package:gig_optimizer/db_service.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/platform_channel.dart';

class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});

@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
bool isListening = false;

@override
void initState() {
super.initState();
requestPermissions();

Future.microtask(() async {
  final provider =
      Provider.of<OrderProvider>(context, listen: false);

  await provider.loadFromDB();

  final data = await DBService.getAllData();
  print("DB DATA: $data");
});

}

Future<void> requestPermissions() async {
final overlay = await Permission.systemAlertWindow.request();

if (!overlay.isGranted) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Overlay permission required"),
    ),
  );
}

}

@override
void dispose() {
Provider.of<OrderProvider>(context, listen: false).dispose();
super.dispose();
}

//  PLATFORM → LOGO
String getLogo(String platform) {
final name = platform.toLowerCase();

if (name.contains("swiggy")) {
  return "assets/images/swiggy.png";
} else if (name.contains("rapido")) {
  return "assets/images/rapido.png";
} else if (name.contains("zomato")) {
  return "assets/images/zomato.png";
} else if (name.contains("uber")) {
  return "assets/images/uber.png";
} else {
  return "assets/images/default.png";
}

}

@override
Widget build(BuildContext context) {
final provider = Provider.of<OrderProvider>(context);

return Scaffold(
  appBar: AppBar(
    title: const Text("Order Dashboard"),
    centerTitle: true,
  ),
  body: Column(
    children: [
      const SizedBox(height: 10),

      //  LIVE DATA
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          provider.nativeMessage,
          style: const TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      const SizedBox(height: 10),

      //  START / STOP
      ElevatedButton(
        onPressed: () {
          if (!isListening) {
            provider.startListening();
          } else {
            provider.dispose();
          }

          setState(() {
            isListening = !isListening;
          });
        },
        child: Text(
          isListening
              ? "Stop Listening"
              : "Start Real-Time Stream",
        ),
      ),

      const SizedBox(height: 10),

      //  ORDER LIST
      Expanded(
        child: provider.orders.isEmpty
            ? const Center(
                child: Text("No orders detected yet"),
              )
            : ListView.builder(
                itemCount: provider.orders.length,
                itemBuilder: (context, index) {
                  final order = provider.orders[index];

                  final rate = order.distance > 0
                      ? (order.fare / order.distance)
                          .toStringAsFixed(2)
                      : "0";

                  final isGood = order.distance > 0 &&
                      (order.fare / order.distance) > 10;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    elevation: 8,
                    color: Colors.green.shade50,

                    child: ListTile(
                      // LOGO
                      leading: Image.asset(
                        getLogo(order.platform),
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),

                      //  TITLE + BEST TAG
                      title: Row(
                        children: [
                          Text(
                            "₹ ${order.fare}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      // DETAILS
                      subtitle: Text(
                        "Total: ${order.distance} KM\n"
                        "First Mile: ${order.pickup} KM\n"
                        "Last Mile: ${order.drop} KM\n"
                        "₹/KM: $rate",
                      ),

                      // RIGHT SIDE
                      trailing: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isGood
                                  ? Colors.green
                                  : Colors.red,
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child: Text(
                              rate,
                              style: const TextStyle(
                                  color: Colors.white),
                            ),
                          ),

                          if (order.pickup > 3)
                            const Text(
                              "⚠️ Pickup",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),

      // ACCESSIBILITY
      ElevatedButton(
        onPressed: () {
          PlatformChannel.openAccessibilitySettings();
        },
        child: const Text("Enable Accessibility"),
      ),

      const SizedBox(height: 10),
    ],
  ),

  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Provider.of<OrderProvider>(context, listen: false)
          .addOrder(
        OrderModel(
          platform: "Swiggy",
          fare: 120,
          distance: 6,
          pickup: 2.0,
          drop: 4.0,
          dropDistance: 6,
        ),
      );
    },
    child: const Icon(Icons.add),
  ),
);

}
}
