import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/firebase_data_service.dart';
import '../../domain/entities/inventory_item.dart';

class InventoryState {
  final List<InventoryItem> items;
  final bool isLoading;
  final String? error;

  const InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  InventoryState copyWith({
    List<InventoryItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class InventoryNotifier extends StateNotifier<InventoryState> {
  InventoryNotifier() : super(const InventoryState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await FirebaseDataService.getInventoryItems();
      state = InventoryState(items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<void> saveItem(InventoryItem item) async {
    await FirebaseDataService.saveInventoryItem(item);
    await load();
  }

  Future<void> consumeItem(InventoryItem item, int quantity) async {
    await FirebaseDataService.consumeInventory(
      item: item,
      additionalConsumed: quantity,
    );
    await load();
  }
}

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
  return InventoryNotifier();
});

final inventoryCategoryFilterProvider = StateProvider<String>((ref) => 'All');
final inventoryLowStockFilterProvider = StateProvider<bool>((ref) => false);
final inventorySearchProvider = StateProvider<String>((ref) => '');

final filteredInventoryProvider =
    Provider<AsyncValue<List<InventoryItem>>>((ref) {
  final inventoryState = ref.watch(inventoryProvider);
  final category = ref.watch(inventoryCategoryFilterProvider);
  final lowStockOnly = ref.watch(inventoryLowStockFilterProvider);
  final query = ref.watch(inventorySearchProvider).toLowerCase();

  if (inventoryState.isLoading) return const AsyncValue.loading();
  if (inventoryState.error != null) {
    return AsyncValue.error(inventoryState.error!, StackTrace.current);
  }

  return AsyncValue.data(
    inventoryState.items.where((item) {
      final matchesCategory = category == 'All' || item.category == category;
      final matchesLowStock = !lowStockOnly || item.isLowStock;
      final matchesQuery = query.isEmpty ||
          item.medicineName.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesCategory && matchesLowStock && matchesQuery;
    }).toList(),
  );
});

final inventoryCategoriesProvider = Provider<List<String>>((ref) {
  const categories = [
    'All',
    'Analgesics',
    'Antibiotics',
    'Antidiabetics',
    'Antihypertensives',
    'Vaccines',
    'Nutritional Supplements',
    'Diagnostics',
    'PPE',
    'Equipment',
    'Rehydration',
    'Anthelmintics',
    'Respiratory',
    'First Aid',
    'Water Purification',
  ];
  return categories;
});
