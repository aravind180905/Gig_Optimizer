class ProfitService {
  static double earningsPerKm(double fare, double distance) {
    if (distance == 0) return 0;
    return fare / distance;
  }
}