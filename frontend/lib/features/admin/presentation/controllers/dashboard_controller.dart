import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';
import 'package:frontend/features/admin/domain/usecases/get_dashboard_data.dart';
import 'package:frontend/features/admin/presentation/providers/admin_providers.dart';

// Dashboard controller provider
final dashboardControllerProvider = StateNotifierProvider<DashboardController, AsyncValue<DashboardMetrics>>(
  (ref) {
    final getDashboardData = ref.watch(getDashboardDataProvider);
    return DashboardController(getDashboardData);
  },
);

class DashboardController extends StateNotifier<AsyncValue<DashboardMetrics>> {
  final GetDashboardData _getDashboardData;
  
  DashboardController(this._getDashboardData) : super(const AsyncValue.loading());
  
  Future<void> loadDashboardData() async {
    try {
      state = const AsyncValue.loading();
      
      // Get dashboard data from use case
      final dashboardResult = await _getDashboardData();
      
      // Handle the result
      dashboardResult.fold(
        (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
        (dashboardMetrics) => state = AsyncValue.data(dashboardMetrics)
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  void switchTrendPeriod(String dataType, String period) {
    // This method is used to switch between different trend periods
    // It doesn't need to do anything as the UI is already handling the period selection
    // In a real implementation, you might want to fetch new data for the selected period
    // For now, we're just using the data that's already loaded
  }
} 