class OrderModel {
  final String platform;
  final double pickup;
  final double drop;
  final double fare;
  final double distance;
  final double dropDistance;

  OrderModel({
    required this.platform,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.distance,
    required this.dropDistance
  });
}