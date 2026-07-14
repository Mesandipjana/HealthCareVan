import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/mobile_unit.dart';
import '../../../../core/services/firebase_data_service.dart';

final unitsProvider = FutureProvider<List<MobileUnit>>((ref) async {
  return FirebaseDataService.getMobileUnits();
});

final saveUnitProvider = Provider((ref) {
  return (MobileUnit unit) async {
    await FirebaseDataService.saveMobileUnit(unit);
    ref.invalidate(unitsProvider);
  };
});

final selectedUnitProvider = StateProvider<String?>((ref) => null);

final filteredUnitsProvider = Provider<AsyncValue<List<MobileUnit>>>((ref) {
  final unitsAsync = ref.watch(unitsProvider);
  final filter = ref.watch(unitFilterProvider);

  return unitsAsync.whenData((units) {
    if (filter == 'all') return units;
    return units.where((u) => u.status == filter).toList();
  });
});

final unitFilterProvider = StateProvider<String>((ref) => 'all');
final unitSearchQueryProvider = StateProvider<String>((ref) => '');

final searchedUnitsProvider = Provider<AsyncValue<List<MobileUnit>>>((ref) {
  final unitsAsync = ref.watch(filteredUnitsProvider);
  final query = ref.watch(unitSearchQueryProvider).toLowerCase();

  return unitsAsync.whenData((units) {
    if (query.isEmpty) return units;
    return units
        .where((u) =>
            u.name.toLowerCase().contains(query) ||
            u.unitCode.toLowerCase().contains(query) ||
            u.district.toLowerCase().contains(query) ||
            u.state.toLowerCase().contains(query))
        .toList();
  });
});

final unitByIdProvider = Provider.family<MobileUnit?, String>((ref, id) {
  final unitsAsync = ref.watch(unitsProvider);
  return unitsAsync.value?.firstWhere(
    (u) => u.id == id,
    orElse: () => throw Exception('Unit not found'),
  );
});
