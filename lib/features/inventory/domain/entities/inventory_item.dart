class InventoryItem {
  final String id;
  final String medicineName;
  final String category;
  final String unitId;
  final String unitName;
  final int availableStock;
  final int consumed;
  final int remaining;
  final String unit; // Tablets, Capsules, Vials, etc.
  final int lowStockThreshold;
  final bool isLowStock;
  final DateTime lastUpdated;

  const InventoryItem({
    required this.id,
    required this.medicineName,
    required this.category,
    required this.unitId,
    required this.unitName,
    required this.availableStock,
    required this.consumed,
    required this.remaining,
    required this.unit,
    required this.lowStockThreshold,
    required this.isLowStock,
    required this.lastUpdated,
  });

  double get consumptionPercent =>
      availableStock > 0 ? (consumed / availableStock * 100) : 0;

  double get remainingPercent =>
      availableStock > 0 ? (remaining / availableStock * 100) : 0;

  bool get isCriticallyLow => remaining <= (lowStockThreshold * 0.5);
}
