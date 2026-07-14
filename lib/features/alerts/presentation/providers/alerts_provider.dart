import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alert_item.dart';
import '../../../../core/services/firebase_data_service.dart';

class AlertsState {
  final List<AlertItem> alerts;
  final bool isLoading;

  const AlertsState({
    this.alerts = const [],
    this.isLoading = false,
  });

  int get unreadCount => alerts.where((a) => !a.isRead).length;

  AlertsState copyWith({List<AlertItem>? alerts, bool? isLoading}) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  AlertsNotifier() : super(const AlertsState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final alerts = await FirebaseDataService.getAlerts();
    state = AlertsState(alerts: alerts);
  }

  Future<void> refresh() => _load();

  Future<void> markAsRead(String id) async {
    final updated = state.alerts.map((a) {
      return a.id == id ? a.copyWith(isRead: true) : a;
    }).toList();
    state = state.copyWith(alerts: updated);
    await FirebaseDataService.markAlertRead(id, true);
  }

  Future<void> markAllAsRead() async {
    final updated = state.alerts.map((a) => a.copyWith(isRead: true)).toList();
    state = state.copyWith(alerts: updated);
    await FirebaseDataService.markAllAlertsRead();
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier();
});

final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).unreadCount;
});
