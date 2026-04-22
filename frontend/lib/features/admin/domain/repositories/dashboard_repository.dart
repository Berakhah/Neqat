import 'package:frontend/features/admin/domain/entities/dashboard_metrics.dart';

abstract class DashboardRepository {
  Future<DashboardMetrics> getDashboardMetrics();
  Future<Map<String, List<int>>> getUserTrends({required String period}); // daily, weekly, monthly
  Future<Map<String, List<int>>> getContentTrends({required String period}); // daily, weekly, monthly
  Future<Map<String, int>> getUsersCountByLocation();
  Future<Map<String, int>> getContentCountByCategory();
  Future<Map<String, double>> getUserEngagementRates();
} 