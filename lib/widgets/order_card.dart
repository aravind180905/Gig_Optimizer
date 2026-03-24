import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/profit_service.dart';

class OrderCard extends StatelessWidget {

final OrderModel order;

const OrderCard({super.key, required this.order});

String getLogo(String platform) {
final name = platform.toLowerCase();

if (name.contains("swiggy")) {
  return "assets/images/swiggy.png";
} else if (name.contains("rapido")) {
  return "assets/images/rapido.png";
} else if (name.contains("zomato")) {
  return "assets/images/zomato.png";
} else if (name.contains("ek_bharat")) {
  return "assets/images/ek_bharat.png";
} else {
  return "assets/images/default.png";
}

}

@override
Widget build(BuildContext context) {

final profit =
    ProfitService.earningsPerKm(
        order.fare,
        order.distance);

return Card(
  margin: const EdgeInsets.all(10),
  child: Padding(
    padding: const EdgeInsets.all(15),
    child: Row( 
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Image.asset(
          getLogo(order.platform),
          width: 50,
          height: 50,
          fit: BoxFit.contain,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(order.platform,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),

              Text("Fare: ₹${order.fare}"),
              Text("Total Distance: ${order.distance} km"),
              Text("Last Mile: ${order.dropDistance} km"),

              const SizedBox(height: 8),

              Text(
                "₹${profit.toStringAsFixed(2)} / km",
                style: const TextStyle(color: Colors.green),
              )
            ],
          ),
        ),
      ],
    ),
  ),
);

}
}
